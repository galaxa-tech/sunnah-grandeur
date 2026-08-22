"use client";

import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";

export default function DashboardPage() {
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
              { label: "Total Users", value: "12,842", growth: "+12% ↑", icon: "group" },
              { label: "Active Sessions", value: "1,204", growth: "+5% ↑", icon: "bolt" },
              { label: "Total Orders", value: "458", growth: "+24% ↑", icon: "shopping_cart" },
              { label: "Total Products", value: "84", growth: "Stable", icon: "inventory_2" },
            ].map((stat) => (
              <div key={stat.label} className="bg-surface-card border border-border-subtle p-6 group hover:border-primary/50 transition-all duration-500">
                <div className="flex justify-between items-start mb-4">
                  <div className="w-12 h-12 bg-primary/10 flex items-center justify-center text-primary">
                    <span className="material-symbols-outlined">{stat.icon}</span>
                  </div>
                  <span className={`${stat.growth.includes("↑") ? "text-status-delivered" : "text-on-surface-variant"} font-label-accent text-[10px]`}>{stat.growth}</span>
                </div>
                <p className="text-on-surface-variant font-label-accent text-[10px] tracking-widest uppercase mb-1">{stat.label}</p>
                <h3 className="text-3xl font-headline-md text-text-primary">{stat.value}</h3>
              </div>
            ))}
          </div>

          {/* Row 2: Recent Orders & Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Table Card */}
            <div className="lg:col-span-2 bg-surface-card border border-border-subtle p-8 overflow-hidden">
              <div className="flex justify-between items-center mb-8">
                <h4 className="font-headline-md text-text-primary text-xl">Recent Orders</h4>
                <button className="text-primary font-label-accent text-[10px] uppercase tracking-widest hover:underline">View All</button>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b border-outline-variant/30">
                      <th className="pb-4 font-label-accent text-[10px] tracking-widest uppercase text-on-surface-variant">Order ID</th>
                      <th className="pb-4 font-label-accent text-[10px] tracking-widest uppercase text-on-surface-variant">Customer</th>
                      <th className="pb-4 font-label-accent text-[10px] tracking-widest uppercase text-on-surface-variant">Amount</th>
                      <th className="pb-4 font-label-accent text-[10px] tracking-widest uppercase text-on-surface-variant text-right">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-outline-variant/10">
                    {[
                      { id: "#SG-9842", customer: "Ahmed Al-Sayed", initials: "AA", amount: "$284.00", status: "Confirmed", statusColor: "text-status-confirmed bg-status-confirmed/10" },
                      { id: "#SG-9841", customer: "Mariam Fatima", initials: "MF", amount: "$1,120.50", status: "Delivered", statusColor: "text-status-delivered bg-status-delivered/10" },
                      { id: "#SG-9840", customer: "Zaid Khan", initials: "ZK", amount: "$45.00", status: "Shipped", statusColor: "text-status-shipped bg-status-shipped/10" },
                    ].map((order) => (
                      <tr key={order.id} className="group hover:bg-white/5 transition-colors">
                        <td className="py-4 font-label-accent text-sm">{order.id}</td>
                        <td className="py-4">
                          <div className="flex items-center gap-3">
                            <div className="w-8 h-8 rounded-full bg-surface-container-high flex items-center justify-center text-[10px]">{order.initials}</div>
                            <span className="text-sm font-medium">{order.customer}</span>
                          </div>
                        </td>
                        <td className="py-4 text-sm">{order.amount}</td>
                        <td className="py-4 text-right">
                          <span className={`px-2 py-1 ${order.statusColor} text-[10px] font-bold uppercase tracking-widest`}>{order.status}</span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Usage Chart Card */}
            <div className="bg-surface-card border border-border-subtle p-8 flex flex-col">
              <div className="mb-8">
                <h4 className="font-headline-md text-text-primary text-xl">Usage Overview</h4>
                <p className="text-on-surface-variant text-[10px] mt-1">Platform activity this week</p>
              </div>
              <div className="flex-1 flex items-end gap-2 h-48 mb-6">
                {[40, 60, 45, 85, 70, 95, 75].map((h, i) => (
                  <div 
                    key={i} 
                    className={`flex-1 transition-all ${i === 6 ? "bg-primary" : "bg-primary/20 hover:bg-primary/40"}`} 
                    style={{ height: `${h}%` }}
                  ></div>
                ))}
              </div>
              <div className="flex justify-between font-label-accent text-[10px] text-on-surface-variant uppercase tracking-tighter">
                <span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span>
              </div>
            </div>
          </div>

          {/* Row 3: Notifications & Quick Actions */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Notifications */}
            <div className="bg-surface-card border border-border-subtle p-8">
              <h4 className="font-headline-md text-text-primary mb-6 text-xl">Recent Notifications</h4>
              <div className="space-y-6">
                {[
                  { title: "Stock alert: Oud Al-Khaleej", desc: "Only 5 units remaining in inventory.", time: "2 hours ago", color: "bg-primary" },
                  { title: "New Admin user registered", desc: "Sami Rahim joined the marketing team.", time: "5 hours ago", color: "bg-status-confirmed" },
                  { title: "Monthly sales report ready", desc: "The August 2023 financial statement is now available.", time: "Yesterday", color: "bg-outline", faded: true },
                ].map((n) => (
                  <div key={n.title} className={`flex gap-4 ${n.faded ? "opacity-60" : ""}`}>
                    <div className={`w-2 h-2 rounded-full ${n.color} mt-1.5 shrink-0`}></div>
                    <div>
                      <p className="text-sm font-medium text-text-primary">{n.title}</p>
                      <p className="text-xs text-on-surface-variant mt-1">{n.desc}</p>
                      <p className="text-[10px] font-label-accent text-outline mt-2 uppercase tracking-widest">{n.time}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Quick Actions Bento */}
            <div className="grid grid-cols-2 grid-rows-2 gap-4">
              <button className="bg-primary-container/10 border border-primary/20 hover:border-primary/60 transition-all p-6 flex flex-col justify-between group text-left">
                <span className="material-symbols-outlined text-primary group-hover:scale-110 transition-transform">add_circle</span>
                <div>
                  <span className="block text-text-primary font-medium text-sm">Add Product</span>
                  <span className="text-[10px] text-on-surface-variant font-label-accent uppercase tracking-widest">Inventory</span>
                </div>
              </button>
              <button className="bg-surface-card border border-border-subtle hover:border-primary/40 transition-all p-6 flex flex-col justify-between group text-left">
                <span className="material-symbols-outlined text-outline group-hover:text-primary transition-colors">send</span>
                <div>
                  <span className="block text-text-primary font-medium text-sm">Send Notification</span>
                  <span className="text-[10px] text-on-surface-variant font-label-accent uppercase tracking-widest">Broadcast</span>
                </div>
              </button>
              <button className="bg-surface-card border border-border-subtle hover:border-primary/40 transition-all p-6 flex flex-col justify-between group text-left">
                <span className="material-symbols-outlined text-outline group-hover:text-primary transition-colors">cloud_upload</span>
                <div>
                  <span className="block text-text-primary font-medium text-sm">Upload Media</span>
                  <span className="text-[10px] text-on-surface-variant font-label-accent uppercase tracking-widest">Gallery</span>
                </div>
              </button>
              <button className="bg-surface-card border border-border-subtle hover:border-primary/40 transition-all p-6 flex flex-col justify-between group text-left">
                <span className="material-symbols-outlined text-outline group-hover:text-primary transition-colors">campaign</span>
                <div>
                  <span className="block text-text-primary font-medium text-sm">Add Banner</span>
                  <span className="text-[10px] text-on-surface-variant font-label-accent uppercase tracking-widest">Promotion</span>
                </div>
              </button>
            </div>
          </div>
        </div>
        
        {/* Background Artwork */}
        <div className="absolute bottom-[-10%] right-[-5%] w-[600px] h-[600px] opacity-10 blur-3xl rounded-full bg-primary/20 pointer-events-none"></div>
      </main>
    </div>
  );
}
