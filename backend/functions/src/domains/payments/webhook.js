"use strict";

const { onRequest }    = require("firebase-functions/v2/https");
const { FieldValue }   = require("firebase-admin/firestore");
const { db, COL }      = require("../../lib/db");
const { getStripe }    = require("../../lib/stripe");
const { cancelUnpaidOrder } = require("./restock");

// ── stripeWebhook ─────────────────────────────────────────────────────────────
//
// Stripe calls this endpoint after payment events.
// Signature verification ensures only genuine Stripe events are processed.
//
// Handled events:
//   payment_intent.succeeded      → Processing + paymentStatus 'paid'
//   payment_intent.payment_failed → error recorded (customer may retry)
//   checkout.session.expired      → order Cancelled, stock restored
//   charge.refunded               → paymentStatus 'refunded'

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
        case "checkout.session.expired":
          await _onSessionExpired(event.data.object);
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
// Order statuses are the admin-panel lifecycle (pending_payment | Processing |
// Shipped | Delivered | Cancelled); payment state lives in `paymentStatus`.

async function _onPaymentSucceeded(intent) {
  const orderId = intent.metadata?.orderId;
  if (!orderId) return;

  const ref = db.collection(COL.ORDERS).doc(orderId);
  await db.runTransaction(async (t) => {
    const doc = await t.get(ref);
    if (!doc.exists) return;
    const { status } = doc.data();
    // Idempotent: only a pending order is promoted. A "Cancelled" order that
    // got paid late (stock already released) is flagged for manual review.
    if (status === "pending_payment") {
      t.update(ref, {
        status:          "Processing",
        paymentStatus:   "paid",
        paymentIntentId: intent.id,
        paidAt:          FieldValue.serverTimestamp(),
        updatedAt:       FieldValue.serverTimestamp(),
      });
    } else if (status === "Cancelled") {
      t.update(ref, {
        paymentStatus:   "paid_after_cancel",
        paymentIntentId: intent.id,
        updatedAt:       FieldValue.serverTimestamp(),
      });
    }
  });
}

// A single failed attempt is NOT terminal — the customer can retry on the same
// intent/session. Abandonment is handled by checkout.session.expired and the
// scheduled cleanup, so here we only record the failure.
async function _onPaymentFailed(intent) {
  const orderId = intent.metadata?.orderId;
  if (!orderId) return;
  await db.collection(COL.ORDERS).doc(orderId).update({
    lastPaymentError: intent.last_payment_error?.message ?? "payment_failed",
    updatedAt:        FieldValue.serverTimestamp(),
  }).catch(() => {});
}

async function _onSessionExpired(session) {
  const orderId = session.metadata?.orderId;
  if (orderId) await cancelUnpaidOrder(orderId, "checkout_expired");
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
    paymentStatus: "refunded",
    refundedAt:    FieldValue.serverTimestamp(),
    updatedAt:     FieldValue.serverTimestamp(),
  });
}

module.exports = { stripeWebhook };
