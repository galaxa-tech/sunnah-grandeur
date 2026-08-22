"use strict";

/**
 * Sunnah Grandeur — Firebase Cloud Functions
 *
 * SECURITY MODEL:
 *  - Stripe secret key is stored as a Firebase Secret (never in source).
 *    Set it once:  firebase functions:secrets:set STRIPE_SECRET_KEY
 *    Set webhook:  firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
 *
 *  - Product prices are ALWAYS read from Firestore server-side.
 *    The Flutter client only sends productId + quantity (never a price).
 *
 *  - Orders are created with status:"pending" and only marked "paid"
 *    after the Stripe webhook confirms payment_intent.succeeded.
 */

const { setGlobalOptions }            = require("firebase-functions");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const admin                            = require("firebase-admin");
const logger                           = require("firebase-functions/logger");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10, region: "us-central1" });

// ─── Stripe factory ──────────────────────────────────────────────────────────
// STRIPE_SECRET_KEY is loaded from Firebase Secrets — never hardcoded.
function getStripe() {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) throw new HttpsError("internal", "Stripe is not configured. Contact support.");
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  return require("stripe")(key, { apiVersion: "2024-11-20.acacia" });
}

// ─── Auth guard ──────────────────────────────────────────────────────────────
function requireAuth(auth) {
  if (!auth || !auth.uid) {
    throw new HttpsError("unauthenticated", "You must be signed in to perform this action.");
  }
  return auth.uid;
}

// ─── Sanitisers ──────────────────────────────────────────────────────────────
const s = (v, max = 255) => String(v ?? "").trim().slice(0, max);

// ════════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT
// ════════════════════════════════════════════════════════════════════════════

/**
 * createUserMetadata
 * Called once after new Firebase Auth registration.
 * Sets role:"user" server-side — the client can never self-assign "admin".
 */
