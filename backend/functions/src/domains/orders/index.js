"use strict";

const crypto                       = require("crypto");
const { onCall, HttpsError }       = require("firebase-functions/v2/https");
const { FieldValue }               = require("firebase-admin/firestore");
const { requireAuth, requireAdmin } = require("../../middleware/auth");
const { validate }                 = require("../../middleware/validate");
const { db, COL }                  = require("../../lib/db");
const { validateUsShipping }       = require("../../lib/addressValidation");
const { stripeTaxRatePpm }         = require("../../lib/tax");
const { getStripe }                = require("../../lib/stripe");
const { cancelAndRestock }         = require("../payments/restock");

// ── Schemas ───────────────────────────────────────────────────────────────────

// Payment methods: "card" (Stripe: card/Apple Pay/Google Pay/Link), "paypal"
// (PayPal + Venmo). "cod" is NOT offered in the US; it is only accepted when
// settings/app_config.codEnabled is explicitly true (legacy mobile builds).
const createOrderSchema = {
  items:         { required: true, type: "array", min: 1, max: 50 },
  shipping:      { required: true, type: "object" },
  paymentMethod: { required: false, type: "string", enum: ["cod", "card", "paypal"] },
  requestId:     { required: false, type: "string", min: 8, max: 64 },
};

// Order lifecycle. "pending_payment" is a transient state before payment is
// confirmed (Stripe webhook / PayPal capture); legacy COD starts "Processing".
const ORDER_STATUSES = ["pending_payment", "Processing", "Shipped", "Delivered", "Cancelled"];

const shippingSchema = {
  name:       { required: true,  type: "string", min: 1, max: 100 },
  phone:      { required: true,  type: "string", max: 30 },
  email:      { required: true,  type: "string", max: 200 },
  line1:      { required: true,  type: "string", min: 1, max: 200 },
  city:       { required: true,  type: "string", min: 1, max: 100 },
  state:      { required: true,  type: "string", max: 100 },
  postalCode: { required: true,  type: "string", min: 1, max: 20 },
  country:    { required: true,  type: "string", min: 2, max: 2 },  // ISO 3166-1 alpha-2
  method:     { required: false, type: "string", enum: ["standard", "express"] },
};

const DEFAULT_BDT_TO_USD_RATE = 1 / 118;

async function loadConfig() {
  const snap = await db.collection(COL.SETTINGS).doc("app_config").get();
  const c = snap.exists ? snap.data() : {};
  return {
    taxRateBps:   c.taxRateBps ?? 0,
    // Shipping is free on all US orders unless a threshold is explicitly set.
    freeShippingThreshold: c.freeShippingThreshold ?? 0,
    standardShippingCents: c.standardShippingCents ?? 0,
    expressShippingCents:  c.expressShippingCents ?? 0,
    codEnabled:   c.codEnabled === true,
    usdToLocalRate: (typeof c.usdToLocalRate === "number" && c.usdToLocalRate > 0)
      ? c.usdToLocalRate : DEFAULT_BDT_TO_USD_RATE,
  };
}

// Price sourced from Firestore only. The admin panel writes a plain decimal
// `price` (entered as BDT); older docs may carry `priceInCents`.
function unitPriceInCents(p, usdToLocalRate) {
  return typeof p.price === "number"
    ? Math.round(p.price * usdToLocalRate * 100)
    : (p.priceInCents ?? 0);
}

function checkItems(items) {
  for (const [i, item] of items.entries()) {
    if (!item.productId || typeof item.productId !== "string") {
      throw new HttpsError("invalid-argument", `items[${i}].productId must be a string.`);
    }
    if (!Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > 100) {
      throw new HttpsError("invalid-argument", `items[${i}].quantity must be an integer between 1 and 100.`);
    }
  }
}

// Effective tax rate in parts-per-million for this destination: Stripe Tax by
// ZIP when available, otherwise the flat settings rate.
async function resolveTaxRatePpm(items, shipping, config) {
  const docs = await db.getAll(...items.map((i) => db.collection(COL.PRODUCTS).doc(i.productId)));
  let subtotal = 0;
  docs.forEach((d, idx) => {
    if (d.exists) subtotal += unitPriceInCents(d.data(), config.usdToLocalRate) * items[idx].quantity;
  });
  const ppm = await stripeTaxRatePpm(subtotal, shipping);
  return ppm ?? config.taxRateBps * 100;
}

function shippingCostCents(subtotalInCents, method, config) {
  if (subtotalInCents >= config.freeShippingThreshold) return 0;
  return method === "express" ? config.expressShippingCents : config.standardShippingCents;
}

// ── quoteOrder ────────────────────────────────────────────────────────────────
// Read-only price quote (subtotal / tax by ZIP / shipping / total) so the
// checkout page can show the real total before the customer pays.

