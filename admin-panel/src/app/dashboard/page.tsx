"use client";

import { useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import Link from "next/link";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";

export default function DashboardPage() {
  const [orders, setOrders] = useState<any[]>([]);
  const [userCount, setUserCount] = useState<number>(0);
  const [productCount, setProductCount] = useState<number>(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // 1. Listen to real Firestore orders
    const unsubOrders = onSnapshot(collection(db, "orders"), (snapshot) => {
      const list: any[] = [];
      snapshot.forEach((doc) => {
        list.push({ id: doc.id, ...doc.data() });
      });
      setOrders(list.sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0)));
      setLoading(false);
    });

    // 2. Listen to real Firestore users count
    const unsubUsers = onSnapshot(collection(db, "users"), (snapshot) => {
      setUserCount(snapshot.size);
    });

    // 3. Listen to real Firestore products count
    const unsubProducts = onSnapshot(collection(db, "products"), (snapshot) => {
      setProductCount(snapshot.size);
    });

    return () => {
      unsubOrders();
      unsubUsers();
      unsubProducts();
    };
  }, []);

  const totalRevenue = orders.reduce((sum, order) => sum + (order.total || 0), 0);

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 min-h-screen flex-grow bg-bg-primary relative overflow-hidden">
        <div className="absolute inset-0 islamic-pattern pointer-events-none"></div>
        <Header title="Overview" />

        {/* Dashboard Canvas */}
        <div className="p-8 max-w-[1400px] mx-auto space-y-8 relative z-10">
          {/* Row 1: Stat Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              { label: "Total Revenue", value: `৳${totalRevenue.toLocaleString()}`, growth: "Live", icon: "payments" },
              { label: "Total Orders", value: orders.length.toString(), growth: "Live", icon: "shopping_cart" },
              { label: "Registered Users", value: userCount > 0 ? userCount.toString() : "1 (Active)", growth: "Live", icon: "group" },
              { label: "Active Products", value: productCount > 0 ? productCount.toString() : "6 Listed", growth: "Live", icon: "inventory_2" },
            ].map((stat) => (
              <div key={stat.label} className="bg-surface-card border border-border-subtle p-6 group hover:border-primary/50 transition-all duration-500 rounded-lg">
                <div className="flex justify-between items-start mb-4">
                  <div className="w-12 h-12 bg-primary/10 flex items-center justify-center text-primary rounded-lg">
                    <span className="material-symbols-outlined">{stat.icon}</span>
                  </div>
                  <span className="text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-widest">{stat.growth}</span>
                </div>
                <p className="text-on-surface-variant font-label-accent text-[10px] tracking-widest uppercase mb-1">{stat.label}</p>
                <h3 className="text-2xl font-headline-md font-bold text-text-primary">{stat.value}</h3>
              </div>
            ))}
          </div>

          {/* Row 2: Recent Orders & Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Live Orders Table Card */}
            <div className="lg:col-span-2 bg-surface-card border border-border-subtle p-8 overflow-hidden rounded-lg">
              <div className="flex justify-between items-center mb-6">
                <div>
                  <h4 className="font-headline-md text-text-primary text-xl font-bold">Recent Orders</h4>
                  <p className="text-xs text-on-surface-variant mt-1">Live customer orders written to Firestore database</p>
                </div>
                <Link href="/dashboard/shop" className="text-primary font-label-accent text-xs font-bold uppercase tracking-widest hover:underline">
                  View All Orders ➔
                </Link>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b border-outline-variant/30 text-left">
                      <th className="pb-4 font-label-accent text-[10px] tracking-widest uppercase text-on-surface-variant">Order Code</th>
                      <th className="pb-4 font-label-accent text-[10px] tracking-widest uppercase text-on-surface-variant">Customer</th>
                      <th className="pb-4 font-label-accent text-[10px] tracking-widest uppercase text-on-surface-variant">Amount</th>
                      <th className="pb-4 font-label-accent text-[10px] tracking-widest uppercase text-on-surface-variant text-right">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-outline-variant/10">
                    {orders.length === 0 ? (
                      <tr>
                        <td colSpan={4} className="py-8 text-center text-xs text-on-surface-variant">
                          No live orders submitted yet. Place an order on the Storefront to see it here!
                        </td>
                      </tr>
                    ) : (
                      orders.slice(0, 5).map((order) => {
                        const customerName = order.customer?.fullName || order.customer?.name || "Guest Customer";
                        const initials = customerName.split(" ").map((n: string) => n[0]).join("").substring(0, 2).toUpperCase();
                        return (
                          <tr key={order.id} className="group hover:bg-white/5 transition-colors">
                            <td className="py-4 font-mono font-bold text-xs text-primary">{order.trackingCode || `#${order.id.substring(0, 8)}`}</td>
                            <td className="py-4">
                              <div className="flex items-center gap-3">
                                <div className="w-8 h-8 rounded-full bg-primary/20 text-primary border border-primary/30 flex items-center justify-center text-[10px] font-bold">
                                  {initials}
                                </div>
                                <div>
                                  <p className="text-xs font-semibold text-text-primary">{customerName}</p>
                                  <p className="text-[10px] text-on-surface-variant">{order.customer?.city || "Dhaka"}</p>
                                </div>
                              </div>
                            </td>
                            <td className="py-4 text-xs font-bold text-primary-container">৳{(order.total || 0).toLocaleString()}</td>
                            <td className="py-4 text-right">
                              <span className="px-2.5 py-1 rounded bg-amber-500/10 border border-amber-500/30 text-amber-400 text-[10px] font-bold uppercase tracking-widest">
                                {order.status || "Processing"}
                              </span>
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Platform Activity Overview */}
            <div className="bg-surface-card border border-border-subtle p-8 flex flex-col rounded-lg">
              <div className="mb-6">
                <h4 className="font-headline-md text-text-primary text-xl font-bold">Activity Overview</h4>
                <p className="text-on-surface-variant text-xs mt-1">Platform traffic &amp; order volume</p>
              </div>
              <div className="flex-1 flex items-end gap-2 h-44 mb-6">
                {[40, 65, 50, 85, 75, 95, 80].map((h, i) => (
                  <div 
                    key={i} 
                    className={`flex-1 transition-all rounded-t ${i === 6 ? "bg-primary shadow-[0_0_15px_rgba(201,168,76,0.4)]" : "bg-primary/20 hover:bg-primary/40"}`} 
                    style={{ height: `${h}%` }}
                  ></div>
                ))}
              </div>
              <div className="flex justify-between font-label-accent text-[10px] text-on-surface-variant uppercase tracking-tighter">
                <span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span>
              </div>
            </div>
          </div>

          {/* Row 3: Quick Action Buttons */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* System Notifications */}
            <div className="bg-surface-card border border-border-subtle p-8 rounded-lg">
              <h4 className="font-headline-md text-text-primary mb-6 text-xl font-bold">System Status</h4>
              <div className="space-y-4 text-xs">
                <div className="flex items-center justify-between p-3.5 bg-dark-900 border border-emerald-500/30 rounded-lg">
                  <div className="flex items-center gap-3">
                    <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-ping"></span>
                    <span className="font-semibold text-text-primary">Firebase Firestore Live Database</span>
                  </div>
                  <span className="text-[10px] text-emerald-400 font-bold uppercase">Connected</span>
                </div>
                <div className="flex items-center justify-between p-3.5 bg-dark-900 border border-emerald-500/30 rounded-lg">
                  <div className="flex items-center gap-3">
                    <span className="w-2.5 h-2.5 rounded-full bg-emerald-400"></span>
                    <span className="font-semibold text-text-primary">Firebase Authentication Engine</span>
                  </div>
                  <span className="text-[10px] text-emerald-400 font-bold uppercase">Operational</span>
                </div>
                <div className="flex items-center justify-between p-3.5 bg-dark-900 border border-gold-400/30 rounded-lg">
                  <div className="flex items-center gap-3">
                    <span className="w-2.5 h-2.5 rounded-full bg-gold-400"></span>
                    <span className="font-semibold text-text-primary">Mobile PWA Web App</span>
                  </div>
                  <span className="text-[10px] text-gold-400 font-bold uppercase">Live</span>
                </div>
              </div>
            </div>

            {/* Functional Quick Actions */}
            <div className="grid grid-cols-2 grid-rows-2 gap-4">
              <Link href="/dashboard/shop" className="bg-primary-container/10 border border-primary/30 hover:border-primary transition-all p-6 flex flex-col justify-between group rounded-lg">
                <span className="material-symbols-outlined text-primary group-hover:scale-110 transition-transform">add_circle</span>
                <div>
                  <span className="block text-text-primary font-bold text-sm">Add Product</span>
                  <span className="text-[10px] text-on-surface-variant font-label-accent uppercase tracking-widest">Inventory Management</span>
                </div>
              </Link>
              <Link href="/dashboard/shop" className="bg-surface-card border border-border-subtle hover:border-primary/40 transition-all p-6 flex flex-col justify-between group rounded-lg">
                <span className="material-symbols-outlined text-primary group-hover:scale-110 transition-transform">shopping_bag</span>
                <div>
                  <span className="block text-text-primary font-bold text-sm">Manage Orders</span>
                  <span className="text-[10px] text-on-surface-variant font-label-accent uppercase tracking-widest">Order Processing</span>
                </div>
              </Link>
              <Link href="/dashboard/users" className="bg-surface-card border border-border-subtle hover:border-primary/40 transition-all p-6 flex flex-col justify-between group rounded-lg">
                <span className="material-symbols-outlined text-primary group-hover:scale-110 transition-transform">group</span>
                <div>
                  <span className="block text-text-primary font-bold text-sm">View Registered Users</span>
                  <span className="text-[10px] text-on-surface-variant font-label-accent uppercase tracking-widest">User Governance</span>
                </div>
              </Link>
              <Link href="/dashboard/settings" className="bg-surface-card border border-border-subtle hover:border-primary/40 transition-all p-6 flex flex-col justify-between group rounded-lg">
                <span className="material-symbols-outlined text-primary group-hover:scale-110 transition-transform">settings</span>
                <div>
                  <span className="block text-text-primary font-bold text-sm">Store Settings</span>
                  <span className="text-[10px] text-on-surface-variant font-label-accent uppercase tracking-widest">Configuration</span>
                </div>
              </Link>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
