"use strict";

const { onRequest }    = require("firebase-functions/v2/https");
const { FieldValue }   = require("firebase-admin/firestore");
const { db, COL }      = require("../../lib/db");
const { getStripe }    = require("../../lib/stripe");

// ── stripeWebhook ─────────────────────────────────────────────────────────────
//
// Stripe calls this endpoint after payment events.
// Signature verification ensures only genuine Stripe events are processed.
//
// Handled events:
//   payment_intent.succeeded      → status: 'paid'
//   payment_intent.payment_failed → status: 'failed', stock restored
//   charge.refunded               → status: 'refunded'

const stripeWebhook = onRequest(
  { region: "us-central1", rawBody: true, timeoutSeconds: 60 },
  async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    const secret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!secret) {
      console.error("[webhook] STRIPE_WEBHOOK_SECRET not set.");
      return res.status(500).send("Webhook secret not configured.");
    }

    let event;
    try {
      event = getStripe().webhooks.constructEvent(
        req.rawBody,
        req.headers["stripe-signature"],
        secret,
      );
    } catch (err) {
      console.error("[webhook] Signature verification failed:", err.message);
      return res.status(400).send(`Signature error: ${err.message}`);
    }

    try {
      switch (event.type) {
        case "payment_intent.succeeded":
          await _onPaymentSucceeded(event.data.object);
          break;
        case "payment_intent.payment_failed":
          await _onPaymentFailed(event.data.object);
          break;
        case "charge.refunded":
          await _onChargeRefunded(event.data.object);
          break;
        default:
          // Acknowledge unknown events without processing
          break;
      }
      res.status(200).json({ received: true });
    } catch (err) {
      // Return 200 to prevent Stripe retrying — log and alert separately
      console.error("[webhook] Handler threw:", err);
      res.status(200).json({ received: true, warning: "handler_error" });
    }
  },
);

// ── Event handlers ────────────────────────────────────────────────────────────

async function _onPaymentSucceeded(intent) {
  const orderId = intent.metadata?.orderId;
  if (!orderId) return;

  const ref = db.collection(COL.ORDERS).doc(orderId);
  const doc = await ref.get();
  if (!doc.exists) return;

  // Idempotency: never downgrade a status that is already past 'paid'
  const currentStatus = doc.data().status;
  if (["paid", "processing", "shipped", "delivered"].includes(currentStatus)) return;

  await ref.update({
    status:          "paid",
    paymentIntentId: intent.id,
    paidAt:          FieldValue.serverTimestamp(),
    updatedAt:       FieldValue.serverTimestamp(),
  });
}

async function _onPaymentFailed(intent) {
  const orderId = intent.metadata?.orderId;
  if (!orderId) return;

  const ref = db.collection(COL.ORDERS).doc(orderId);
  const doc = await ref.get();
  if (!doc.exists || doc.data().status !== "pending_payment") return;

  // Restore stock for each line item
  const batch = db.batch();
  for (const item of (doc.data().items ?? [])) {
    batch.update(
      db.collection(COL.PRODUCTS).doc(item.productId),
      { stockQuantity: FieldValue.increment(item.quantity), updatedAt: FieldValue.serverTimestamp() },
    );
  }
  batch.update(ref, {
    status:    "failed",
    failedAt:  FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
}

async function _onChargeRefunded(charge) {
  const intentId = charge.payment_intent;
  if (!intentId) return;

  const snap = await db.collection(COL.ORDERS)
    .where("paymentIntentId", "==", intentId)
    .limit(1)
    .get();

  if (snap.empty) return;

  await snap.docs[0].ref.update({
    status:     "refunded",
    refundedAt: FieldValue.serverTimestamp(),
    updatedAt:  FieldValue.serverTimestamp(),
  });
}

module.exports = { stripeWebhook };
