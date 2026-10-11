"use strict";

const { FieldValue } = require("firebase-admin/firestore");
const { db, COL }    = require("../../lib/db");

// Cancels an order that is in one of `allowedStatuses` and returns its reserved
// stock. Transactional + status-guarded, so concurrent calls (webhook retry,
// cron, customer double-click) can never restore the same stock twice.
// Returns { cancelled, previousStatus, order } — order is the pre-cancel data.
async function cancelAndRestock(orderId, reason, allowedStatuses, extra = {}) {
  const ref = db.collection(COL.ORDERS).doc(orderId);
  return db.runTransaction(async (t) => {
    const doc = await t.get(ref);
    if (!doc.exists) return { cancelled: false, previousStatus: null, order: null };
    const order = doc.data();
    if (!allowedStatuses.includes(order.status)) {
      return { cancelled: false, previousStatus: order.status, order };
    }
    for (const item of (order.items ?? [])) {
      t.update(db.collection(COL.PRODUCTS).doc(item.productId), {
        stockQuantity: FieldValue.increment(item.quantity),
        updatedAt:     FieldValue.serverTimestamp(),
      });
    }
    t.update(ref, {
      status:        "Cancelled",
      paymentStatus: order.paymentStatus === "paid" ? "paid" : "unpaid",
      cancelReason:  reason,
      cancelledAt:   FieldValue.serverTimestamp(),
      updatedAt:     FieldValue.serverTimestamp(),
      ...extra,
    });
    return { cancelled: true, previousStatus: order.status, order };
  });
}

// Cancels a still-unpaid card order (webhook expiry / abandoned-order cron).
async function cancelUnpaidOrder(orderId, reason) {
  const r = await cancelAndRestock(orderId, reason, ["pending_payment"]);
  return r.cancelled;
}

module.exports = { cancelUnpaidOrder, cancelAndRestock };