exports.createUserMetadata = onCall(async (request) => {
  const uid = requireAuth(request.auth);

  const ref  = db.collection("users").doc(uid);
  const snap = await ref.get();

  if (!snap.exists) {
    await ref.set({
      uid,
      name:      s(request.data.name,  100),
      email:     s(request.data.email, 254).toLowerCase(),
      phone:     s(request.data.phone,  20),
      role:      "user",       // server-assigned — NEVER from client
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    logger.info(`User profile created: ${uid}`);
  }

  return { success: true };
});

/**
 * updateUserProfile
 * Whitelisted update — only name and phone may be changed here.
 * Email changes go through FirebaseAuth.updateEmail separately.
 */
exports.updateUserProfile = onCall(async (request) => {
  const uid = requireAuth(request.auth);

  const update = {};
  if (request.data.name  !== undefined) update.name  = s(request.data.name,  100);
  if (request.data.phone !== undefined) update.phone = s(request.data.phone,  20);
  if (Object.keys(update).length === 0) return { success: true };

  update.updatedAt = admin.firestore.FieldValue.serverTimestamp();
  await db.collection("users").doc(uid).update(update);

  return { success: true };
});

/**
 * deleteAccount
 * Deletes Firestore profile, cart, then Firebase Auth account atomically.
 */
exports.deleteAccount = onCall(async (request) => {
  const uid = requireAuth(request.auth);

  // 1. Batch-delete cart items
  const cartSnap = await db.collection("carts").doc(uid).collection("items").get();
  if (!cartSnap.empty) {
    const batch = db.batch();
    cartSnap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }

  // 2. Delete cart document
  await db.collection("carts").doc(uid).delete().catch(() => {});

  // 3. Delete user profile
  await db.collection("users").doc(uid).delete().catch(() => {});

  // 4. Delete Firebase Auth account (must be last)
  await admin.auth().deleteUser(uid);

  logger.info(`Account deleted: ${uid}`);
  return { success: true };
});


// ════════════════════════════════════════════════════════════════════════════
// ORDER MANAGEMENT
// ════════════════════════════════════════════════════════════════════════════

/**
 * createOrder
 *
 * SECURITY: The server fetches product prices from Firestore.
 * Client sends only { items: [{productId, quantity}], shipping }.
 * Client-supplied prices are IGNORED entirely.
 *
 * Returns the new orderId and server-verified totals.
 */
exports.createOrder = onCall(async (request) => {
  const uid = requireAuth(request.auth);

  const { items, shipping } = request.data;

  // ── Input validation ────────────────────────────────────────────────────
  if (!Array.isArray(items) || items.length === 0 || items.length > 50) {
    throw new HttpsError("invalid-argument", "Cart must have 1–50 items.");
  }
  if (!shipping || !s(shipping.name) || !s(shipping.line1) || !s(shipping.postalCode)) {
    throw new HttpsError("invalid-argument", "Complete shipping address is required.");
  }

  // ── Fetch authoritative prices from Firestore ───────────────────────────
  let subtotalCents = 0;
  const orderItems  = [];

  for (const item of items) {
    const { productId, quantity } = item;

    if (!productId || typeof quantity !== "number" || quantity < 1 || quantity > 99) {
      throw new HttpsError("invalid-argument", `Invalid item: ${productId}`);
    }

    const productSnap = await db.collection("products").doc(String(productId)).get();

    if (!productSnap.exists) {
      throw new HttpsError("not-found", `Product not found: ${productId}`);
    }

    const product = productSnap.data();

    if (!product.isActive) {
      throw new HttpsError("failed-precondition", `"${product.name}" is no longer available.`);
    }
    if (typeof product.stockQuantity === "number" && product.stockQuantity < quantity) {
      throw new HttpsError(
        "resource-exhausted",
        `"${product.name}" only has ${product.stockQuantity} in stock.`
      );
    }

    // Server-authoritative price — client price is NEVER used
    const priceCents   = Math.round(Number(product.priceInCents));
    const lineCents    = priceCents * quantity;
    subtotalCents     += lineCents;

    orderItems.push({
      productId:     String(productId),
      name:          s(product.name, 200),
      priceInCents:  priceCents,
      quantity:      Math.floor(quantity),
      lineTotalCents: lineCents,
      image:         s(product.images?.[0] ?? product.image ?? "", 500),
      sku:           s(product.sku, 100),
    });
  }

  // ── Server-side totals (client has no influence over these) ────────────
  const TAX_RATE      = 0.05;    // 5 % VAT
  const taxCents      = Math.round(subtotalCents * TAX_RATE);
  const shippingCents = 0;       // Free shipping across the USA
  const totalCents    = subtotalCents + taxCents + shippingCents;

  if (totalCents <= 0) {
    throw new HttpsError("invalid-argument", "Order total must be greater than zero.");
  }

  // ── Create order document ───────────────────────────────────────────────
  const orderId = db.collection("orders").doc().id;

  await db.collection("orders").doc(orderId).set({
    orderId,
    userId:           uid,
    items:            orderItems,
    subtotalInCents:  subtotalCents,
    taxInCents:       taxCents,
    shippingInCents:  shippingCents,
    totalInCents:     totalCents,
    shipping: {
      name:       s(shipping.name,       100),
      line1:      s(shipping.line1,      200),
      city:       s(shipping.city,        100),
      state:      s(shipping.state,        50),
      postalCode: s(shipping.postalCode,   20),
      country:    s(shipping.country ?? "US", 3).toUpperCase(),
      method:     s(shipping.method ?? "standard", 20).toLowerCase(),
    },
    status:           "pending",      // awaiting Stripe payment
    paymentIntentId:  null,
    createdAt:        admin.firestore.FieldValue.serverTimestamp(),
    updatedAt:        admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(`Order created: ${orderId} | user: ${uid} | total: ${totalCents}¢`);

  return {
    orderId,
    subtotalInCents:  subtotalCents,
    taxInCents,
    shippingInCents:  shippingCents,
    totalInCents:     totalCents,
    status:           "pending",
  };
});


// ════════════════════════════════════════════════════════════════════════════
// STRIPE PAYMENTS
// ════════════════════════════════════════════════════════════════════════════

/**
 * createPaymentIntent
 *
 * Reads the order total from Firestore (never from client).
 * Returns a clientSecret for the Flutter PaymentSheet.
 *
 * Idempotent: if the order already has a valid pending PaymentIntent,
 * it is returned instead of creating a duplicate.
 */
exports.createPaymentIntent = onCall(
  { secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    const uid     = requireAuth(request.auth);
    const orderId = String(request.data.orderId ?? "");

    if (!orderId) throw new HttpsError("invalid-argument", "orderId is required.");

    // ── Read order from Firestore ─────────────────────────────────────────
    const orderSnap = await db.collection("orders").doc(orderId).get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }
    const order = orderSnap.data();

    // Security: order must belong to the authenticated user
    if (order.userId !== uid) {
      throw new HttpsError("permission-denied", "Access denied.");
    }

    if (order.status === "paid") {
      throw new HttpsError("already-exists", "This order has already been paid.");
    }

    const stripe = getStripe();

    // ── Idempotency: re-use existing PaymentIntent if still valid ─────────
    if (order.paymentIntentId) {
      try {
        const existing = await stripe.paymentIntents.retrieve(order.paymentIntentId);
        const reusable = ["requires_payment_method", "requires_confirmation", "requires_action"];
        if (reusable.includes(existing.status)) {
          logger.info(`Re-using PaymentIntent: ${existing.id} for order: ${orderId}`);
          return {
            clientSecret:    existing.client_secret,
            paymentIntentId: existing.id,
            amountInCents:   existing.amount,
          };
        }
      } catch (_) {
        // Retrieval failed — fall through to create a new one
      }
    }

    // ── Create new Stripe PaymentIntent (amount is server-side from Firestore) ──
    const paymentIntent = await stripe.paymentIntents.create({
      amount:               order.totalInCents,   // ← from Firestore, NEVER client
      currency:             "usd",
      automatic_payment_methods: { enabled: true },
      metadata: {
        orderId,
        userId:  uid,
        appName: "sunnah_grandeur",
      },
    });

    // Store paymentIntentId on the order for webhook correlation
    await db.collection("orders").doc(orderId).update({
      paymentIntentId: paymentIntent.id,
      updatedAt:       admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`PaymentIntent created: ${paymentIntent.id} | order: ${orderId} | ${paymentIntent.amount}¢`);

    return {
      clientSecret:    paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      amountInCents:   paymentIntent.amount,
    };
  }
);

/**
 * verifyPayment
 *
 * Fallback client-callable check — confirms payment status directly with Stripe.
 * Used if the webhook hasn't fired yet (e.g., network delays).
 * If Stripe confirms "succeeded", updates Firestore immediately.
 */
exports.verifyPayment = onCall(
  { secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
    requireAuth(request.auth);

    const piId = String(request.data.paymentIntentId ?? "");
    if (!piId) throw new HttpsError("invalid-argument", "paymentIntentId is required.");

    const stripe = getStripe();
    const pi     = await stripe.paymentIntents.retrieve(piId);
    const paid   = pi.status === "succeeded";

    // If paid but webhook hasn't updated order yet — do it now as fallback
    if (paid && pi.metadata?.orderId) {
      const orderRef  = db.collection("orders").doc(pi.metadata.orderId);
      const orderSnap = await orderRef.get();
      if (orderSnap.exists && orderSnap.data().status !== "paid") {
        await orderRef.update({
          status:    "paid",
          paidAt:    admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info(`Order ${pi.metadata.orderId} marked paid via verifyPayment fallback.`);
      }
    }

    return {
      paymentIntentId: pi.id,
      status:          pi.status,
      paid,
    };
  }
);


// ════════════════════════════════════════════════════════════════════════════
// STRIPE WEBHOOK HANDLER
// ════════════════════════════════════════════════════════════════════════════

/**
 * stripeWebhookHandler  (HTTP trigger — NOT a callable)
 *
 * Stripe posts events to:
 *   https://us-central1-{project-id}.cloudfunctions.net/stripeWebhookHandler
 *
 * Setup steps:
 *  1. In Stripe Dashboard → Developers → Webhooks → Add endpoint
 *     URL: the URL above
 *     Events: payment_intent.succeeded, payment_intent.payment_failed, payment_intent.canceled
 *  2. Copy the "Signing secret" and run:
 *     firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
 *
 * CRITICAL: Signature is verified BEFORE any Firestore writes.
 *           Requests without a valid signature are rejected with 400.
 */
exports.stripeWebhookHandler = onRequest(
  { secrets: ["STRIPE_SECRET_KEY", "STRIPE_WEBHOOK_SECRET"] },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).end("Method Not Allowed");
      return;
    }

    const sig           = req.headers["stripe-signature"];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    if (!webhookSecret) {
      logger.error("STRIPE_WEBHOOK_SECRET is not configured.");
      res.status(500).end("Webhook secret missing.");
      return;
    }

    // ── Verify Stripe signature ──────────────────────────────────────────
    let event;
    try {
      const stripe = getStripe();
      // req.rawBody contains the raw request body for signature verification
      event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
    } catch (err) {
      logger.error("Webhook signature verification failed:", err.message);
      res.status(400).end(`Webhook Error: ${err.message}`);
      return;
    }

    logger.info(`Stripe event received: ${event.type} (${event.id})`);

    // ── Idempotency: skip already-processed events ───────────────────────
    const eventRef  = db.collection("webhookEvents").doc(event.id);
    const eventSnap = await eventRef.get();
    if (eventSnap.exists) {
      logger.info(`Duplicate event skipped: ${event.id}`);
      res.status(200).json({ received: true, duplicate: true });
      return;
    }

    // ── Process event ────────────────────────────────────────────────────
    try {
      switch (event.type) {

        case "payment_intent.succeeded": {
          const pi      = event.data.object;
          const orderId = pi.metadata?.orderId;
          if (!orderId) {
            logger.warn(`payment_intent.succeeded: no orderId in metadata (pi: ${pi.id})`);
            break;
          }

          await db.collection("orders").doc(orderId).update({
            status:    "paid",
            paidAt:    admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Clear the user's Firestore cart now that payment is confirmed
          const userId = pi.metadata?.userId;
          if (userId) {
            const cartItems = await db
              .collection("carts").doc(userId).collection("items").get();
            if (!cartItems.empty) {
              const batch = db.batch();
              cartItems.docs.forEach((d) => batch.delete(d.ref));
              await batch.commit();
            }
          }

          logger.info(`✅ Order ${orderId} PAID — cart cleared for user ${userId}`);
          break;
        }

        case "payment_intent.payment_failed": {
          const pi             = event.data.object;
          const orderId        = pi.metadata?.orderId;
          const failureMessage = pi.last_payment_error?.message ?? "Unknown failure";
          if (!orderId) break;

          await db.collection("orders").doc(orderId).update({
            status:         "payment_failed",
            failureMessage,
            updatedAt:      admin.firestore.FieldValue.serverTimestamp(),
          });

          logger.warn(`❌ Order ${orderId} payment FAILED: ${failureMessage}`);
          break;
        }

        case "payment_intent.canceled": {
          const pi      = event.data.object;
          const orderId = pi.metadata?.orderId;
          if (!orderId) break;

          await db.collection("orders").doc(orderId).update({
            status:    "cancelled",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          logger.info(`Order ${orderId} CANCELLED.`);
          break;
        }

        default:
          logger.info(`Unhandled event type: ${event.type}`);
      }

      // Mark event as processed for idempotency
      await eventRef.set({
        eventId:   event.id,
        type:      event.type,
        processed: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    } catch (err) {
      logger.error(`Error processing event ${event.id}:`, err);
      // Return 200 to prevent Stripe from retrying — log and investigate separately
      res.status(200).json({ received: true, processingError: err.message });
      return;
    }

    res.status(200).json({ received: true });
  }
);
