"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { validate }           = require("../../middleware/validate");
const { db, COL }            = require("../../lib/db");

const VALID_TYPES      = ["lecture", "short", "quran", "ruqyah"];
const DEFAULT_LIMIT    = 50;
const MAX_LIMIT        = 100;

const getMediaSchema = {
  type:     { required: false, type: "string", enum: VALID_TYPES },
  category: { required: false, type: "string", max: 100 },
  limit:    { required: false, type: "number", integer: true, min: 1, max: MAX_LIMIT },
};

// ── getMedia ──────────────────────────────────────────────────────────────────
// Public. Direct Firestore reads from the client are equally valid
// (Firestore rules allow public read for isActive items).
// This function is useful when you need server-side filtering/composition.

const getMedia = onCall({ region: "us-central1" }, async (request) => {
  validate(request.data || {}, getMediaSchema);

  const { type, category, limit: rawLimit = DEFAULT_LIMIT } = request.data || {};
  const limit = Math.min(Number(rawLimit) || DEFAULT_LIMIT, MAX_LIMIT);

  let query = db.collection(COL.MEDIA).where("isActive", "==", true);

  if (type)     query = query.where("type",     "==", type);
  if (category) query = query.where("category", "==", category);

  query = query.orderBy("publishedAt", "desc").limit(limit);

  const snap = await query.get();

  return {
    media: snap.docs.map((doc) => {
      const d = doc.data();
      return {
        id:           doc.id,
        type:         d.type,
        category:     d.category,
        title:        d.title,
        youtubeId:    d.youtubeId,
        thumbnailUrl: d.thumbnailUrl ?? `https://img.youtube.com/vi/${d.youtubeId}/mqdefault.jpg`,
        publishedAt:  d.publishedAt?.toDate?.()?.toISOString() ?? null,
      };
    }),
    count: snap.size,
  };
});

module.exports = { getMedia };
