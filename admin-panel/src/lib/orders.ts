// Shared order helpers for the dashboard and Shop & Orders pages.
// Statuses are set by backend/functions/src/domains/orders (ORDER_STATUSES):
// pending_payment | Processing | Shipped | Delivered | Cancelled.

export function isCancelledOrder(order: { status?: unknown }): boolean {
  return typeof order.status === "string" && order.status.trim().toLowerCase() === "cancelled";
}

/** Order total in cents — real orders store `totalInCents`; legacy docs used `total`/`amount` in dollars. */
export function orderTotalCents(order: any): number {
  if (typeof order.totalInCents === "number") return order.totalInCents;
  const dollars = Number(order.total ?? order.amount ?? 0);
  return Number.isFinite(dollars) ? Math.round(dollars * 100) : 0;
}

/** Tailwind classes for a status badge. */
export function orderStatusBadgeClass(status?: string): string {
  switch ((status || "").trim().toLowerCase()) {
    case "cancelled":       return "bg-red-500/10 border-red-500/30 text-red-400";
    case "delivered":       return "bg-emerald-500/10 border-emerald-500/30 text-emerald-400";
    case "shipped":         return "bg-sky-500/10 border-sky-500/30 text-sky-400";
    case "pending_payment": return "bg-zinc-500/10 border-zinc-500/30 text-zinc-400";
    default:                return "bg-amber-500/10 border-amber-500/30 text-amber-400";
  }
}
