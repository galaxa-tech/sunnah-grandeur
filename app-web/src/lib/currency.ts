// Mirrors admin-panel/src/lib/currency.ts. The rate lives in Firestore
// (`settings/app_config.usdToLocalRate`) so app-web, app-mobile, admin-panel,
// and backend/functions all read the SAME value at runtime instead of each
// hardcoding their own copy — previously all four independently hardcoded
// `1/118`, which only stayed correct by coincidence. Callers should pass the
// live rate from useCurrency(); DEFAULT_BDT_TO_USD_RATE is only the fallback
// used before that doc loads / if it's ever missing a value.
export const DEFAULT_BDT_TO_USD_RATE = 1 / 118;

export function toDisplayUsd(bdtAmount: number, rate: number = DEFAULT_BDT_TO_USD_RATE): number {
  return bdtAmount * rate;
}

export function formatUsd(bdtAmount: number, rate: number = DEFAULT_BDT_TO_USD_RATE): string {
  const usd = toDisplayUsd(bdtAmount, rate);
  return `$${usd.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

export function formatUsdFromCents(cents: number): string {
  return `$${(cents / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

// For a value that's already a real USD amount (e.g. a flat shipping fee),
// as opposed to a BDT-denominated catalog price that needs converting.
export function formatUsdRaw(usdAmount: number): string {
  return `$${usdAmount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}
