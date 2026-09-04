"use strict";

const { onCall, HttpsError }       = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { requireAuth, requireAdmin } = require("../../middleware/auth");
const { validate }                 = require("../../middleware/validate");
const { db, COL }                  = require("../../lib/db");

// ── Schemas ───────────────────────────────────────────────────────────────────

const createOrderSchema = {
  items:         { required: true, type: "array", min: 1, max: 50 },
  shipping:      { required: true, type: "object" },
  paymentMethod: { required: false, type: "string", enum: ["cod", "card"] },
};

// Order lifecycle. "pending_payment" is a card-only transient state before the
// Stripe webhook confirms payment; COD orders skip it and start "Processing".
const ORDER_STATUSES = ["pending_payment", "Processing", "Shipped", "Delivered", "Cancelled"];

const shippingSchema = {
  name:       { required: true,  type: "string", min: 1, max: 100 },
  phone:      { required: false, type: "string", max: 30 },
  email:      { required: false, type: "string", max: 200 },
  line1:      { required: true,  type: "string", min: 1, max: 200 },
  city:       { required: true,  type: "string", min: 1, max: 100 },
  state:      { required: false, type: "string", max: 100 },
  postalCode: { required: true,  type: "string", min: 1, max: 20 },
  country:    { required: true,  type: "string", min: 2, max: 2 },  // ISO 3166-1 alpha-2
  method:     { required: true,  type: "string", enum: ["standard", "express"] },
};

// ── createOrder ───────────────────────────────────────────────────────────────
//
// SECURITY:
//   uid comes ONLY from request.auth.uid (the verified Firebase ID token).
//   Price comes ONLY from Firestore product documents.
//   Tax and shipping calculated server-side from settings.
//   Client cannot influence order total in any way.

const createOrder = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireAuth(request);   // ← uid from token, NEVER from request.data

  validate(request.data, createOrderSchema);
  validate(request.data.shipping, shippingSchema);

  const { items, shipping, paymentMethod = "card" } = request.data;
  const initialStatus = paymentMethod === "cod" ? "Processing" : "pending_payment";

  // Validate each item shape before the transaction
  for (const [i, item] of items.entries()) {
    if (!item.productId || typeof item.productId !== "string") {
      throw new HttpsError("invalid-argument", `items[${i}].productId must be a string.`);
    }
    if (!Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > 100) {
      throw new HttpsError("invalid-argument", `items[${i}].quantity must be an integer between 1 and 100.`);
    }
  }

  // Fetch app config for tax rate + free-shipping threshold
  const configSnap = await db.collection(COL.SETTINGS).doc("app_config").get();
  const config     = configSnap.exists ? configSnap.data() : {};

  // taxRateBps: basis points (e.g. 875 = 8.75%)
  const taxRateBps              = config.taxRateBps              ?? 0;
  const freeShippingThreshold   = config.freeShippingThreshold   ?? 5000;   // cents
  const standardShippingCents   = config.standardShippingCents   ?? 999;
  const expressShippingCents    = config.expressShippingCents    ?? 1999;

  const orderRef = db.collection(COL.ORDERS).doc();

  const { subtotalInCents, taxInCents, shippingInCents, totalInCents, enrichedItems } =
    await db.runTransaction(async (t) => {

      // Atomically read all products
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

        // ── Price sourced from Firestore only ─────────────────────────────────
        const lineTotalInCents = p.priceInCents * item.quantity;
        subtotalInCents += lineTotalInCents;

        enrichedItems.push({
          productId:       item.productId,
          name:            p.name,
          sku:             p.sku,
          priceInCents:    p.priceInCents,     // snapshot at time of order
          quantity:        item.quantity,
          lineTotalInCents,
        });

        // Decrement stock atomically
        t.update(doc.ref, {
          stockQuantity: FieldValue.increment(-item.quantity),
          updatedAt:     FieldValue.serverTimestamp(),
        });
      }

      const taxInCents      = Math.round(subtotalInCents * taxRateBps / 10000);
      const shippingInCents = subtotalInCents >= freeShippingThreshold
        ? 0
        : shipping.method === "express"
          ? expressShippingCents
          : standardShippingCents;
      const totalInCents = subtotalInCents + taxInCents + shippingInCents;

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
        shipping: {
          name:       shipping.name,
          phone:      shipping.phone ?? "",
          email:      shipping.email ?? "",
          line1:      shipping.line1,
          city:       shipping.city,
          state:      shipping.state ?? "",
          postalCode: shipping.postalCode,
          country:    shipping.country,
          method:     shipping.method,
        },
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { subtotalInCents, taxInCents, shippingInCents, totalInCents, enrichedItems };
    });

  return {
    orderId:          orderRef.id,
    subtotalInCents,
    taxInCents,
    shippingInCents,
    totalInCents,
    status:           initialStatus,
  };
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

  await orderRef.update({
    status,
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { success: true, orderId, status };
});

module.exports = { createOrder, getOrdersByUser, updateOrderStatus };
