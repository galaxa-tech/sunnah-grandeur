"use strict";

const { getFirestore } = require("firebase-admin/firestore");

// Single Firestore instance shared across all domains.
const db = getFirestore();

const COL = {
  USERS:    "users",
  PRODUCTS: "products",
  ORDERS:   "orders",
  MEDIA:    "media",
  HADITHS:  "hadiths",
  SETTINGS: "settings",
  MASJIDS:  "masjids",
  CONFIG:   "config",
};

module.exports = { db, COL };
