"use strict";

const { onCall } = require("firebase-functions/v2/https");
const { db, COL } = require("../../lib/db");

// ── getHadiths ────────────────────────────────────────────────────────────────
// Public read. Returns active hadith posts ordered by displayOrder, then date.
// Clients can also read directly from Firestore (rules allow public read).

const getHadiths = onCall({ region: "us-central1" }, async (request) => {
  const rawLimit = request.data?.limit;
  const limit = Math.min(Math.max(Number(rawLimit) || 10, 1), 30);

  const snap = await db.collection(COL.HADITHS)
    .where("isActive", "==", true)
    .orderBy("displayOrder", "asc")
    .limit(limit)
    .get();

  return {
    hadiths: snap.docs.map((doc) => {
      const d = doc.data();
      return {
        id:          doc.id,
        textEn:      d.textEn      ?? "",
        textAr:      d.textAr      ?? "",
        textBn:      d.textBn      ?? "",
        source:      d.source      ?? "",
        displayOrder:d.displayOrder ?? 0,
      };
    }),
  };
});

module.exports = { getHadiths };
