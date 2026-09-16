// Substitutes the %GOOGLE_MAPS_API_KEY% placeholder in build/web/index.html
// with the real key from api_keys.json (gitignored, never committed).
// Run this AFTER `flutter build web` and BEFORE deploying build/web.
"use strict";
const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const keysPath = path.join(root, "api_keys.json");
const indexPath = path.join(root, "build", "web", "index.html");

if (!fs.existsSync(keysPath)) {
  console.error("api_keys.json not found — copy api_keys.template.json and fill in your keys.");
  process.exit(1);
}
if (!fs.existsSync(indexPath)) {
  console.error("build/web/index.html not found — run `flutter build web` first.");
  process.exit(1);
}

const keys = JSON.parse(fs.readFileSync(keysPath, "utf8"));
const mapsKey = keys.PLACES_API_KEY;
if (!mapsKey) {
  console.error("PLACES_API_KEY missing from api_keys.json.");
  process.exit(1);
}

let html = fs.readFileSync(indexPath, "utf8");
html = html.replaceAll("%GOOGLE_MAPS_API_KEY%", mapsKey);
fs.writeFileSync(indexPath, html);
console.log("Injected Maps API key into build/web/index.html");
