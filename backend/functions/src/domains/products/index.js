"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { db, COL }            = require("../../lib/db");

const DEFAULT_PAGE_SIZE = 12;
const MAX_PAGE_SIZE     = 48;

// createProduct/updateProduct were removed here — the admin panel writes
// products directly to Firestore via the client SDK (see
// backend/firestore.rules, "Admin panel writes products directly via client
// SDK"), which is the real, live path. These two callables were deployed but
// had zero callers on either the admin panel or mobile app; keeping unused,
// deployed write-path functions around just adds audit surface for no benefit.

// ── getProducts ───────────────────────────────────────────────────────────────
// Public. Direct Firestore read is equally valid for the client;
// this function exists for server-side pagination with count metadata.

const getProducts = onCall({ region: "us-central1" }, async (request) => {
  const {
    limit:    rawLimit    = DEFAULT_PAGE_SIZE,
    page:     rawPage     = 1,
    category,
    badge,
    activeOnly = true,
  } = request.data || {};

  const limit  = Math.min(Math.max(Number(rawLimit)  || DEFAULT_PAGE_SIZE, 1), MAX_PAGE_SIZE);
  const page   = Math.max(Number(rawPage) || 1, 1);
  const offset = (page - 1) * limit;

  let query = db.collection(COL.PRODUCTS).orderBy("createdAt", "desc");

  if (activeOnly) query = query.where("isActive", "==", true);
  if (category)   query = query.where("category", "==", String(category).trim());
  if (badge)      query = query.where("badge",    "==", String(badge).trim());

  const [countSnap, pageSnap] = await Promise.all([
    query.select().get(),
    query.offset(offset).limit(limit).get(),
  ]);

  return {
    products: pageSnap.docs.map(_toProduct),
    total:    countSnap.size,
    page,
    limit,
    hasMore:  offset + pageSnap.size < countSnap.size,
  };
});

// ── getProductById ────────────────────────────────────────────────────────────

const getProductById = onCall({ region: "us-central1" }, async (request) => {
  const { productId } = request.data || {};
  if (!productId || typeof productId !== "string") {
    throw new HttpsError("invalid-argument", "'productId' is required.");
  }

  const doc = await db.collection(COL.PRODUCTS).doc(productId.trim()).get();
  if (!doc.exists) {
    throw new HttpsError("not-found", `Product '${productId}' does not exist.`);
  }

  return _toProduct(doc);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function _toProduct(doc) {
  const d = doc.data();
  return {
    id:           doc.id,
    name:         d.name,
    description:  d.description,
    priceInCents: d.priceInCents,
    category:     d.category,
    sku:          d.sku,
    stockQuantity:d.stockQuantity,
    images:       d.images       ?? [],
    isActive:     d.isActive     ?? true,
    badge:        d.badge        ?? null,
    fragrance:    d.fragrance    ?? null,
    volumeMl:     d.volumeMl     ?? null,
    createdAt:    d.createdAt?.toDate?.()?.toISOString() ?? null,
  };
}

module.exports = { getProducts, getProductById };
