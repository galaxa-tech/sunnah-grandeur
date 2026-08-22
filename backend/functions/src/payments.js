/**
 * payments.js
 * -----------
 * Cloud Functions for Stripe payment processing.
 *
 * Exported callable functions:
 *   - createPaymentIntent — creates a Stripe PaymentIntent and returns clientSecret
 *   - verifyPayment       — checks the status of a PaymentIntent from the server side
 *
 * Security: All Stripe interactions happen server-side.
 *           The frontend never touches the Stripe secret key.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore }        = require("firebase-admin/firestore");
const Stripe                  = require("stripe");

// Lazy-initialise Stripe with the secret key from environment
let stripeClient = null;
function getStripe() {
  if (!stripeClient) {
    const key = process.env.STRIPE_SECRET_KEY;
    if (!key) throw new Error("STRIPE_SECRET_KEY is not set in environment.");
    stripeClient = new Stripe(key, { apiVersion: "2024-06-20" });
  }
  return stripeClient;
}

const db         = getFirestore();
const ORDERS_COL = "orders";
const CURRENCY   = process.env.CURRENCY || "usd";

// ─────────────────────────────────────────────────────────────────────────────
// createPaymentIntent
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Creates a Stripe PaymentIntent and stores the paymentIntentId on the order.
 *
 * Request data:
 *   {
 *     orderId  : string   (Firestore order document ID)
 *   }
 *
 * Response:
 *   {
 *     clientSecret     : string   (pass to Stripe SDK on the client)
 *     paymentIntentId  : string
 *   }
 */
const createPaymentIntent = onCall({ region: "us-central1" }, async (request) => {
  try {
    const { orderId } = request.data || {};

    // ── Validation ────────────────────────────────────────────────────────────
    if (!orderId || typeof orderId !== "string") {
      throw new HttpsError("invalid-argument", "orderId is required.");
    }

    // ── Fetch order to verify it exists and is pending ────────────────────────
    const orderRef = db.collection(ORDERS_COL).doc(orderId);
    const orderDoc = await orderRef.get();

    if (!orderDoc.exists) {
      throw new HttpsError("not-found", `Order "${orderId}" not found.`);
    }

    const order = orderDoc.data();
    const amount = Math.round(order.total * 100); // Convert from validated Firestore decimal to minor units (cents)

    if (!amount || amount < 50) {
      throw new HttpsError("failed-precondition", "Order has an invalid total amount.");
    }

    if (order.status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        `Order is already in "${order.status}" status. Cannot create a new payment intent.`
      );
    }

    // ── Create PaymentIntent on Stripe ────────────────────────────────────────
    const stripe = getStripe();
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency       : CURRENCY,
      metadata       : { orderId, userId: order.userId },
      // Enables future payment method saving
      automatic_payment_methods: { enabled: true },
    });

    // ── Store paymentIntentId on the order document ───────────────────────────
    await orderRef.update({ paymentIntentId: paymentIntent.id });

    return {
      clientSecret    : paymentIntent.client_secret,
      paymentIntentId : paymentIntent.id,
    };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    console.error("[createPaymentIntent] Stripe error:", err.message);
    throw new HttpsError("internal", "Failed to create payment intent. Please try again.");
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// verifyPayment
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Verifies the current status of a Stripe PaymentIntent from the server side.
 * Use this as a fallback if the webhook hasn't fired yet.
 *
 * Request data:
 *   { paymentIntentId: string }
 *
 * Response:
 *   {
 *     paymentIntentId : string
 *     status          : string   (Stripe PaymentIntent status)
 *     paid            : boolean
 *   }
 */
const verifyPayment = onCall({ region: "us-central1" }, async (request) => {
  try {
    const { paymentIntentId } = request.data || {};

    if (!paymentIntentId || typeof paymentIntentId !== "string") {
      throw new HttpsError("invalid-argument", "paymentIntentId is required.");
    }

    const stripe = getStripe();
    const pi = await stripe.paymentIntents.retrieve(paymentIntentId);

    return {
      paymentIntentId : pi.id,
      status          : pi.status,
      paid            : pi.status === "succeeded",
    };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    // Stripe "invalid_request_error" means the ID doesn't exist
    if (err.type === "StripeInvalidRequestError") {
      throw new HttpsError("not-found", "PaymentIntent not found.");
    }
    console.error("[verifyPayment] Error:", err.message);
    throw new HttpsError("internal", "Failed to verify payment. Please try again.");
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────────────────────────────────────
module.exports = { createPaymentIntent, verifyPayment };
