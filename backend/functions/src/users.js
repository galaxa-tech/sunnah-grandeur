/**
 * users.js
 * --------
 * Cloud Functions for secure User Profile management.
 * Enforces "Backend as Single Source of Truth" for user metadata.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore }        = require("firebase-admin/firestore");

const db = getFirestore();
const USERS_COL = "users";

/**
 * createUserMetadata
 * Initializes the Firestore document for a newly registered user.
 */
const createUserMetadata = onCall({ region: "us-central1" }, async (request) => {
  const { name, email, phone } = request.data || {};
  const { auth } = request;

  if (!auth) {
    throw new HttpsError("unauthenticated", "Must be logged in to create metadata.");
  }

  if (!name || !email) {
    throw new HttpsError("invalid-argument", "Name and email are required.");
  }

  const userRef = db.collection(USERS_COL).doc(auth.uid);
  
  // Prevent overwriting existing data
  const existing = await userRef.get();
  if (existing.exists) {
    return { success: true, message: "Metadata already exists." };
  }

  const userData = {
    name,
    email,
    phone: phone || "",
    role: "user",
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  await userRef.set(userData);
  return { success: true };
});

/**
 * updateUserProfile
 * Securely updates specific allowed fields in the user's profile.
 */
const updateUserProfile = onCall({ region: "us-central1" }, async (request) => {
  const { name, email, phone } = request.data || {};
  const { auth } = request;

  if (!auth) {
    throw new HttpsError("unauthenticated", "Must be logged in to update profile.");
  }

  const userRef = db.collection(USERS_COL).doc(auth.uid);
  
  // Define strictly allowed fields to prevent arbitrary key injection
  const updates = {};
  if (name !== undefined) updates.name = name;
  if (email !== undefined) updates.email = email;
  if (phone !== undefined) updates.phone = phone;
  
  updates.updatedAt = new Date();

  if (Object.keys(updates).length <= 1) { // 1 because of updatedAt
    throw new HttpsError("invalid-argument", "No valid fields to update.");
  }

  await userRef.update(updates);
  return { success: true };
});

module.exports = { createUserMetadata, updateUserProfile };
