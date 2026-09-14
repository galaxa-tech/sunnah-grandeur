// Single source of truth for how a price is shown to a customer. The
// storefront's launch market is the USA (USD) — see the market strategy
// plan. Existing catalog prices were entered as plain BDT numbers by the
// admin panel; this converts them to a clean USD retail figure for display.
// TODO: once the owner sets real USD prices per product in the admin panel,
// drop BDT_TO_USD_RATE and just format the stored number directly.
const BDT_TO_USD_RATE = 1 / 118;

export function toDisplayUsd(bdtAmount: number): number {
  return bdtAmount * BDT_TO_USD_RATE;
}

export function formatUsd(bdtAmount: number): string {
  const usd = toDisplayUsd(bdtAmount);
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
