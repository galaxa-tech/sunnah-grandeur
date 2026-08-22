"use strict";

const { HttpsError } = require("firebase-functions/v2/https");

/**
 * Role hierarchy (highest → lowest):
 *   superAdmin → admin → employee → user
 *
 * Custom claims are set server-side via Admin SDK and cannot be forged by clients.
 */

const ROLES = {
  SUPER_ADMIN: "superAdmin",
  ADMIN:       "admin",
  EMPLOYEE:    "employee",
  USER:        "user",
};

// Roles that have any kind of admin panel access
const ADMIN_ROLES = [ROLES.SUPER_ADMIN, ROLES.ADMIN, ROLES.EMPLOYEE];

/**
 * Asserts the caller is authenticated.
 * Returns uid extracted from the verified Firebase ID token.
 * NEVER trust request.data.userId — always use this.
 */
function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in to perform this action.");
  }
  return request.auth.uid;
}

/**
 * Asserts the caller has any staff-level role (superAdmin, admin, or employee).
 * Use this for read-heavy admin panel operations.
 */
function requireStaff(request) {
  const uid = requireAuth(request);
  const role = request.auth.token.role;
  if (!ADMIN_ROLES.includes(role)) {
    throw new HttpsError("permission-denied", "Staff access required.");
  }
  return uid;
}

/**
 * Asserts the caller has 'admin' or 'superAdmin' claim.
 * Use this for write operations (create/update/delete products, manage orders).
 */
function requireAdmin(request) {
  const uid = requireAuth(request);
  const role = request.auth.token.role;
  if (![ROLES.SUPER_ADMIN, ROLES.ADMIN].includes(role)) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }
  return uid;
}

/**
 * Asserts the caller has the 'superAdmin' claim.
 * Use this for role management and destructive operations.
 */
function requireSuperAdmin(request) {
  const uid = requireAuth(request);
  if (request.auth.token.role !== ROLES.SUPER_ADMIN) {
    throw new HttpsError("permission-denied", "Super-admin access required.");
  }
  return uid;
}

module.exports = { requireAuth, requireStaff, requireAdmin, requireSuperAdmin, ROLES };
