"use strict";

const { HttpsError } = require("firebase-functions/v2/https");

const US_STATES = new Set([
  "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA",
  "KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
  "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT",
  "VA","WA","WV","WI","WY","DC",
]);

// First-3-digit ZIP prefix ranges per state (USPS). Catches obvious mismatches
// such as a NY state with a 90210 ZIP, without needing a paid address API.
const ZIP_RANGES = {
  AL: [[350, 369]], AK: [[995, 999]], AZ: [[850, 865]], AR: [[716, 729], [755, 755]],
  CA: [[900, 961]], CO: [[800, 816]], CT: [[60, 69]], DE: [[197, 199]],
  DC: [[200, 205], [569, 569]], FL: [[320, 349]], GA: [[300, 319], [398, 399]],
  HI: [[967, 968]], ID: [[832, 838]], IL: [[600, 629]], IN: [[460, 479]],
  IA: [[500, 528]], KS: [[660, 679]], KY: [[400, 427]], LA: [[700, 714]],
  ME: [[39, 49]], MD: [[206, 219]], MA: [[10, 27], [55, 55]], MI: [[480, 499]],
  MN: [[550, 567]], MS: [[386, 397]], MO: [[630, 658]], MT: [[590, 599]],
  NE: [[680, 693]], NV: [[889, 898]], NH: [[30, 38]], NJ: [[70, 89]],
  NM: [[870, 884]], NY: [[5, 5], [100, 149]], NC: [[270, 289]], ND: [[580, 588]],
  OH: [[430, 459]], OK: [[730, 749]], OR: [[970, 979]], PA: [[150, 196]],
  RI: [[28, 29]], SC: [[290, 299]], SD: [[570, 577]], TN: [[370, 385]],
  TX: [[750, 799], [885, 885]], UT: [[840, 847]], VT: [[50, 59]],
  VA: [[201, 201], [220, 246]], WA: [[980, 994]], WV: [[247, 268]],
  WI: [[530, 549]], WY: [[820, 831]],
};

const ZIP_RE   = /^\d{5}(-\d{4})?$/;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

// Returns the phone as +1XXXXXXXXXX, or null if it is not a valid US number.
function normalizeUsPhone(raw) {
  const digits = String(raw || "").replace(/\D/g, "");
  const ten = digits.length === 11 && digits.startsWith("1") ? digits.slice(1) : digits;
  if (ten.length !== 10) return null;
  // NANP: area code and exchange cannot start with 0 or 1.
  if (!/^[2-9]\d{2}[2-9]\d{6}$/.test(ten)) return null;
  return `+1${ten}`;
}

function zipMatchesState(zip, state) {
  const prefix = parseInt(zip.slice(0, 3), 10);
  const ranges = ZIP_RANGES[state];
  if (!ranges) return true;
  return ranges.some(([lo, hi]) => prefix >= lo && prefix <= hi);
}

// Throws a customer-friendly HttpsError; returns cleaned shipping fields.
function validateUsShipping(s) {
  const fail = (msg) => { throw new HttpsError("invalid-argument", msg); };

  if (String(s.country || "").toUpperCase() !== "US") {
    fail("Sorry, we currently deliver within the United States only. Please enter a US address.");
  }

  const phone = normalizeUsPhone(s.phone);
  if (!phone) fail("Please enter a valid US phone number (10 digits, e.g. (212) 555-0100). We only deliver within the United States.");

  const email = String(s.email || "").trim();
  if (!EMAIL_RE.test(email)) fail("Please enter a valid email address — your order confirmation is sent there.");

  const state = String(s.state || "").trim().toUpperCase();
  if (!US_STATES.has(state)) fail("Please choose a valid US state.");

  const postalCode = String(s.postalCode || "").trim();
  if (!ZIP_RE.test(postalCode)) fail("Please enter a valid 5-digit US ZIP code.");
  if (!zipMatchesState(postalCode, state)) fail(`ZIP code ${postalCode} does not match the state ${state}. Please check your address.`);

  const line1 = String(s.line1 || "").trim();
  if (line1.length < 5 || !/\d/.test(line1) || !/[A-Za-z]/.test(line1)) {
    fail("Please enter a complete street address including the street number.");
  }

  const city = String(s.city || "").trim();
  if (city.length < 2 || !/[A-Za-z]/.test(city)) fail("Please enter a valid city.");

  const name = String(s.name || "").trim();
  if (name.length < 2) fail("Please enter your full name.");

  return { name, phone, email, line1, city, state, postalCode, country: "US" };
}

module.exports = { validateUsShipping, normalizeUsPhone };
