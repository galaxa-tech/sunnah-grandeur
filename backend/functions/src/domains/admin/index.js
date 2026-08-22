"use strict";

const { onCall, HttpsError }   = require("firebase-functions/v2/https");
const { FieldValue }           = require("firebase-admin/firestore");
const { getAuth }              = require("firebase-admin/auth");
const { requireAdmin, requireSuperAdmin, ROLES } = require("../../middleware/auth");
const { db, COL }              = require("../../lib/db");

// ── setUserRole ───────────────────────────────────────────────────────────────
// Assigns a role to any user.
// - superAdmin can assign any role (superAdmin, admin, employee, user).
// - admin can only assign 'employee' or 'user' — cannot create admins.
//
// Bootstrap the first superAdmin via the migration script:
//   node scripts/set-admin.js <email>

const setUserRole = onCall({ region: "us-central1" }, async (request) => {
  const callerRole = request.auth?.token?.role;

  // Must be at least an admin
  requireAdmin(request);

  const { targetUid, role } = request.data || {};

  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError("invalid-argument", "'targetUid' is required.");
  }

  const validRoles = Object.values(ROLES);
  if (!validRoles.includes(role)) {
    throw new HttpsError(
      "invalid-argument",
      `'role' must be one of: ${validRoles.join(", ")}.`,
    );
  }

  // Admins (non-super) cannot promote to admin or superAdmin
  if (callerRole === ROLES.ADMIN && [ROLES.SUPER_ADMIN, ROLES.ADMIN].includes(role)) {
    throw new HttpsError(
      "permission-denied",
      "Only a super-admin can grant admin or super-admin roles.",
    );
  }

  // Nobody can demote or change a superAdmin except another superAdmin
  const targetRecord = await getAuth().getUser(targetUid);
  const targetCurrentRole = targetRecord.customClaims?.role;
  if (targetCurrentRole === ROLES.SUPER_ADMIN && callerRole !== ROLES.SUPER_ADMIN) {
    throw new HttpsError("permission-denied", "Cannot modify a super-admin account.");
  }

  await getAuth().setCustomUserClaims(targetUid, { role });

  await db.collection(COL.USERS).doc(targetUid).update({
    role,
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { success: true, targetUid, role };
});

// Keep legacy name exported as alias for backward compatibility
const setAdminRole = setUserRole;

// ── getDashboardStats ─────────────────────────────────────────────────────────

const getDashboardStats = onCall({ region: "us-central1" }, async (request) => {
  requireAdmin(request);

  const [usersSnap, productsSnap, ordersSnap, paidOrdersSnap] = await Promise.all([
    db.collection(COL.USERS).select().get(),
    db.collection(COL.PRODUCTS).where("isActive", "==", true).select().get(),
    db.collection(COL.ORDERS).select().get(),
    db.collection(COL.ORDERS).where("status", "==", "paid").select().get(),
  ]);

  return {
    totalUsers:     usersSnap.size,
    activeProducts: productsSnap.size,
    totalOrders:    ordersSnap.size,
    paidOrders:     paidOrdersSnap.size,
  };
});

module.exports = { setAdminRole, setUserRole, getDashboardStats };
