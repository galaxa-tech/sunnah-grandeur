/**
 * orders.js
 * ---------
 * Cloud Functions for the Orders system.
 *
 * Exported callable functions:
 *   - createOrder      — validates items/stock, creates an order doc
 *   - getOrdersByUser  — returns a user's order history
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const db = getFirestore();
const PRODUCTS_COL = "products";
const ORDERS_COL   = "orders";
const USERS_COL    = "users";

// ─────────────────────────────────────────────────────────────────────────────
// createOrder
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Creates a new order document after validating stock availability.
 * The order starts in "pending" status; status is updated to "paid" via webhook.
 *
 * Request data:
 *   {
 *     userId : string
 *     items  : Array<{ productId: string, quantity: number }>
 *   }
 *
 * Response:
 *   {
 *     orderId    : string
 *     total      : number   (in smallest currency unit, e.g. cents)
 *     status     : "pending"
 *     createdAt  : string   (ISO timestamp)
 *   }
 */
const createOrder = onCall({ region: "us-central1" }, async (request) => {
  try {
    const { userId, items } = request.data || {};

    // ── Input validation ──────────────────────────────────────────────────────
    if (!userId || typeof userId !== "string") {
      throw new HttpsError("invalid-argument", "userId is required.");
    }
    if (!Array.isArray(items) || items.length === 0) {
      throw new HttpsError("invalid-argument", "items must be a non-empty array.");
    }
    for (const item of items) {
      if (!item.productId || typeof item.productId !== "string") {
        throw new HttpsError("invalid-argument", "Each item must have a valid productId.");
      }
      if (!Number.isInteger(item.quantity) || item.quantity < 1) {
        throw new HttpsError("invalid-argument", `quantity for ${item.productId} must be a positive integer.`);
      }
    }

    // ── Validate products and check stock (inside a transaction) ──────────────
    const orderRef = db.collection(ORDERS_COL).doc();

    const result = await db.runTransaction(async (t) => {
      const productRefs = items.map((item) =>
        db.collection(PRODUCTS_COL).doc(item.productId)
      );
      const productDocs = await t.getAll(...productRefs);

      let total = 0;
      const enrichedItems = [];

      for (let i = 0; i < items.length; i++) {
        const doc = productDocs[i];
        const item = items[i];

        if (!doc.exists) {
          throw new HttpsError("not-found", `Product "${item.productId}" does not exist.`);
        }

        const product = doc.data();

        if (product.stockQuantity < item.quantity) {
          throw new HttpsError(
            "resource-exhausted",
            `Insufficient stock for "${product.name}". Available: ${product.stockQuantity}, Requested: ${item.quantity}.`
          );
        }

        const lineTotal = product.price * item.quantity;
        total += lineTotal;

        enrichedItems.push({
          productId : item.productId,
          name      : product.name,
          quantity  : item.quantity,
          unitPrice : product.price,
          lineTotal,
        });

        // Decrement stock
        t.update(doc.ref, { stockQuantity: FieldValue.increment(-item.quantity) });
      }

      // Write the order document
      const orderData = {
        userId,
        items           : enrichedItems,
        total,
        status          : "pending",
        paymentIntentId : null,
        createdAt       : FieldValue.serverTimestamp(),
      };
      t.set(orderRef, orderData);

      // Update user's order references
      const userRef = db.collection(USERS_COL).doc(userId);
      t.set(userRef, { orderRefs: FieldValue.arrayUnion(orderRef.id) }, { merge: true });

      return { total };
    });

    return {
      orderId   : orderRef.id,
      total     : result.total,
      status    : "pending",
      createdAt : new Date().toISOString(),
    };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    console.error("[createOrder] Error:", err);
    throw new HttpsError("internal", "Failed to create order. Please try again.");
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// getOrdersByUser
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Returns all orders for a given user, sorted by most recent first.
 *
 * Request data:
 *   { userId: string }
 *
 * Response:
 *   { orders: Order[] }
 */
const getOrdersByUser = onCall({ region: "us-central1" }, async (request) => {
  try {
    const { userId } = request.data || {};

    if (!userId || typeof userId !== "string") {
      throw new HttpsError("invalid-argument", "userId is required.");
    }

    // Optional: enforce caller == userId for security
    if (request.auth && request.auth.uid !== userId) {
      throw new HttpsError("permission-denied", "You can only access your own orders.");
    }

    const snap = await db
      .collection(ORDERS_COL)
      .where("userId", "==", userId)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get();

    const orders = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id        : doc.id,
        ...data,
        createdAt : data.createdAt?.toDate?.()?.toISOString() ?? null,
      };
    });

    return { orders };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    console.error("[getOrdersByUser] Error:", err);
    throw new HttpsError("internal", "Failed to fetch orders. Please try again.");
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────────────────────────────────────
module.exports = { createOrder, getOrdersByUser };
