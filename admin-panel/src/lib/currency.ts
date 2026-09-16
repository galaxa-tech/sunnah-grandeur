// Mirrors app-web/src/lib/currency.ts. The admin panel is the ONE place
// prices are actually entered, so staff type and see a real USD figure here
// while the stored `price`/`priceInCents` fields keep their existing
// BDT-scale numbers (what the storefront/mobile/backend already convert
// from). usdToStored is the exact inverse of the display conversion.
//
// The rate itself lives in Firestore (`settings/app_config.usdToLocalRate`)
// so app-web, app-mobile, and backend/functions all read the SAME value at
// runtime instead of each hardcoding their own copy — previously all three
// independently hardcoded `1/118`, which only stayed correct by coincidence.
// DEFAULT_BDT_TO_USD_RATE is only the fallback used before that doc loads /
// if it's ever missing a value.
// TODO: once every stored product price is migrated to true USD, delete
// this file and the matching config field in app-web + app-mobile + backend.
export const DEFAULT_BDT_TO_USD_RATE = 1 / 118;

export function storedToUsd(stored: number, rate: number = DEFAULT_BDT_TO_USD_RATE): number {
  return stored * rate;
}

export function usdToStored(usd: number, rate: number = DEFAULT_BDT_TO_USD_RATE): number {
  return usd / rate;
}

export function formatUsd(stored: number, rate: number = DEFAULT_BDT_TO_USD_RATE): string {
  const usd = storedToUsd(stored, rate);
  return `$${usd.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}
