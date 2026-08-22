"use strict";

const { onCall }               = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth }              = require("firebase-admin/auth");
const { requireAuth }          = require("../../middleware/auth");
const { validate }             = require("../../middleware/validate");
const { db, COL }              = require("../../lib/db");

// ── Schemas ───────────────────────────────────────────────────────────────────

const createSchema = {
  name:  { required: true,  type: "string", min: 1, max: 100 },
  email: { required: true,  type: "string", min: 3, max: 254 },
  phone: { required: false, type: "string", max: 20 },
};

const updateSchema = {
  name:  { required: false, type: "string", min: 1, max: 100 },
  phone: { required: false, type: "string", max: 20 },
};

// ── createUserMetadata ────────────────────────────────────────────────────────
// Called immediately after Firebase Auth registration.
// Sets role: 'user' server-side — client can never set this field.

const createUserMetadata = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireAuth(request);
  validate(request.data, createSchema);

  const { name, email, phone = "" } = request.data;

  const userRef = db.collection(COL.USERS).doc(uid);
  const existing = await userRef.get();

  // Idempotent — safe to call multiple times
  if (existing.exists) {
    return { success: true };
  }

  await userRef.set({
    uid,
    name,
    email,
    phone,
    role:                  "user",  // ALWAYS set server-side
    language:              "en",
    prayerMethod:          "mwl",
    notificationsEnabled:  true,
    createdAt:             FieldValue.serverTimestamp(),
    updatedAt:             FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// ── updateUserProfile ─────────────────────────────────────────────────────────
// Whitelist-only update — role, uid, email cannot be changed here.

const updateUserProfile = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireAuth(request);
  validate(request.data, updateSchema);

  const { name, phone } = request.data;
  const updates = { updatedAt: FieldValue.serverTimestamp() };

  if (name  !== undefined) updates.name  = name;
  if (phone !== undefined) updates.phone = phone;

  if (Object.keys(updates).length === 1) {
    // Only updatedAt — nothing to do
    return { success: true };
  }

  await db.collection(COL.USERS).doc(uid).update(updates);
  return { success: true };
});

// ── deleteAccount ─────────────────────────────────────────────────────────────
// Deletes Firestore profile + Firebase Auth account server-side.
// Client must never write directly to /users/{uid}.

const deleteAccount = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireAuth(request);

  // Delete Firestore document first
  await db.collection(COL.USERS).doc(uid).delete();

  // Then revoke auth (order matters — if auth delete fails, Firestore is already gone
  // but the user can no longer sign in because their data is removed)
  await getAuth().deleteUser(uid);

  return { success: true };
});

module.exports = { createUserMetadata, updateUserProfile, deleteAccount };
