#!/usr/bin/env node
/**
 * Bootstrap Super Admin
 * ---------------------
 * Sets the 'superAdmin' custom claim on a Firebase Auth user by email.
 * Run ONCE to create the first super admin account.
 *
 * Usage (run from /backend/functions directory):
 *   node ../scripts/bootstrap-super-admin.js <email>
 *
 * Example:
 *   node ../scripts/bootstrap-super-admin.js sunnahgrandeur.nyc@gmail.com
 *
 * Requirements:
 *   - Must be run from the /backend/functions directory.
 *   - Run `firebase login` first if not already authenticated.
 */

"use strict";

require("dotenv").config();

const { initializeApp, getApps } = require("firebase-admin/app");
const { getAuth }                 = require("firebase-admin/auth");
const { getFirestore, FieldValue }= require("firebase-admin/firestore");

// ── Validate args ─────────────────────────────────────────────────────────────
const email = process.argv[2];
if (!email || !email.includes("@")) {
  console.error("Usage (from /backend/functions): node ../scripts/bootstrap-super-admin.js <email>");
  process.exit(1);
}

// ── Init Admin SDK (uses Application Default Credentials from firebase login) ─
if (!getApps().length) {
  initializeApp();
}

const auth = getAuth();
const db   = getFirestore();

async function run() {
  console.log(`\n🔍 Looking up user: ${email} ...`);

  let user;
  try {
    user = await auth.getUserByEmail(email);
  } catch (err) {
    if (err.code === "auth/user-not-found") {
      console.error(`\n❌ No Firebase Auth user found for: ${email}`);
      console.error("   → The user must sign in to the app at least once before being promoted.");
      console.error("   → Create an account with this email on the website, then re-run this script.");
      process.exit(1);
    }
    throw err;
  }

  const uid = user.uid;
  console.log(`✅ Found user: ${uid}`);

  await auth.setCustomUserClaims(uid, { role: "superAdmin" });
  console.log(`✅ Custom claim set: role = 'superAdmin'`);

  await db.collection("users").doc(uid).set({
    uid,
    email,
    name:      user.displayName || "Super Admin",
    role:      "superAdmin",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`✅ Firestore /users/${uid} updated with role: 'superAdmin'`);
  console.log(`\n🎉 Done! ${email} is now the Super Admin.`);
  console.log(`   → The user must sign out and sign back in for the new role to take effect.\n`);
}

run().catch((err) => {
  console.error("\n❌ Unexpected error:", err.message);
  process.exit(1);
});
