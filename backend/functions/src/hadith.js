/**
 * hadith.js
 * ---------
 * Simple read-only fetch for traditional curated Hadith/Ayat content.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore }        = require("firebase-admin/firestore");

const db         = getFirestore();
const HADITH_COL = "hadith_posts";

// ─────────────────────────────────────────────────────────────────────────────
// getHadiths
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Returns a list of static hadith/ayat posts.
 *
 * Request data:
 *   {
 *     limit? : number (default 10, max 30)
 *   }
 */
const getHadiths = onCall({ region: "us-central1" }, async (request) => {
  try {
    const rawLimit = request.data?.limit;
    const limit = Math.min(Math.max(parseInt(rawLimit, 10) || 10, 1), 30);

    const snap = await db.collection(HADITH_COL)
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();

    const posts = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        title: data.title,
        content: data.content,
        source: data.source || null,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      };
    });

    return { posts };
  } catch (err) {
    console.error("[getHadiths] Error:", err);
    throw new HttpsError("internal", "Failed to fetch hadiths. Please try again.");
  }
});

module.exports = { getHadiths };
