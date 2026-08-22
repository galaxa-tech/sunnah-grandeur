"use strict";

const Stripe = require("stripe");

let _client = null;

function getStripe() {
  if (_client) return _client;
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) throw new Error("STRIPE_SECRET_KEY environment variable is not set.");
  _client = new Stripe(key, { apiVersion: "2024-06-20" });
  return _client;
}

const CURRENCY = process.env.CURRENCY || "usd";

module.exports = { getStripe, CURRENCY };
