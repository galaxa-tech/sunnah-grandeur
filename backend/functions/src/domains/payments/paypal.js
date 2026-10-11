"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { FieldValue }         = require("firebase-admin/firestore");
const { requireAuth }        = require("../../middleware/auth");
const { db, COL }            = require("../../lib/db");
const { CURRENCY }           = require("../../lib/stripe");

// PayPal (also carries Venmo for US buyers via the PayPal JS SDK button).
// Env: PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET, PAYPAL_ENV=sandbox|live.
// Amount always comes from the Firestore order — never from the client.

function base() {
  return process.env.PAYPAL_ENV === "live"
    ? "https://api-m.paypal.com"
    : "https://api-m.sandbox.paypal.com";
}

async function accessToken() {
  const id = process.env.PAYPAL_CLIENT_ID;
  const secret = process.env.PAYPAL_CLIENT_SECRET;
  if (!id || !secret) {
    throw new HttpsError("failed-precondition", "PayPal is not available right now. Please pay by card.");
  }
  const res = await fetch(`${base()}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${Buffer.from(`${id}:${secret}`).toString("base64")}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  if (!res.ok) throw new HttpsError("unavailable", "Could not reach PayPal. Please try again.");
  return (await res.json()).access_token;
}

async function loadOwnedPendingOrder(uid, orderId) {
  if (!orderId || typeof orderId !== "string") {
    throw new HttpsError("invalid-argument", "'orderId' is required.");
  }
  const ref = db.collection(COL.ORDERS).doc(orderId.trim());
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Order not found.");
  const order = snap.data();
  if (order.userId !== uid) throw new HttpsError("permission-denied", "You do not have access to this order.");
  if (order.status !== "pending_payment") {
    throw new HttpsError("failed-precondition", `Order is in '${order.status}' status. Payment cannot be initiated.`);
  }
  return { ref, order };
}

const createPaypalOrder = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireAuth(request);
  const { ref, order } = await loadOwnedPendingOrder(uid, request.data?.orderId);
  const token = await accessToken();

  const res = await fetch(`${base()}/v2/checkout/orders`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", "PayPal-Request-Id": `sg_${ref.id}_${order.totalInCents}` },
    body: JSON.stringify({
      intent: "CAPTURE",
      purchase_units: [{
        reference_id: ref.id,
        custom_id: ref.id,
        description: `Sunnah Grandeur order ${ref.id}`,
        amount: { currency_code: CURRENCY.toUpperCase(), value: (order.totalInCents / 100).toFixed(2) },
      }],
    }),
  });
  if (!res.ok) throw new HttpsError("unavailable", "PayPal could not start this payment. Please try again or use a card.");
  const data = await res.json();
  await ref.update({ paypalOrderId: data.id, paymentMethod: "paypal", updatedAt: FieldValue.serverTimestamp() });
  return { paypalOrderId: data.id };
});

const capturePaypalOrder = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireAuth(request);
  const { ref, order } = await loadOwnedPendingOrder(uid, request.data?.orderId);
  if (!order.paypalOrderId || order.paypalOrderId !== request.data?.paypalOrderId) {
    throw new HttpsError("failed-precondition", "PayPal payment does not match this order.");
  }
  const token = await accessToken();

  const res = await fetch(`${base()}/v2/checkout/orders/${encodeURIComponent(order.paypalOrderId)}/capture`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", "PayPal-Request-Id": `sg_cap_${ref.id}` },
  });
  const data = await res.json().catch(() => ({}));
  const capture = data?.purchase_units?.[0]?.payments?.captures?.[0];
  if (!res.ok || data.status !== "COMPLETED" || !capture) {
    await ref.update({ lastPaymentError: String(data?.message || data?.name || "paypal_capture_failed").slice(0, 200), updatedAt: FieldValue.serverTimestamp() });
    throw new HttpsError("failed-precondition", "PayPal payment was not completed. You have not been charged. Please try again.");
  }
  if (Math.round(parseFloat(capture.amount.value) * 100) !== order.totalInCents) {
    await ref.update({ paymentStatus: "amount_mismatch", updatedAt: FieldValue.serverTimestamp() });
    throw new HttpsError("internal", "Payment amount mismatch. Please contact support.");
  }

  await ref.update({
    status: "Processing",
    paymentStatus: "paid",
    paypalCaptureId: capture.id,
    paidAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { success: true, orderId: ref.id };
});

module.exports = { createPaypalOrder, capturePaypalOrder };
