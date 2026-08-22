/**
 * webhooks.js
 * -----------
 * HTTPS endpoint that receives Stripe webhook events.
 *
 * Exported functions:
 *   - stripeWebhook  — raw HTTPS function (not callable) for Stripe delivery
 *
 * Handled events:
 *   - payment_intent.succeeded     → order.status = "paid"
 *   - payment_intent.payment_failed → order.status = "failed"
 *   - charge.refunded              → order.status = "refunded"
 *
 * Setup:
 *   1. Deploy this function
 *   2. In Stripe Dashboard → Webhooks → Add endpoint
 *      URL: https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/stripeWebhook
 *   3. Select events: payment_intent.succeeded, payment_intent.payment_failed, charge.refunded
 *   4. Copy the signing secret → set as STRIPE_WEBHOOK_SECRET in .env
 */

const { onRequest }    = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const Stripe           = require("stripe");

let stripeClient = null;
function getStripe() {
  if (!stripeClient) {
    const key = process.env.STRIPE_SECRET_KEY;
    if (!key) throw new Error("STRIPE_SECRET_KEY is not set.");
    stripeClient = new Stripe(key, { apiVersion: "2024-06-20" });
  }
  return stripeClient;
}

const db         = getFirestore();
const ORDERS_COL = "orders";

// ─────────────────────────────────────────────────────────────────────────────
// stripeWebhook
// ─────────────────────────────────────────────────────────────────────────────
const stripeWebhook = onRequest(
  {
    region      : "us-central1",
    // rawBody is required for Stripe signature verification
    rawBody     : true,
    timeoutSeconds: 60,
  },
  async (req, res) => {
    // Only accept POST requests from Stripe
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!webhookSecret) {
      console.error("[stripeWebhook] STRIPE_WEBHOOK_SECRET is not configured.");
      res.status(500).send("Webhook secret not configured.");
      return;
    }

    const signature = req.headers["stripe-signature"];
    let event;

    // ── Verify signature ──────────────────────────────────────────────────────
    try {
      event = getStripe().webhooks.constructEvent(
        req.rawBody, // raw Buffer — critical for signature verification
        signature,
        webhookSecret
      );
    } catch (err) {
      console.error("[stripeWebhook] Signature verification failed:", err.message);
      res.status(400).send(`Webhook signature verification failed: ${err.message}`);
      return;
    }

    // ── Route event types ──────────────────────────────────────────────────────
    try {
      switch (event.type) {
        case "payment_intent.succeeded":
          await handlePaymentSucceeded(event.data.object);
          break;

        case "payment_intent.payment_failed":
          await handlePaymentFailed(event.data.object);
          break;

        case "charge.refunded":
          await handleChargeRefunded(event.data.object);
          break;

        default:
          // Acknowledge but don't process unknown events
          console.log(`[stripeWebhook] Unhandled event type: ${event.type}`);
      }

      res.status(200).json({ received: true });
    } catch (err) {
      console.error("[stripeWebhook] Handler error:", err);
      // Return 200 to prevent Stripe retrying — log and investigate manually
      res.status(200).json({ received: true, warning: "Handler error logged." });
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// Event handlers
// ─────────────────────────────────────────────────────────────────────────────

/**
 * payment_intent.succeeded
 * Marks the matching order as "paid".
 */
async function handlePaymentSucceeded(paymentIntent) {
  const { id: paymentIntentId, metadata } = paymentIntent;
  const orderId = metadata?.orderId;

  if (!orderId) {
    console.warn("[handlePaymentSucceeded] No orderId in metadata for:", paymentIntentId);
    return;
  }

  const orderRef = db.collection(ORDERS_COL).doc(orderId);
  const orderDoc = await orderRef.get();

  if (!orderDoc.exists) {
    console.error(`[handlePaymentSucceeded] Order "${orderId}" not found.`);
    return;
  }

  // Idempotency: don't downgrade status if already paid/shipped/completed
  const currentStatus = orderDoc.data().status;
  if (["paid", "shipped", "completed"].includes(currentStatus)) {
    console.log(`[handlePaymentSucceeded] Order "${orderId}" already in "${currentStatus}" — skipping.`);
    return;
  }

  await orderRef.update({
    status    : "paid",
    paidAt    : new Date().toISOString(),
    paymentIntentId,
  });

  console.log(`[handlePaymentSucceeded] Order "${orderId}" marked as paid.`);
}

/**
 * payment_intent.payment_failed
 * Marks the matching order as "failed" and restores stock.
 */
async function handlePaymentFailed(paymentIntent) {
  const { id: paymentIntentId, metadata } = paymentIntent;
  const orderId = metadata?.orderId;

  if (!orderId) {
    console.warn("[handlePaymentFailed] No orderId in metadata for:", paymentIntentId);
    return;
  }

  const orderRef = db.collection(ORDERS_COL).doc(orderId);
  const orderDoc = await orderRef.get();

  if (!orderDoc.exists) {
    console.error(`[handlePaymentFailed] Order "${orderId}" not found.`);
    return;
  }

  if (orderDoc.data().status !== "pending") {
    console.log(`[handlePaymentFailed] Order "${orderId}" is not pending — skipping.`);
    return;
  }

  // Restore stock for each item
  const batch = db.batch();
  const items = orderDoc.data().items || [];
  for (const item of items) {
    const productRef = db.collection("products").doc(item.productId);
    const { FieldValue } = require("firebase-admin/firestore");
    batch.update(productRef, { stockQuantity: FieldValue.increment(item.quantity) });
  }

  batch.update(orderRef, { status: "failed", failedAt: new Date().toISOString() });
  await batch.commit();

  console.log(`[handlePaymentFailed] Order "${orderId}" marked as failed, stock restored.`);
}

/**
 * charge.refunded
 * Marks the matching order as "refunded".
 */
async function handleChargeRefunded(charge) {
  const paymentIntentId = charge.payment_intent;

  if (!paymentIntentId) return;

  // Find the order by paymentIntentId
  const snap = await db
    .collection(ORDERS_COL)
    .where("paymentIntentId", "==", paymentIntentId)
    .limit(1)
    .get();

  if (snap.empty) {
    console.warn(`[handleChargeRefunded] No order found for PaymentIntent: ${paymentIntentId}`);
    return;
  }

  await snap.docs[0].ref.update({
    status     : "refunded",
    refundedAt : new Date().toISOString(),
  });

  console.log(`[handleChargeRefunded] Order for PaymentIntent "${paymentIntentId}" marked as refunded.`);
}

// ─────────────────────────────────────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────────────────────────────────────
module.exports = { stripeWebhook };
