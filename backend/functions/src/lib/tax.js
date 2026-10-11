"use strict";

const { getStripe, CURRENCY } = require("./stripe");

// Sales tax by destination ZIP/state via Stripe Tax. Returns the effective rate
// in parts-per-million (so it can be applied to the authoritative subtotal
// inside the order transaction), or null if Stripe Tax is unavailable (no
// registrations configured yet, key missing, API error) — callers then fall
// back to the flat settings/app_config.taxRateBps.
async function stripeTaxRatePpm(subtotalInCents, shipping) {
  if (!process.env.STRIPE_SECRET_KEY || subtotalInCents <= 0) return null;
  try {
    const calc = await getStripe().tax.calculations.create({
      currency: CURRENCY,
      line_items: [{ amount: subtotalInCents, reference: "order", tax_behavior: "exclusive" }],
      customer_details: {
        address: {
          line1:       shipping.line1,
          city:        shipping.city,
          state:       shipping.state,
          postal_code: shipping.postalCode,
          country:     "US",
        },
        address_source: "shipping",
      },
    });
    return Math.round((calc.tax_amount_exclusive / subtotalInCents) * 1_000_000);
  } catch (err) {
    console.warn("[tax] Stripe Tax unavailable, using flat rate:", err.message);
    return null;
  }
}

module.exports = { stripeTaxRatePpm };
