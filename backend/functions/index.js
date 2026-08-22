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
 *    createProduct         updateProduct         (admin only)
 *    createOrder           getOrdersByUser
 *    createPaymentIntent   verifyPayment
 *    getMedia              triggerSync            (admin only)
 *    getHadiths
 *    setAdminRole          getDashboardStats      (admin only)
 *
 *  HTTPS (raw):
 *    stripeWebhook
 *
 *  Scheduled:
 *    scheduledSync  — daily 03:00 UTC
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
const { getProducts, getProductById, createProduct, updateProduct } =
  require("./src/domains/products");
exports.getProducts    = getProducts;
exports.getProductById = getProductById;
exports.createProduct  = createProduct;
exports.updateProduct  = updateProduct;

// ── Orders ────────────────────────────────────────────────────────────────────
const { createOrder, getOrdersByUser } =
  require("./src/domains/orders");
exports.createOrder     = createOrder;
exports.getOrdersByUser = getOrdersByUser;

// ── Payments ──────────────────────────────────────────────────────────────────
const { createPaymentIntent, verifyPayment } =
  require("./src/domains/payments");
exports.createPaymentIntent = createPaymentIntent;
exports.verifyPayment       = verifyPayment;

// ── Stripe Webhook ────────────────────────────────────────────────────────────
const { stripeWebhook } = require("./src/domains/payments/webhook");
exports.stripeWebhook = stripeWebhook;

// ── Media ─────────────────────────────────────────────────────────────────────
const { getMedia }                      = require("./src/domains/media");
const { triggerSync, scheduledSync }    = require("./src/domains/media/sync");
exports.getMedia       = getMedia;
exports.triggerSync    = triggerSync;
exports.scheduledSync  = scheduledSync;

// ── Hadiths ───────────────────────────────────────────────────────────────────
const { getHadiths } = require("./src/domains/hadiths");
exports.getHadiths = getHadiths;

// ── Admin ─────────────────────────────────────────────────────────────────────
const { setAdminRole, setUserRole, getDashboardStats } = require("./src/domains/admin");
exports.setAdminRole      = setAdminRole;
exports.setUserRole       = setUserRole;
exports.getDashboardStats = getDashboardStats;
