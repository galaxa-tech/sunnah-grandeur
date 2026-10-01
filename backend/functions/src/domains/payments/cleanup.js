"use strict";

const { onSchedule }        = require("firebase-functions/v2/scheduler");
const { Timestamp }         = require("firebase-admin/firestore");
const { db, COL }           = require("../../lib/db");
const { cancelUnpaidOrder } = require("./restock");

// Card orders reserve stock at creation. If the customer abandons payment the
// order would hold that stock forever — release anything unpaid after 1 hour.
const cancelAbandonedOrders = onSchedule(
  { region: "us-central1", schedule: "every 30 minutes" },
  async () => {
    const cutoff = Timestamp.fromMillis(Date.now() - 60 * 60 * 1000);
    const snap = await db.collection(COL.ORDERS)
      .where("status", "==", "pending_payment")
      .where("createdAt", "<", cutoff)
      .limit(200)
      .get();
    for (const doc of snap.docs) {
      await cancelUnpaidOrder(doc.id, "payment_abandoned");
    }
    console.log(`[cleanup] cancelled ${snap.size} abandoned order(s)`);
  },
);

module.exports = { cancelAbandonedOrders };
