import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import Stripe from "stripe";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const stripeSecretKey = process.env.STRIPE_SECRET_KEY || "sk_test_placeholder";
const stripe = new Stripe(stripeSecretKey, {
  apiVersion: "2024-06-20" as any,
});

interface OrderItemInput {
  productId?: string;
  id?: string;
  name: string;
  price: number;
  quantity: number;
}

export const createStripeSession = onRequest(
  { cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed. Use POST." });
      return;
    }

    try {
      const { userId, items, successUrl, cancelUrl } = req.body;

      if (!userId || !items || !Array.isArray(items) || items.length === 0) {
        res.status(400).json({
          error: "Missing required parameters: userId and a non-empty items array.",
        });
        return;
      }

      const defaultSuccess = successUrl || "https://sunnah-grandeur.web.app/checkout/success";
      const defaultCancel = cancelUrl || "https://sunnah-grandeur.web.app/checkout";

      let totalInCents = 0;
      const lineItems: Stripe.Checkout.SessionCreateParams.LineItem[] = items.map(
        (item: OrderItemInput) => {
          const itemPriceInCents = Math.round(item.price);
          totalInCents += itemPriceInCents * item.quantity;

          return {
            price_data: {
              currency: "usd",
              product_data: {
                name: item.name || "Sunnah Grandeur Product",
                metadata: {
                  productId: item.productId || item.id || "prod_unknown",
                },
              },
              unit_amount: itemPriceInCents,
            },
            quantity: item.quantity,
          };
        }
      );

      const formattedItems = items.map((item: OrderItemInput) => ({
        productId: item.productId || item.id || "prod_unknown",
        name: item.name,
        price: Math.round(item.price),
        quantity: item.quantity,
      }));

      const session = await stripe.checkout.sessions.create({
        payment_method_types: ["card"],
        line_items: lineItems,
        mode: "payment",
        success_url: `${defaultSuccess}?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: defaultCancel,
        client_reference_id: userId,
        metadata: {
          userId: userId,
          items: JSON.stringify(formattedItems),
          total: totalInCents.toString(),
        },
      });

      res.status(200).json({
        id: session.id,
        url: session.url,
      });
    } catch (error: any) {
      console.error("Error creating Stripe session:", error);
      res.status(500).json({
        error: error.message || "Failed to create Stripe Checkout session.",
      });
    }
  }
);

export const stripeWebhook = onRequest(
  { rawBody: true },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const sig = req.headers["stripe-signature"];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event: Stripe.Event;

    try {
      if (webhookSecret && sig) {
        const rawBody = (req as any).rawBody || req.body;
        event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
      } else {
        event = req.body;
      }
    } catch (err: any) {
      console.error("Webhook signature verification failed:", err.message);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    if (event.type === "checkout.session.completed") {
      const session = event.data.object as Stripe.Checkout.Session;

      try {
        const userId = session.client_reference_id || session.metadata?.userId || "guest_user";
        const itemsRaw = session.metadata?.items ? JSON.parse(session.metadata.items) : [];
        const total = session.amount_total || (session.metadata?.total ? parseInt(session.metadata.total) : 0);

        const orderData = {
          userId: userId,
          items: itemsRaw.map((item: any) => ({
            productId: item.productId || item.id || "prod_unknown",
            price: item.price,
            quantity: item.quantity,
            name: item.name || "Product",
          })),
          total: total,
          status: "paid",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          stripeSessionId: session.id,
          paymentIntentId: session.payment_intent || null,
        };

        await db.collection("orders").add(orderData);
        console.log(`Successfully created paid order for session ${session.id}`);
      } catch (err: any) {
        console.error("Error writing order to Firestore:", err);
        res.status(500).send("Error writing order to database");
        return;
      }
    }

    res.status(200).json({ received: true });
  }
);
