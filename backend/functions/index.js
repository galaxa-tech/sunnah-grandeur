"use strict";

/**
 * Cloud Functions entry point — barrel exports only.
 * All logic lives in src/domains/. This file never contains business logic.
 *
 * Deployed functions:
 *
 *  Callable (authenticated):
 *    createUserMetadata    updateUserProfile     deleteAccount
 *    getProducts           getProductById
 *    createOrder           getOrdersByUser       updateOrderStatus (admin only)
 *    createPaymentIntent   verifyPayment
 *    getMedia
 *    getHadiths
 *    setAdminRole          getDashboardStats      (admin only)
 *
 *  HTTPS (raw):
 *    stripeWebhook
 *    masjidNearby          masjidSearch           (Places API proxy, public)
 *    metalPrices                                  (gold/silver spot proxy, public)
 *
 * Media is admin-curated only (see app-mobile/lib/providers/media_provider.dart)
 * — no YouTube auto-sync function exists by design; do not reintroduce one.
 */

require("dotenv").config();

const { initializeApp } = require("firebase-admin/app");
initializeApp();

// ── Users ─────────────────────────────────────────────────────────────────────
const { createUserMetadata, updateUserProfile, deleteAccount } =
  require("./src/domains/users");
exports.createUserMetadata = createUserMetadata;
exports.updateUserProfile  = updateUserProfile;
exports.deleteAccount      = deleteAccount;

// ── Products ──────────────────────────────────────────────────────────────────
const { getProducts, getProductById } = require("./src/domains/products");
exports.getProducts    = getProducts;
exports.getProductById = getProductById;

// ── Orders ────────────────────────────────────────────────────────────────────
const { createOrder, getOrdersByUser, updateOrderStatus } =
  require("./src/domains/orders");
exports.createOrder       = createOrder;
exports.getOrdersByUser   = getOrdersByUser;
exports.updateOrderStatus = updateOrderStatus;

// ── Payments ──────────────────────────────────────────────────────────────────
const { createPaymentIntent, verifyPayment } =
  require("./src/domains/payments");
exports.createPaymentIntent = createPaymentIntent;
exports.verifyPayment       = verifyPayment;

// ── Stripe Webhook ────────────────────────────────────────────────────────────
const { stripeWebhook } = require("./src/domains/payments/webhook");
exports.stripeWebhook = stripeWebhook;

// ── Media (admin-curated only — see index.js header comment) ──────────────────
const { getMedia } = require("./src/domains/media");
exports.getMedia = getMedia;

// ── Hadiths ───────────────────────────────────────────────────────────────────
const { getHadiths } = require("./src/domains/hadiths");
exports.getHadiths = getHadiths;

// ── Admin ─────────────────────────────────────────────────────────────────────
const { setAdminRole, setUserRole, getDashboardStats } = require("./src/domains/admin");
exports.setAdminRole      = setAdminRole;
exports.setUserRole       = setUserRole;
exports.getDashboardStats = getDashboardStats;

// ── Masjid Finder (Places API proxy — see src/domains/masjid/index.js) ────────
const { masjidNearby, masjidSearch } = require("./src/domains/masjid");
exports.masjidNearby = masjidNearby;
exports.masjidSearch = masjidSearch;

// ── Zakat (live metal-price proxy — see src/domains/zakat/index.js) ───────────
const { metalPrices } = require("./src/domains/zakat");
exports.metalPrices = metalPrices;
