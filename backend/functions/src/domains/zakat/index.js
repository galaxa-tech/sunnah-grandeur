"use strict";

// Proxies a free, no-key spot-price API for gold/silver so the mobile app's
// Zakat calculator can pre-fill today's price instead of a static default
// the user has to remember to update manually themselves.
//
// WHY A PROXY (same reasoning as src/domains/masjid): the mobile app also
// ships as a web build, and calling a third-party API straight from the
// browser is subject to that API's own CORS policy (or lack of one) — doing
// the fetch server-side sidesteps that and lets us hand back our own CORS
// headers. It also means we can swap the upstream provider later without
// touching the client.
//
// Upstream: https://api.gold-api.com — free, no API key. Best-effort only;
// if it's ever unreachable or the shape changes, this returns a clear error
// and the Flutter screen keeps its own hardcoded default rather than crash.

const { onRequest } = require("firebase-functions/v2/https");

const ALLOWED_ORIGINS = [
  "https://sunnah-grandeur-app.web.app",
  "https://sunnah-grandeur.web.app",
  "https://sunnah-grandeur-admin.web.app",
  /^http:\/\/localhost(:\d+)?$/,
];

const TROY_OUNCE_IN_GRAMS = 31.1034768;

async function fetchPricePerGram(symbol) {
  const upstream = await fetch(`https://api.gold-api.com/price/${symbol}`);
  if (!upstream.ok) {
    throw new Error(`Upstream returned ${upstream.status} for ${symbol}`);
  }
  const body = await upstream.json();
  const pricePerOunce = Number(body.price);
  if (!Number.isFinite(pricePerOunce) || pricePerOunce <= 0) {
    throw new Error(`Upstream returned an invalid price for ${symbol}: ${body.price}`);
  }
  return pricePerOunce / TROY_OUNCE_IN_GRAMS;
}

const metalPrices = onRequest(
  { region: "us-central1", cors: ALLOWED_ORIGINS },
  async (_req, res) => {
    try {
      const [goldPerGram, silverPerGram] = await Promise.all([
        fetchPricePerGram("XAU"),
        fetchPricePerGram("XAG"),
      ]);
      res.status(200).json({
        goldUsdPerGram: Number(goldPerGram.toFixed(2)),
        silverUsdPerGram: Number(silverPerGram.toFixed(2)),
        fetchedAt: new Date().toISOString(),
      });
    } catch (err) {
      res.status(502).json({ error: String(err.message || err) });
    }
  }
);

module.exports = { metalPrices };
