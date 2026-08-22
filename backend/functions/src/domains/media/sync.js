"use strict";

const { onCall }             = require("firebase-functions/v2/https");
const { onSchedule }         = require("firebase-functions/v2/scheduler");
const { FieldValue }         = require("firebase-admin/firestore");
const { google }             = require("googleapis");
const { requireAdmin }       = require("../../middleware/auth");
const { db, COL }            = require("../../lib/db");

// Lazy-initialized at call time — NOT at module load.
// Initializing at module top-level causes a 10 s timeout during `firebase deploy`.
function getYoutube() {
  return google.youtube("v3");
}

// ── _performSync ──────────────────────────────────────────────────────────────
// Reads YouTube source configuration from Firestore config collection,
// then batch-upserts video metadata into the media collection.

async function _performSync() {
  const apiKey = process.env.YOUTUBE_API_KEY;
  if (!apiKey) throw new Error("YOUTUBE_API_KEY not set.");

  const configSnap = await db.collection(COL.CONFIG).doc("youtube_sources").get();
  if (!configSnap.exists) throw new Error("youtube_sources config document not found.");

  const { sources } = configSnap.data();
  if (!Array.isArray(sources) || sources.length === 0) {
    throw new Error("sources array is empty or missing.");
  }

  const results = [];

  for (const source of sources) {
    const { playlistId, type, category } = source;
    if (!playlistId) continue;

    try {
      const resp = await getYoutube().playlistItems.list({
        key:        apiKey,
        part:       "snippet,contentDetails",
        playlistId,
        maxResults: 50,
      });

      const items = resp.data.items ?? [];
      const batch = db.batch();

      for (const item of items) {
        const videoId = item.contentDetails.videoId;
        const snip    = item.snippet;
        const ref     = db.collection(COL.MEDIA).doc(`yt_${videoId}`);

        batch.set(ref, {
          type,
          category,
          title:        snip.title,
          youtubeId:    videoId,
          thumbnailUrl: snip.thumbnails?.high?.url ?? snip.thumbnails?.default?.url ?? null,
          publishedAt:  snip.publishedAt ? new Date(snip.publishedAt) : null,
          isActive:     true,
          source:       "youtube",
          syncedAt:     FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      await batch.commit();
      results.push({ playlistId, type, category, synced: items.length });
    } catch (err) {
      console.error(`[sync] Failed for playlist ${playlistId}:`, err.message);
      results.push({ playlistId, error: err.message });
    }
  }

  return { results, syncedAt: new Date().toISOString() };
}

// ── triggerSync (admin-only callable) ─────────────────────────────────────────

const triggerSync = onCall({ region: "us-central1" }, async (request) => {
  requireAdmin(request);   // Prevents public abuse of YouTube API quota
  return await _performSync();
});

// ── scheduledSync (daily at 03:00 UTC) ───────────────────────────────────────

const scheduledSync = onSchedule(
  { schedule: "0 3 * * *", region: "us-central1" },
  async () => {
    const result = await _performSync();
    console.log("[scheduledSync] Complete:", JSON.stringify(result));
  },
);

module.exports = { triggerSync, scheduledSync };
