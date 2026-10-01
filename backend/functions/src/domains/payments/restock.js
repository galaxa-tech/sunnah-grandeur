"use strict";

const { FieldValue } = require("firebase-admin/firestore");
const { db, COL }    = require("../../lib/db");

// Cancels a still-unpaid card order and returns its reserved stock.
// Transactional + status-guarded, so concurrent calls (webhook retry, cron)
// can never restore the same stock twice.
async function cancelUnpaidOrder(orderId, reason) {
  const ref = db.collection(COL.ORDERS).doc(orderId);
  return db.runTransaction(async (t) => {
    const doc = await t.get(ref);
    if (!doc.exists || doc.data().status !== "pending_payment") return false;
    for (const item of (doc.data().items ?? [])) {
      t.update(db.collection(COL.PRODUCTS).doc(item.productId), {
        stockQuantity: FieldValue.increment(item.quantity),
        updatedAt:     FieldValue.serverTimestamp(),
      });
    }
    t.update(ref, {
      status:        "Cancelled",
      paymentStatus: "unpaid",
      cancelReason:  reason,
      updatedAt:     FieldValue.serverTimestamp(),
    });
    return true;
  });
}

module.exports = { cancelUnpaidOrder };