const quoteOrder = onCall({ region: "us-central1" }, async (request) => {
  requireAuth(request);
  const data = request.data || {};
  validate(data, { items: { required: true, type: "array", min: 1, max: 50 }, shipping: { required: true, type: "object" } });
  checkItems(data.items);

  const s = data.shipping;
  const zip = String(s.postalCode || "").trim();
  const state = String(s.state || "").trim().toUpperCase();
  if (!/^\d{5}(-\d{4})?$/.test(zip) || state.length !== 2) {
    throw new HttpsError("invalid-argument", "Enter a valid ZIP code and state to calculate tax.");
  }

  const config = await loadConfig();
  const ppm = await resolveTaxRatePpm(data.items, { line1: s.line1 || "", city: s.city || "", state, postalCode: zip }, config);

  const docs = await db.getAll(...data.items.map((i) => db.collection(COL.PRODUCTS).doc(i.productId)));
  let subtotalInCents = 0;
  docs.forEach((d, idx) => {
    if (!d.exists) throw new HttpsError("not-found", `Product '${data.items[idx].productId}' does not exist.`);
    subtotalInCents += unitPriceInCents(d.data(), config.usdToLocalRate) * data.items[idx].quantity;
  });
  const taxInCents      = Math.round(subtotalInCents * ppm / 1_000_000);
  const shippingInCents = shippingCostCents(subtotalInCents, "standard", config);
  return { subtotalInCents, taxInCents, shippingInCents, totalInCents: subtotalInCents + taxInCents + shippingInCents };
});

// ── createOrder ───────────────────────────────────────────────────────────────
//
// SECURITY:
//   uid comes ONLY from request.auth.uid (the verified Firebase ID token).
//   Price comes ONLY from Firestore product documents.
//   Tax and shipping calculated server-side.
//   Client cannot influence order total in any way.
//   `requestId` makes retries idempotent: same user + same id = same order.

const createOrder = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireAuth(request);   // ← uid from token, NEVER from request.data

  validate(request.data, createOrderSchema);
  validate(request.data.shipping, shippingSchema);

  const { items, paymentMethod = "card", requestId } = request.data;
  checkItems(items);

  const config = await loadConfig();
  if (paymentMethod === "cod" && !config.codEnabled) {
    throw new HttpsError("failed-precondition",
      "Cash on delivery is not available. Please pay by card, PayPal or Venmo.");
  }

  // US-only + format validation (phone, email, ZIP/state, street address).
  const clean = validateUsShipping(request.data.shipping);
  const method = request.data.shipping.method === "express" ? "express" : "standard";
  const initialStatus = paymentMethod === "cod" ? "Processing" : "pending_payment";

  const taxPpm = await resolveTaxRatePpm(items, clean, config);

  const orderRef = requestId
    ? db.collection(COL.ORDERS).doc(crypto.createHash("sha256").update(`${uid}:${requestId}`).digest("hex").slice(0, 20))
    : db.collection(COL.ORDERS).doc();

  const result = await db.runTransaction(async (t) => {
    // Reads first: idempotency check, then all products.
    const existing = await t.get(orderRef);
    if (existing.exists) {
      const o = existing.data();
      if (o.userId !== uid) throw new HttpsError("already-exists", "Duplicate request id.");
      return {
        subtotalInCents: o.subtotalInCents, taxInCents: o.taxInCents,
        shippingInCents: o.shippingInCents, totalInCents: o.totalInCents,
        status: o.status, duplicate: true,
      };
    }

    const productRefs = items.map((i) => db.collection(COL.PRODUCTS).doc(i.productId));
    const productDocs = await t.getAll(...productRefs);

    let subtotalInCents = 0;
    const enrichedItems = [];

    for (let idx = 0; idx < items.length; idx++) {
      const doc  = productDocs[idx];
      const item = items[idx];

      if (!doc.exists) {
        throw new HttpsError("not-found", `Product '${item.productId}' does not exist.`);
      }
      const p = doc.data();
      if (!p.isActive) {
        throw new HttpsError("failed-precondition", `Product '${p.name}' is no longer available.`);
      }
      if (p.stockQuantity < item.quantity) {
        throw new HttpsError("resource-exhausted",
          `Insufficient stock for '${p.name}'. Available: ${p.stockQuantity}, requested: ${item.quantity}.`);
      }

      const unit = unitPriceInCents(p, config.usdToLocalRate);
      const lineTotalInCents = unit * item.quantity;
      subtotalInCents += lineTotalInCents;

      enrichedItems.push({
        productId:       item.productId,
        name:            p.name,
        sku:             p.sku,
        priceInCents:    unit,     // snapshot at time of order
        quantity:        item.quantity,
        lineTotalInCents,
      });

      t.update(doc.ref, {
        stockQuantity: FieldValue.increment(-item.quantity),
        updatedAt:     FieldValue.serverTimestamp(),
      });
    }

    const taxInCents      = Math.round(subtotalInCents * taxPpm / 1_000_000);
    const shippingInCents = shippingCostCents(subtotalInCents, method, config);
    const totalInCents    = subtotalInCents + taxInCents + shippingInCents;

    t.set(orderRef, {
      userId:           uid,          // from auth token only
      items:            enrichedItems,
      subtotalInCents,
      taxInCents,
      shippingInCents,
      totalInCents,
      status:           initialStatus,
      paymentMethod,
      paymentIntentId:  null,
      requestId:        requestId ?? null,
      shipping:         { ...clean, method },
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { subtotalInCents, taxInCents, shippingInCents, totalInCents, status: initialStatus, duplicate: false };
  });

  return { orderId: orderRef.id, ...result };
});

