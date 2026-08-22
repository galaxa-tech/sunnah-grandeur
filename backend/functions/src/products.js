/**
 * products.js
 * -----------
 * Cloud Functions for the Products system.
 *
 * Exported callable functions:
 *   - getProducts      — paginated product listing with optional category/badge filter
 *   - getProductById   — fetch a single product by its Firestore document ID
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const db = getFirestore();
const PRODUCTS_COL = "products";
const DEFAULT_PAGE_SIZE = 12;
const MAX_PAGE_SIZE = 50;

// ─────────────────────────────────────────────────────────────────────────────
// getProducts
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Returns a paginated list of products.
 *
 * Request data:
 *   {
 *     limit?    : number   (default 12, max 50)
 *     page?     : number   (1-based page number, default 1)
 *     category? : string   (filter by category)
 *     badge?    : string   (filter by badge: "sale" | "new" | etc.)
 *   }
 *
 * Response:
 *   {
 *     products : Product[]
 *     total    : number     (total matching docs for pagination UI)
 *     page     : number
 *     limit    : number
 *     hasMore  : boolean
 *   }
 */
const getProducts = onCall({ region: "us-central1" }, async (request) => {
  try {
    const {
      limit: rawLimit = DEFAULT_PAGE_SIZE,
      page: rawPage = 1,
      category,
      badge,
    } = request.data || {};

    const limit = Math.min(Math.max(parseInt(rawLimit, 10) || DEFAULT_PAGE_SIZE, 1), MAX_PAGE_SIZE);
    const page  = Math.max(parseInt(rawPage, 10) || 1, 1);
    const offset = (page - 1) * limit;

    // Build base query
    let query = db.collection(PRODUCTS_COL).orderBy("createdAt", "desc");

    if (category && typeof category === "string") {
      query = query.where("category", "==", category.trim());
    }
    if (badge && typeof badge === "string") {
      query = query.where("badge", "==", badge.trim());
    }

    // Fetch total count (lightweight — only IDs)
    const countSnap = await query.select().get();
    const total = countSnap.size;

    // Fetch the actual page
    const snap = await query.offset(offset).limit(limit).get();

    const products = snap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() ?? null,
    }));

    return {
      products,
      total,
      page,
      limit,
      hasMore: offset + products.length < total,
    };
  } catch (err) {
    console.error("[getProducts] Error:", err);
    throw new HttpsError("internal", "Failed to fetch products. Please try again.");
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// getProductById
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Returns a single product document.
 *
 * Request data:
 *   { productId: string }
 *
 * Response:
 *   Product object or throws not-found error.
 */
const getProductById = onCall({ region: "us-central1" }, async (request) => {
  try {
    const { productId } = request.data || {};

    if (!productId || typeof productId !== "string") {
      throw new HttpsError("invalid-argument", "productId is required and must be a string.");
    }

    const doc = await db.collection(PRODUCTS_COL).doc(productId.trim()).get();

    if (!doc.exists) {
      throw new HttpsError("not-found", `Product with id "${productId}" does not exist.`);
    }

    const data = doc.data();
    return {
      id: doc.id,
      ...data,
      createdAt: data.createdAt?.toDate?.()?.toISOString() ?? null,
    };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    console.error("[getProductById] Error:", err);
    throw new HttpsError("internal", "Failed to fetch product. Please try again.");
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────────────────────────────────────
module.exports = { getProducts, getProductById };
