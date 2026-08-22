"use client";
import { useEffect, useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { collection, query, where, orderBy, getDocs } from "firebase/firestore";
import { updateProfile } from "firebase/auth";
import { useAuth } from "@/context/AuthContext";
import { db, auth } from "@/lib/firebase";

interface Order {
  id: string;
  trackingCode: string;
  status: string;
  total: number;
  createdAt: { toDate: () => Date } | null;
  items: { name: string; quantity: number }[];
}

function AccountPageInner() {
  const { user, loading, logOut } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const tab = searchParams.get("tab") || "profile";

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
        where("customer.email", "==", user.email),
        orderBy("createdAt", "desc")
      );
      getDocs(q)
        .then((snap) => setOrders(snap.docs.map((d) => ({ id: d.id, ...d.data() } as Order))))
        .catch(console.error)
        .finally(() => setOrdersLoading(false));
    }
  }, [user, tab]);

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
        {["profile", "orders"].map((t) => (
          <Link
            key={t}
            href={`/account${t === "orders" ? "?tab=orders" : ""}`}
            className={`px-5 py-2.5 text-xs font-bold uppercase tracking-widest transition-colors border-b-2 -mb-px ${
              tab === t
                ? "border-primary-container text-primary-container"
                : "border-transparent text-text-secondary hover:text-text-primary"
            }`}
          >
            {t === "profile" ? "Profile" : "My Orders"}
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
              className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-sm text-text-primary focus:border-primary-container focus:outline-none"
            />
          </div>

          <div className="space-y-1">
            <label className="text-xs text-text-secondary uppercase tracking-wider">Email Address</label>
            <input
              type="email"
              value={user.email || ""}
              disabled
              className="w-full bg-[#0a0a0a] border border-border-subtle rounded px-3 py-2.5 text-sm text-text-secondary cursor-not-allowed"
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
        </div>
      )}

      {/* Orders Tab */}
      {tab === "orders" && (
        <div className="space-y-4">
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
                    <p className="font-mono font-bold text-primary-container text-sm">{order.trackingCode}</p>
                    <p className="text-[10px] text-text-secondary mt-0.5">
                      {order.createdAt?.toDate
                        ? order.createdAt.toDate().toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" })
                        : "—"}
                    </p>
                  </div>
                  <span className={`text-[10px] font-bold uppercase tracking-wider px-2.5 py-1 rounded-full ${
                    order.status === "paid" || order.status === "delivered"
                      ? "bg-emerald-500/10 text-emerald-400"
                      : order.status === "failed"
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
                  <span className="text-sm font-bold text-primary-container">৳{order.total?.toLocaleString()}</span>
                </div>
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