// ── getOrdersByUser ───────────────────────────────────────────────────────────
// Clients can also read orders directly via Firestore (rules enforce userId match).
// This function is provided for cases where server-side pagination is needed.

const getOrdersByUser = onCall({ region: "us-central1" }, async (request) => {
  const uid   = requireAuth(request);
  const limit = Math.min(Number(request.data?.limit) || 20, 50);

  const snap = await db.collection(COL.ORDERS)
    .where("userId", "==", uid)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  return {
    orders: snap.docs.map((doc) => {
      const d = doc.data();
      return {
        id:               doc.id,
        status:           d.status,
        totalInCents:     d.totalInCents,
        items:            d.items,
        shipping:         d.shipping,
        paymentIntentId:  d.paymentIntentId,
        createdAt:        d.createdAt?.toDate?.()?.toISOString() ?? null,
      };
    }),
  };
});

// ── Refund helper ─────────────────────────────────────────────────────────────
// Refunds a paid order's Stripe charge. Failures are recorded on the order for
// manual follow-up instead of failing the (already completed) cancellation.
async function refundIfPaid(orderId, order) {
  if (order.paymentStatus !== "paid") return "none";
  const ref = db.collection(COL.ORDERS).doc(orderId);
  try {
    if (order.paymentMethod === "paypal") {
      // PayPal refunds are issued from the PayPal dashboard / capture id.
      await ref.update({ refundPending: true, updatedAt: FieldValue.serverTimestamp() });
      return "manual";
    }
    if (!order.paymentIntentId) {
      await ref.update({ refundPending: true, updatedAt: FieldValue.serverTimestamp() });
      return "manual";
    }
    await getStripe().refunds.create(
      { payment_intent: order.paymentIntentId, metadata: { orderId } },
      { idempotencyKey: `refund_${orderId}` });
    await ref.update({ paymentStatus: "refunded", updatedAt: FieldValue.serverTimestamp() });
    return "refunded";
  } catch (err) {
    console.error("[refund] failed for order", orderId, err.message);
    await ref.update({ refundPending: true, refundError: String(err.message).slice(0, 300), updatedAt: FieldValue.serverTimestamp() });
    return "manual";
  }
}

// ── cancelOrder ───────────────────────────────────────────────────────────────
// Customer self-service cancellation, allowed until the order ships.

const cancelOrder = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireAuth(request);
  const { orderId } = request.data || {};
  if (!orderId || typeof orderId !== "string") {
    throw new HttpsError("invalid-argument", "'orderId' is required.");
  }

  const ref  = db.collection(COL.ORDERS).doc(orderId.trim());
  const snap = await ref.get();
  if (!snap.exists || snap.data().userId !== uid) {
    throw new HttpsError("not-found", "Order not found.");
  }

  const r = await cancelAndRestock(orderId.trim(), "customer_requested", ["pending_payment", "Processing"]);
  if (!r.cancelled) {
    if (r.previousStatus === "Cancelled") return { success: true, alreadyCancelled: true, refund: "none" };
    throw new HttpsError("failed-precondition",
      `This order is already ${r.previousStatus} and can no longer be cancelled online. Please contact support.`);
  }
  const refund = await refundIfPaid(orderId.trim(), r.order);
  return { success: true, refund };
});

// ── updateOrderStatus ─────────────────────────────────────────────────────────
// Admin-only. Firestore rules block direct client writes to /orders — this is
// the one sanctioned path for changing an order's fulfillment status.

const updateOrderStatus = onCall({ region: "us-central1" }, async (request) => {
  requireAdmin(request);

  const { orderId, status } = request.data || {};

  if (!orderId || typeof orderId !== "string") {
    throw new HttpsError("invalid-argument", "'orderId' is required.");
  }
  if (!ORDER_STATUSES.includes(status)) {
    throw new HttpsError("invalid-argument", `'status' must be one of: ${ORDER_STATUSES.join(", ")}.`);
  }

  const orderRef = db.collection(COL.ORDERS).doc(orderId);
  const orderDoc = await orderRef.get();
  if (!orderDoc.exists) {
    throw new HttpsError("not-found", `Order '${orderId}' does not exist.`);
  }

  // Cancelling returns stock (once) and refunds a paid order.
  if (status === "Cancelled") {
    const r = await cancelAndRestock(orderId, "admin_cancelled", ["pending_payment", "Processing", "Shipped", "Delivered"]);
    const refund = r.cancelled ? await refundIfPaid(orderId, r.order) : "none";
    return { success: true, orderId, status, refund };
  }

  await orderRef.update({
    status,
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { success: true, orderId, status };
});

module.exports = { createOrder, quoteOrder, cancelOrder, getOrdersByUser, updateOrderStatus };
