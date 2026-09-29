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
// Permanently erases everything tied to the caller's account (App Store 5.1.1(v)
// / Google Play account-deletion policy), then deletes the Auth user.
//   Deleted:     users/{uid} (+ tasbih_sessions), carts/{uid}, favorites/{uid},
//                the user's reviews and app feedback.
//   Anonymized:  orders — kept for tax/accounting, but name/phone/email/address
//                are scrubbed and userId is detached.
// The public account-deletion page (sunnahgrandeur.com/account-deletion)
// documents exactly this list — keep them in sync.

const ANONYMIZED_SHIPPING = {
  name: "Deleted User", phone: "", email: "", line1: "", city: "",
  state: "", postalCode: "",
};

async function deleteWhereUserId(collection, uid) {
  const snap = await db.collection(collection).where("userId", "==", uid).get();
  const writer = db.bulkWriter();
  snap.docs.forEach((d) => writer.delete(d.ref));
  await writer.close();
}

const deleteAccount = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireAuth(request);

  // Owner-keyed documents, including subcollections.
  await Promise.all([
    db.recursiveDelete(db.collection(COL.USERS).doc(uid)),
    db.recursiveDelete(db.collection("carts").doc(uid)),
    db.recursiveDelete(db.collection("favorites").doc(uid)),
    deleteWhereUserId("reviews", uid),
    deleteWhereUserId("app_feedback", uid),
  ]);

  // Orders: retain the financial record, strip the personal data.
  const orders = await db.collection(COL.ORDERS).where("userId", "==", uid).get();
  const writer = db.bulkWriter();
  orders.docs.forEach((d) => {
    const shipping = { ...(d.get("shipping") || {}), ...ANONYMIZED_SHIPPING };
    writer.update(d.ref, {
      userId:         null,
      shipping,
      accountDeleted: true,
      updatedAt:      FieldValue.serverTimestamp(),
    });
  });
  await writer.close();

  // Auth user last — if anything above throws, the user can still sign in
  // and retry instead of being left with orphaned data.
  await getAuth().deleteUser(uid);

  return { success: true };
});

module.exports = { createUserMetadata, updateUserProfile, deleteAccount };
