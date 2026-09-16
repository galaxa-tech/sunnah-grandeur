"use strict";

// Proxies Google Places API (Legacy) nearby/text search for mosques.
//
// WHY THIS EXISTS: the Places Web Service (maps.googleapis.com/maps/api/place/*)
// does not send CORS headers, so a browser calling it directly gets blocked
// by the browser's own CORS policy — this only ever worked on native
// Android/iOS builds (no CORS there). Since the mobile app is deployed as a
// web app, these functions do the HTTP call server-side (where CORS doesn't
// apply) and hand the JSON back to the browser with our own CORS headers.
// This also keeps GOOGLE_PLACES_API_KEY out of the client bundle entirely.

const { onRequest } = require("firebase-functions/v2/https");

const ALLOWED_ORIGINS = [
  "https://sunnah-grandeur-app.web.app",
  "https://sunnah-grandeur.web.app",
  "https://sunnah-grandeur-admin.web.app",
  /^http:\/\/localhost(:\d+)?$/,
];

const PLACES_BASE = "https://maps.googleapis.com/maps/api/place";

async function proxyPlaces(res, path, params) {
  const apiKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!apiKey) {
    res.status(500).json({ status: "ERROR", error_message: "GOOGLE_PLACES_API_KEY not configured." });
    return;
  }
  const qs = new URLSearchParams({ ...params, key: apiKey });
  const upstream = await fetch(`${PLACES_BASE}/${path}?${qs.toString()}`);
  const body = await upstream.json();
  res.status(upstream.status).json(body);
}

const masjidNearby = onRequest(
  { region: "us-central1", cors: ALLOWED_ORIGINS },
  async (req, res) => {
    const { lat, lng, radius } = req.query;
    if (!lat || !lng) {
      res.status(400).json({ status: "ERROR", error_message: "lat and lng are required." });
      return;
    }
    try {
      await proxyPlaces(res, "nearbysearch/json", {
        location: `${lat},${lng}`,
        radius: radius || "5000",
        type: "mosque",
      });
    } catch (err) {
      res.status(502).json({ status: "ERROR", error_message: String(err) });
    }
  }
);

const masjidSearch = onRequest(
  { region: "us-central1", cors: ALLOWED_ORIGINS },
  async (req, res) => {
    const { query, lat, lng } = req.query;
    if (!query || !lat || !lng) {
      res.status(400).json({ status: "ERROR", error_message: "query, lat and lng are required." });
      return;
    }
    try {
      await proxyPlaces(res, "textsearch/json", {
        query: `mosque ${query}`,
        location: `${lat},${lng}`,
        radius: "20000",
      });
    } catch (err) {
      res.status(502).json({ status: "ERROR", error_message: String(err) });
    }
  }
);

module.exports = { masjidNearby, masjidSearch };
