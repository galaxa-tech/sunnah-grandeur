"use client";
import { useEffect, useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { collection, query, where, orderBy, getDocs, getDoc, doc } from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { updateProfile } from "firebase/auth";
import { useAuth } from "@/context/AuthContext";
import { db, auth, functions } from "@/lib/firebase";
import { useWishlist } from "@/lib/wishlist";
import { products as staticProducts } from "@/data/products";
import { formatUsdFromCents } from "@/lib/currency";

// Mirrors the real shape written by backend/functions/src/domains/orders —
// there is no `customer.email` or `total` field on an actual order document.
interface Order {
  id: string;
  status: string;
  totalInCents: number;
  createdAt: { toDate: () => Date } | null;
  items: { name: string; quantity: number }[];
}

function AccountPageInner() {
  const { user, loading, logOut } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const tab = searchParams.get("tab") || "profile";

  const [cancelling, setCancelling] = useState<string | null>(null);
  const [orderMsg, setOrderMsg] = useState("");
  const wishlist = useWishlist();
  const [saved, setSaved] = useState<any[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [ordersLoading, setOrdersLoading] = useState(false);
  const [displayName, setDisplayName] = useState("");
  const [saving, setSaving] = useState(false);
  const [saveMsg, setSaveMsg] = useState("");

  useEffect(() => {
    if (!loading && !user) router.push("/");
  }, [user, loading, router]);

  useEffect(() => {
    if (user) setDisplayName(user.displayName || "");
  }, [user]);

  useEffect(() => {
    if (user && tab === "orders") {
      setOrdersLoading(true);
      const q = query(
        collection(db, "orders"),
        where("userId", "==", user.uid),
        orderBy("createdAt", "desc")
      );
      getDocs(q)
        .then((snap) => setOrders(snap.docs.map((d) => ({ id: d.id, ...d.data() } as Order))))
        .catch(console.error)
        .finally(() => setOrdersLoading(false));
    }
  }, [user, tab]);

  // Resolve saved product ids to displayable products (Firestore first, static catalog fallback).
  const savedKey = Array.from(wishlist.ids).sort().join(",");
  useEffect(() => {
    if (tab !== "wishlist") return;
    let live = true;
    Promise.all(Array.from(wishlist.ids).map(async (id) => {
      try {
        const s = await getDoc(doc(db, "products", id));
        if (s.exists()) {
          const d: any = s.data();
          return { id, name: d.name, price: d.price, image: d.image || d.images?.[0] || d.imageUrl };
        }
      } catch { /* fall through */ }
      const p: any = staticProducts.find((x) => String(x.id) === id);
      return p ? { id, name: p.name, price: p.price, image: p.image } : null;
    })).then((r) => { if (live) setSaved(r.filter(Boolean) as any[]); });
    return () => { live = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab, savedKey]);

  const handleCancel = async (orderId: string) => {
    if (!window.confirm("Cancel this order? If you already paid, your payment will be refunded to the original payment method.")) return;
    setCancelling(orderId);
    setOrderMsg("");
    try {
      const res: any = await httpsCallable(functions, "cancelOrder")({ orderId });
      setOrders((prev) => prev.map((o) => (o.id === orderId ? { ...o, status: "Cancelled" } : o)));
      setOrderMsg(res.data?.refund === "refunded"
        ? "Order cancelled. Your refund is on its way (5–10 business days)."
        : res.data?.refund === "manual"
        ? "Order cancelled. Our team will process your refund shortly."
        : "Order cancelled.");
    } catch (e: any) {
      setOrderMsg((e?.message || "Could not cancel this order.").replace(/^.*?:\s*/, ""));
    } finally {
      setCancelling(null);
    }
  };

  const handleSaveName = async () => {
    if (!auth.currentUser || !displayName.trim()) return;
    setSaving(true);
    try {
      await updateProfile(auth.currentUser, { displayName: displayName.trim() });
      setSaveMsg("Profile updated!");
      setTimeout(() => setSaveMsg(""), 3000);
    } catch {
      setSaveMsg("Failed to update.");
    } finally {
      setSaving(false);
    }
  };

  if (loading || !user) {
    return (
      <div className="pt-40 text-center">
        <div className="w-8 h-8 border-2 border-primary-container border-t-transparent rounded-full animate-spin mx-auto" />
      </div>
    );
  }

  return (
    <div className="pt-32 pb-24 px-4 max-w-3xl mx-auto">
      <h1 className="text-3xl font-bold font-serif text-text-primary mb-2">My Account</h1>
      <p className="text-xs text-text-secondary mb-8">
        Signed in as <span className="text-primary-container font-semibold">{user.email}</span>
      </p>

      {/* Tabs */}
      <div className="flex gap-1 mb-8 border-b border-border-subtle">
        {["profile", "orders", "wishlist"].map((t) => (
          <Link
            key={t}
            href={`/account${t === "profile" ? "" : `?tab=${t}`}`}
            className={`px-5 py-2.5 text-xs font-bold uppercase tracking-widest transition-colors border-b-2 -mb-px ${
              tab === t
                ? "border-primary-container text-primary-container"
                : "border-transparent text-text-secondary hover:text-text-primary"
            }`}
          >
            {t === "profile" ? "Profile" : t === "orders" ? "My Orders" : "Wishlist"}
          </Link>
        ))}
      </div>

      {/* Profile Tab */}
      {tab === "profile" && (
        <div className="bg-surface-card border border-border-subtle rounded-xl p-6 space-y-5">
          <h2 className="text-sm font-bold text-text-primary uppercase tracking-wider">Personal Information</h2>

          <div className="space-y-1">
            <label className="text-xs text-text-secondary uppercase tracking-wider">Display Name</label>
            <input
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              placeholder="Your name"
              className="w-full bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-sm text-text-primary focus:border-primary-container focus:outline-none"
            />
          </div>

          <div className="space-y-1">
            <label className="text-xs text-text-secondary uppercase tracking-wider">Email Address</label>
            <input
              type="email"
              value={user.email || ""}
              disabled
              className="w-full bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-sm text-text-secondary cursor-not-allowed"
            />
            <p className="text-[10px] text-text-secondary">Email cannot be changed here.</p>
          </div>

          {saveMsg && (
            <p className="text-xs text-emerald-400">{saveMsg}</p>
          )}

          <div className="flex gap-3 pt-2">
            <button
              onClick={handleSaveName}
              disabled={saving}
              className="bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest px-6 py-2.5 rounded hover:bg-[#e6c364] transition-colors disabled:opacity-50"
            >
              {saving ? "Saving..." : "Save Changes"}
            </button>
            <button
              onClick={logOut}
              className="border border-border-subtle text-text-secondary font-bold text-xs uppercase tracking-widest px-6 py-2.5 rounded hover:border-red-500 hover:text-red-400 transition-colors"
            >
              Sign Out
            </button>
          </div>
          <p className="text-[11px] text-text-secondary pt-2">
            Want to leave?{" "}
            <Link href="/account-deletion" className="text-red-400 hover:underline">Delete your account and data</Link>
          </p>
        </div>
      )}

      {/* Wishlist Tab */}
      {tab === "wishlist" && (
        <div className="space-y-4">
          {saved.length === 0 ? (
            <div className="text-center py-16 space-y-3">
              <span className="material-symbols-outlined text-5xl text-text-secondary">favorite</span>
              <p className="text-sm text-text-secondary">No saved items yet. Use the ⋮ menu on any product and choose &ldquo;Save for later&rdquo;.</p>
              <Link href="/shop" className="inline-block bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest px-6 py-2.5 rounded hover:bg-[#e6c364] transition-colors">Browse Products</Link>
            </div>
          ) : (
            saved.map((p) => (
              <div key={p.id} className="bg-surface-card border border-border-subtle rounded-xl p-4 flex items-center gap-4">
                <div className="w-16 h-16 rounded bg-bg-primary border border-border-subtle overflow-hidden flex items-center justify-center flex-shrink-0">
                  {p.image ? <img src={p.image} alt={p.name} className="max-w-full max-h-full object-contain" /> : <span className="material-symbols-outlined text-text-secondary">image</span>}
                </div>
                <div className="flex-1 min-w-0">
                  <Link href={`/product/${p.id}`} className="font-bold text-sm text-text-primary hover:text-primary-container truncate block">{p.name}</Link>
                </div>
                <button onClick={() => wishlist.toggle(p.id)} className="text-[11px] text-text-secondary hover:text-red-400 uppercase font-bold tracking-widest">Remove</button>
              </div>
            ))
          )}
        </div>
      )}

      {/* Orders Tab */}
      {tab === "orders" && (
        <div className="space-y-4">
          {orderMsg && <p role="status" className="text-xs text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 rounded p-3">{orderMsg}</p>}
          {ordersLoading ? (
            <div className="text-center py-12">
              <div className="w-8 h-8 border-2 border-primary-container border-t-transparent rounded-full animate-spin mx-auto" />
            </div>
          ) : orders.length === 0 ? (
            <div className="text-center py-16 space-y-3">
              <span className="material-symbols-outlined text-5xl text-text-secondary">receipt_long</span>
              <p className="text-sm text-text-secondary">No orders yet.</p>
              <Link
                href="/shop"
                className="inline-block bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest px-6 py-2.5 rounded hover:bg-[#e6c364] transition-colors"
              >
                Start Shopping
              </Link>
            </div>
          ) : (
            orders.map((order) => (
              <div key={order.id} className="bg-surface-card border border-border-subtle rounded-xl p-5 space-y-3">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-mono font-bold text-primary-container text-sm">{order.id}</p>
                    <p className="text-[10px] text-text-secondary mt-0.5">
                      {order.createdAt?.toDate
                        ? order.createdAt.toDate().toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" })
                        : "—"}
                    </p>
                  </div>
                  <span className={`text-[10px] font-bold uppercase tracking-wider px-2.5 py-1 rounded-full ${
                    order.status === "Delivered" || order.status === "Shipped"
                      ? "bg-emerald-500/10 text-emerald-400"
                      : order.status === "Cancelled"
                      ? "bg-red-500/10 text-red-400"
                      : "bg-amber-500/10 text-amber-400"
                  }`}>
                    {order.status}
                  </span>
                </div>
                <div className="text-xs text-text-secondary">
                  {order.items?.slice(0, 2).map((item, i) => (
                    <span key={i}>{item.name} ×{item.quantity}{i < Math.min(order.items.length, 2) - 1 ? ", " : ""}</span>
                  ))}
                  {order.items?.length > 2 && <span> +{order.items.length - 2} more</span>}
                </div>
                <div className="flex justify-between items-center pt-1 border-t border-border-subtle">
                  <span className="text-xs text-text-secondary">Total</span>
                  <span className="text-sm font-bold text-primary-container">{formatUsdFromCents(order.totalInCents)}</span>
                </div>
                {(order.status === "Processing" || order.status === "pending_payment") && (
                  <div className="pt-2">
                    <button
                      onClick={() => handleCancel(order.id)}
                      disabled={cancelling === order.id}
                      className="text-[11px] font-bold uppercase tracking-widest border border-red-500/40 text-red-400 px-4 py-2 rounded hover:bg-red-500/10 transition-colors disabled:opacity-50"
                    >
                      {cancelling === order.id ? "Cancelling…" : "Cancel Order"}
                    </button>
                  </div>
                )}
                {order.status === "Shipped" && (
                  <p className="text-[11px] text-text-secondary">Already shipped — it can no longer be cancelled online. See our <Link href="/returns-and-exchanges" className="text-primary-container underline">Returns &amp; Refunds</Link> policy.</p>
                )}
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}

export default function AccountPage() {
  return (
    <Suspense fallback={
      <div className="pt-40 text-center">
        <div className="w-8 h-8 border-2 border-primary-container border-t-transparent rounded-full animate-spin mx-auto" />
      </div>
    }>
      <AccountPageInner />
    </Suspense>
  );
}
