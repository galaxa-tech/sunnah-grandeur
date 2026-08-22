"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { FieldValue }         = require("firebase-admin/firestore");
const { requireAdmin }       = require("../../middleware/auth");
const { validate }           = require("../../middleware/validate");
const { db, COL }            = require("../../lib/db");

const DEFAULT_PAGE_SIZE = 12;
const MAX_PAGE_SIZE     = 48;

// ── Schemas ───────────────────────────────────────────────────────────────────

const createProductSchema = {
  name:             { required: true,  type: "string", min: 1, max: 200 },
  description:      { required: true,  type: "string", min: 1 },
  priceInCents:     { required: true,  type: "number", integer: true, positive: true },
  category:         { required: true,  type: "string" },
  sku:              { required: true,  type: "string", min: 1, max: 50 },
  stockQuantity:    { required: true,  type: "number", integer: true, min: 0 },
  images:           { required: true,  type: "array",  min: 1 },
  isActive:         { required: false, type: "boolean" },
  badge:            { required: false, type: "string", enum: ["new", "sale", "bestseller"] },
  fragrance:        { required: false, type: "string" },
  volumeMl:         { required: false, type: "number", positive: true },
};

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

// ── createProduct (admin) ─────────────────────────────────────────────────────

const createProduct = onCall({ region: "us-central1" }, async (request) => {
  requireAdmin(request);
  validate(request.data, createProductSchema);

  const {
    name, description, priceInCents, category, sku,
    stockQuantity, images, isActive = true, badge = null,
    fragrance = null, volumeMl = null,
  } = request.data;

  const ref = db.collection(COL.PRODUCTS).doc();
  await ref.set({
    name, description, priceInCents, category, sku,
    stockQuantity, images, isActive, badge, fragrance, volumeMl,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { productId: ref.id };
});

// ── updateProduct (admin) ─────────────────────────────────────────────────────

const updateProduct = onCall({ region: "us-central1" }, async (request) => {
  requireAdmin(request);

  const { productId, ...fields } = request.data || {};
  if (!productId) throw new HttpsError("invalid-argument", "'productId' is required.");

  // Whitelist updatable fields
  const ALLOWED = [
    "name", "description", "priceInCents", "category", "sku",
    "stockQuantity", "images", "isActive", "badge", "fragrance", "volumeMl",
  ];
  const updates = { updatedAt: FieldValue.serverTimestamp() };
  for (const key of ALLOWED) {
    if (fields[key] !== undefined) updates[key] = fields[key];
  }

  await db.collection(COL.PRODUCTS).doc(productId).update(updates);
  return { success: true };
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

module.exports = { getProducts, getProductById, createProduct, updateProduct };
