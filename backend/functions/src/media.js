/**
 * media.js
 * --------
 * Cloud Functions for the Media Hub system.
 *
 * Exported callable functions:
 *   - getMedia      — returns media items filtered by type (video, quran, ruqyah)
 *   - triggerSync   — manual trigger for YouTube sync
 *   - scheduledSync — hourly/daily task for YouTube sync
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule }         = require("firebase-functions/v2/scheduler");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { google }              = require("googleapis");

const db        = getFirestore();
const MEDIA_COL = "media";

const VALID_TYPES = ["video", "quran", "ruqyah"];

// ─────────────────────────────────────────────────────────────────────────────
// getMedia
// ─────────────────────────────────────────────────────────────────────────────
const getMedia = onCall({ region: "us-central1" }, async (request) => {
  try {
    const { type, category, limit: rawLimit = 50 } = request.data || {};
    const limit = Math.min(Math.max(parseInt(rawLimit, 10) || 50, 1), 100);

    if (type && !VALID_TYPES.includes(type)) {
      throw new HttpsError("invalid-argument", `Invalid type "${type}".`);
    }

    let query = db.collection(MEDIA_COL);
    if (type) query = query.where("type", "==", type);
    if (category) query = query.where("category", "==", category);

    if (type && category) {
      query = query.orderBy("title", "asc");
    } else if (type) {
      query = query.orderBy("category", "asc").orderBy("title", "asc");
    }

    const snap = await query.limit(limit).get();
    const media = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    return { media, count: media.length };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    console.error("[getMedia] Error:", err);
    throw new HttpsError("internal", "Failed to fetch media.");
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// syncYouTubeVideos
// ─────────────────────────────────────────────────────────────────────────────

const youtube = google.youtube("v3");
const API_KEY = process.env.YOUTUBE_API_KEY;

/**
 * Performs a global sync of YouTube videos based on sources defined in Firestore.
 */
async function performSync() {
  if (!API_KEY) {
    console.error("YOUTUBE_API_KEY not set.");
    return { success: false, error: "API Key missing" };
  }

  try {
    // 1. Fetch sync configuration from Firestore
    const configSnap = await db.collection("config").doc("youtube_sources").get();
    if (!configSnap.exists) {
      console.warn("No 'youtube_sources' config found in 'config' collection.");
      return { success: false, error: "Missing sync configuration" };
    }

    const { sources } = configSnap.data();
    if (!sources || !Array.isArray(sources)) {
      console.warn("Sources configuration is missing or invalid.");
      return { success: false, error: "Invalid sources list" };
    }

    const results = [];

    // 2. Loop through each defined source (Channel/Playlist)
    for (const source of sources) {
      try {
        const { id, type = "video", category = "General" } = source;
        if (!id) continue;

        const resp = await youtube.playlistItems.list({
          key: API_KEY,
          part: "snippet,contentDetails",
          playlistId: id,
          maxResults: 50,
        });

        const items = resp.data.items || [];
        const batch = db.batch();

        for (const item of items) {
          const vId = item.contentDetails.videoId;
          const snip = item.snippet;
          const ref = db.collection(MEDIA_COL).doc(`yt_${vId}`);

          batch.set(ref, {
            title: snip.title,
            description: snip.description,
            thumbnail: snip.thumbnails?.high?.url || snip.thumbnails?.default?.url,
            youtubeId: vId,
            type: type,
            category: category,
            source: "youtube",
            syncDate: FieldValue.serverTimestamp(),
            publishedAt: snip.publishedAt,
          }, { merge: true });
        }
        await batch.commit();
        results.push({ id, count: items.length, category });
      } catch (e) {
        console.error(`Sync failed for source ${source.id}:`, e.message);
      }
    }

    return { success: true, results };
  } catch (err) {
    console.error("Global sync failed:", err);
    return { success: false, error: err.message };
  }
}

const triggerSync = onCall({ region: "us-central1" }, async (request) => {
  return await performSync();
});

const scheduledSync = onSchedule("0 3 * * *", async (event) => {
  await performSync();
});

module.exports = { getMedia, triggerSync, scheduledSync };
