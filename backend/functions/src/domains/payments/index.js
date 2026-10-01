"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { requireAuth }        = require("../../middleware/auth");
const { db, COL }            = require("../../lib/db");
const { getStripe, CURRENCY }= require("../../lib/stripe");

// ── createPaymentIntent ───────────────────────────────────────────────────────
//
// SECURITY:
//   Amount is read from the Firestore order document (server-side).
//   The client sends only orderId. It cannot influence the charge amount.

const createPaymentIntent = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireAuth(request);

  const { orderId } = request.data || {};
  if (!orderId || typeof orderId !== "string") {
    throw new HttpsError("invalid-argument", "'orderId' is required.");
  }

  const orderRef = db.collection(COL.ORDERS).doc(orderId.trim());
  const orderDoc = await orderRef.get();

  if (!orderDoc.exists) {
    throw new HttpsError("not-found", `Order '${orderId}' not found.`);
  }

  const order = orderDoc.data();

  // Enforce ownership — user cannot pay for another user's order
  if (order.userId !== uid) {
    throw new HttpsError("permission-denied", "You do not have access to this order.");
  }

  if (order.status !== "pending_payment") {
    throw new HttpsError("failed-precondition",
      `Order is in '${order.status}' status. Payment cannot be initiated.`);
  }

  const amount = order.totalInCents;
  if (!Number.isInteger(amount) || amount < 50) {
    throw new HttpsError("failed-precondition", "Order total is invalid.");
  }

  const stripe = getStripe();
  const intent = await stripe.paymentIntents.create({
    amount,
    currency: CURRENCY,
    metadata: {
      orderId,
      userId: uid,
    },
    automatic_payment_methods: { enabled: true },
  });

  // Store the intent ID so the webhook can match it back to this order
  await orderRef.update({
    paymentIntentId: intent.id,
    updatedAt:       new Date(),
  });

  return {
    clientSecret:    intent.client_secret,
    paymentIntentId: intent.id,
    amountInCents:   amount,
  };
});

// ── verifyPayment ─────────────────────────────────────────────────────────────
// Fallback for cases where the webhook hasn't fired yet.
// Client polls this after the Payment Sheet resolves.

const verifyPayment = onCall({ region: "us-central1" }, async (request) => {
  requireAuth(request);

  const { paymentIntentId } = request.data || {};
  if (!paymentIntentId || typeof paymentIntentId !== "string") {
    throw new HttpsError("invalid-argument", "'paymentIntentId' is required.");
  }

  const stripe = getStripe();
  let intent;
  try {
    intent = await stripe.paymentIntents.retrieve(paymentIntentId.trim());
  } catch (err) {
    if (err.type === "StripeInvalidRequestError") {
      throw new HttpsError("not-found", "PaymentIntent not found.");
    }
    throw new HttpsError("internal", "Failed to verify payment.");
  }

  return {
    paymentIntentId: intent.id,
    status:          intent.status,
    paid:            intent.status === "succeeded",
  };
});

// ── createCheckoutSession ─────────────────────────────────────────────────────
// Web storefront (static export, no server) pays via Stripe-hosted Checkout.
// Same security model as createPaymentIntent: amount comes from the order doc.

const ALLOWED_RETURN_ORIGINS = [
  "https://www.sunnahgrandeur.us",
  "https://sunnahgrandeur.us",
  "https://sunnah-grandeur.web.app",
  "https://sunnah-grandeur.firebaseapp.com",
  "http://localhost:3000",
];

const createCheckoutSession = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireAuth(request);

  const { orderId, origin } = request.data || {};
  if (!orderId || typeof orderId !== "string") {
    throw new HttpsError("invalid-argument", "'orderId' is required.");
  }
  const base = ALLOWED_RETURN_ORIGINS.includes(origin) ? origin : ALLOWED_RETURN_ORIGINS[0];

  const orderRef = db.collection(COL.ORDERS).doc(orderId.trim());
  const orderDoc = await orderRef.get();
  if (!orderDoc.exists) throw new HttpsError("not-found", `Order '${orderId}' not found.`);

  const order = orderDoc.data();
  if (order.userId !== uid) {
    throw new HttpsError("permission-denied", "You do not have access to this order.");
  }
  if (order.status !== "pending_payment") {
    throw new HttpsError("failed-precondition",
      `Order is in '${order.status}' status. Payment cannot be initiated.`);
  }
  const amount = order.totalInCents;
  if (!Number.isInteger(amount) || amount < 50) {
    throw new HttpsError("failed-precondition", "Order total is invalid.");
  }

  const session = await getStripe().checkout.sessions.create({
    mode: "payment",
    customer_email: order.shipping?.email || undefined,
    line_items: [{
      quantity: 1,
      price_data: {
        currency: CURRENCY,
        unit_amount: amount,
        product_data: { name: `Sunnah Grandeur order ${orderId}` },
      },
    }],
    payment_intent_data: { metadata: { orderId, userId: uid } },
    metadata: { orderId, userId: uid },
    expires_at: Math.floor(Date.now() / 1000) + 30 * 60,
    success_url: `${base}/checkout/success/?order=${encodeURIComponent(orderId)}`,
    cancel_url:  `${base}/checkout/?cancelled=1`,
  });

  await orderRef.update({ checkoutSessionId: session.id, updatedAt: new Date() });
  return { url: session.url, sessionId: session.id };
});

module.exports = { createPaymentIntent, createCheckoutSession, verifyPayment };
