"use client";

import { useState } from "react";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";

export default function UserManagementPage() {
  const [selectedUser, setSelectedUser] = useState<any>(null);

  const users = [
    { id: 1, name: "Ahmed Mansour", email: "ahmed.m@example.com", joinDate: "Oct 12, 2023", lastActive: "2 hours ago", role: "CUSTOMER", status: "Active", statusColor: "text-status-delivered bg-status-delivered/10 border-status-delivered/20", dotColor: "bg-status-delivered", img: "https://lh3.googleusercontent.com/aida-public/AB6AXuCl2r0tlNT3lTkYkrVMdHPVCQA-qZmE02AXVsZ9tLYcip2sVX19WfEWWDpghNHpJONJnTuWfdmIpnsTXwWx5hFFA0peNRdWvs1DtruzbH7_nGFHIStBewxcL7rvkGgqa_1TrQDfTl7Z3E1JLAUjcjXVew9k6ymzU_mIuEiSJ2YDuJcM13Z5AdDyeLcqoDCbgQZFB1RR5p4Mg4OQlr9lds4SDIUzmnzvn9jlwSaZJ6rKztH920fwwK7j2eCgSS6NTEXN4ZWgdgzAfkL3" },
    { id: 2, name: "Sara Khan", email: "sara.k@domain.org", joinDate: "Nov 05, 2023", lastActive: "Yesterday", role: "PREMIUM", status: "Active", statusColor: "text-status-delivered bg-status-delivered/10 border-status-delivered/20", dotColor: "bg-status-delivered", img: "https://lh3.googleusercontent.com/aida-public/AB6AXuDuIMRIhesNYJqkgshww2POl7zi6P2yo7MYjm3P7ccFzWR9yMvAQkQqOwJHZkNk13uMLCYIZ-NkARTlvENnqKfm5upEBkHHIY60ZU4R_QZFpeJgmFeLdTFq09t177uQEc2WrrosiFqZV7d2xHXqq4zW6HJhHs0FJrYd0eIv_9dCcU2wZE4T3MRbNyKKBlhDmFT9SDnTPl3J90XDS8gQQYFDbFUrR8bdiDT38b19R8mNHl9NFmQ6RbCa-ZJlATJfJtQ4PhAdW02tE4fl" },
    { id: 3, name: "Omar Bakri", email: "bakri.o@webmail.com", joinDate: "Aug 22, 2023", lastActive: "3 weeks ago", role: "CUSTOMER", status: "Banned", statusColor: "text-status-cancelled bg-status-cancelled/10 border-status-cancelled/20", dotColor: "bg-status-cancelled", img: "https://lh3.googleusercontent.com/aida-public/AB6AXuDXfQSuboahTjXo7OBhPiVjv46wNg-iolmq56tjIniN7Pw7QAnOTQ4LJRTf9qNB1Cd9UNBvJOXwOuqSekdBBDGYcW6HjrBMUUKOdgtQ2Gd08x5oUXpk5IAaRS_k-ncYDbd0ZVg0iXKSx7Fli5rSE_aXM-aT9amWwYX59xUZQ2vRJfN5TYaH_4i2gOEXBt8NFqA7-enuIoeUa7wTScetxGVwWG407-W-JSgV0sMWbjrOQQj5JAEAMS2hWSx7bQuFGMlINlUl3qPM-PwY", isBanned: true },
  ];

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 min-h-screen flex-grow flex flex-col bg-bg-primary relative overflow-hidden">
        <Header title="User Management" />

        {/* Content Canvas */}
        <div className="p-8 max-w-[1400px] mx-auto w-full relative z-10">
          {/* Filters & Stats Section */}
          <div className="flex flex-col md:flex-row md:items-center justify-between mb-8 gap-4">
            <div className="flex items-center gap-3">
              <button className="bg-primary text-on-primary px-6 py-2 rounded-full font-label-accent text-[10px] tracking-widest">ALL USERS (1,248)</button>
              <button className="bg-surface-card border border-outline-variant text-on-surface-variant px-6 py-2 rounded-full font-label-accent text-[10px] tracking-widest hover:border-primary transition-colors">ACTIVE (1,102)</button>
              <button className="bg-surface-card border border-outline-variant text-on-surface-variant px-6 py-2 rounded-full font-label-accent text-[10px] tracking-widest hover:border-primary transition-colors">BANNED (146)</button>
            </div>
            <div className="flex items-center gap-4">
              <select className="bg-surface-card border border-outline-variant rounded px-4 py-2 text-xs font-label-accent focus:border-primary focus:ring-0 text-on-surface cursor-pointer">
                <option>Sort by: Newest First</option>
                <option>Sort by: Last Active</option>
                <option>Sort by: High Spenders</option>
              </select>
              <button className="flex items-center gap-2 border border-outline-variant px-4 py-2 rounded text-xs hover:bg-surface-container-high transition-colors">
                <span className="material-symbols-outlined text-sm">filter_list</span>
                More Filters
              </button>
            </div>
          </div>

          {/* Table Container */}
          <div className="bg-surface-card border border-border-subtle rounded-xl overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-outline-variant bg-surface-container-lowest">
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest">Avatar</th>
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest">Name</th>
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest">Join Date</th>
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest">Last Active</th>
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest">Role</th>
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest">Status</th>
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-outline-variant">
                  {users.map((user) => (
                    <tr 
                      key={user.id} 
                      onClick={() => setSelectedUser(user)}
                      className={`hover:bg-surface-container-low transition-colors group cursor-pointer ${user.isBanned ? "bg-error/5" : ""}`}
                    >
                      <td className="px-6 py-4">
                        <img className="w-10 h-10 rounded-full border border-outline-variant object-cover" src={user.img} alt={user.name} />
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex flex-col">
                          <span className="font-bold text-on-surface text-sm">{user.name}</span>
                          <span className="text-xs text-text-secondary">{user.email}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-xs text-on-surface-variant">{user.joinDate}</td>
                      <td className="px-6 py-4 text-xs text-on-surface-variant">{user.lastActive}</td>
                      <td className="px-6 py-4">
                        <span className={`text-[10px] font-label-accent border px-2 py-0.5 rounded ${user.role === "PREMIUM" ? "border-primary/40 text-primary" : "border-outline text-outline"}`}>
                          {user.role}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-bold ${user.statusColor} uppercase tracking-tighter`}>
                          <span className={`w-1.5 h-1.5 rounded-full ${user.dotColor}`}></span>
                          {user.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button className="p-2 hover:bg-secondary-container/20 hover:text-primary rounded transition-all">
                            <span className="material-symbols-outlined text-lg">visibility</span>
                          </button>
                          <button className={`p-2 rounded transition-all ${user.isBanned ? "bg-error text-on-error" : "hover:bg-error-container/20 hover:text-error"}`}>
                            <span className="material-symbols-outlined text-lg">{user.isBanned ? "undo" : "block"}</span>
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            {/* Pagination */}
            <div className="px-6 py-4 border-t border-outline-variant flex items-center justify-between bg-surface-container-lowest">
              <p className="text-[10px] text-on-surface-variant font-label-accent uppercase tracking-widest">SHOWING 1-3 OF 1,248 USERS</p>
              <div className="flex items-center gap-2">
                <button className="p-2 border border-outline-variant rounded hover:bg-surface-container-high text-on-surface-variant">
                  <span className="material-symbols-outlined text-sm">chevron_left</span>
                </button>
                <button className="w-8 h-8 flex items-center justify-center rounded bg-primary text-on-primary text-xs font-bold">1</button>
                <button className="w-8 h-8 flex items-center justify-center rounded border border-outline-variant hover:bg-surface-container-high text-xs text-on-surface-variant transition-colors">2</button>
                <button className="w-8 h-8 flex items-center justify-center rounded border border-outline-variant hover:bg-surface-container-high text-xs text-on-surface-variant transition-colors">3</button>
                <span className="text-on-surface-variant text-xs">...</span>
                <button className="p-2 border border-outline-variant rounded hover:bg-surface-container-high text-on-surface-variant">
                  <span className="material-symbols-outlined text-sm">chevron_right</span>
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Side Drawer (User Profile Details) */}
        {selectedUser && (
          <>
            <div 
              className="fixed inset-0 bg-black/40 backdrop-blur-sm z-40 transition-opacity" 
              onClick={() => setSelectedUser(null)}
            ></div>
            <div className="fixed top-0 right-0 h-full w-[400px] bg-surface-container-lowest z-50 border-l border-outline-variant shadow-2xl transition-transform duration-500 overflow-y-auto">
              <div className="p-8 h-full flex flex-col">
                <div className="flex items-center justify-between mb-8">
                  <h3 className="font-headline-md text-xl text-primary">User Profile</h3>
                  <button 
                    onClick={() => setSelectedUser(null)}
                    className="text-on-surface-variant hover:text-error transition-colors"
                  >
                    <span className="material-symbols-outlined">close</span>
                  </button>
                </div>
                {/* Profile Overview */}
                <div className="flex flex-col items-center mb-8 text-center">
                  <div className="relative mb-4">
                    <img className="w-24 h-24 rounded-full border-2 border-primary p-1 object-cover" src={selectedUser.img} alt={selectedUser.name} />
                    <span className={`absolute bottom-1 right-1 w-5 h-5 ${selectedUser.dotColor} border-4 border-surface-container-lowest rounded-full`}></span>
                  </div>
                  <h4 className="text-xl font-bold">{selectedUser.name}</h4>
                  <p className="text-xs text-text-secondary mb-4">Member since {selectedUser.joinDate.split(',')[1]}</p>
                  <div className="flex gap-2">
                    <button className="bg-primary text-on-primary px-4 py-2 rounded text-[10px] font-label-accent tracking-widest">MESSAGE</button>
                    <button className="border border-error text-error px-4 py-2 rounded text-[10px] font-label-accent tracking-widest hover:bg-error hover:text-on-error transition-all">BAN USER</button>
                  </div>
                </div>
                {/* Stats Grid */}
                <div className="grid grid-cols-2 gap-4 mb-8">
                  <div className="bg-surface-card p-4 border border-outline-variant rounded">
                    <p className="text-[8px] text-text-secondary uppercase tracking-widest mb-1">Total Spent</p>
                    <p className="text-lg font-bold text-primary">$4,280.00</p>
                  </div>
                  <div className="bg-surface-card p-4 border border-outline-variant rounded">
                    <p className="text-[8px] text-text-secondary uppercase tracking-widest mb-1">Orders</p>
                    <p className="text-lg font-bold text-primary">12</p>
                  </div>
                </div>
                {/* Tabs in Drawer */}
                <div className="flex border-b border-outline-variant mb-6 text-[10px]">
                  <button className="pb-2 border-b-2 border-primary text-primary font-bold px-4">HISTORY</button>
                  <button className="pb-2 text-on-surface-variant font-bold px-4 hover:text-on-surface">LOGS</button>
                  <button className="pb-2 text-on-surface-variant font-bold px-4 hover:text-on-surface">NOTES</button>
                </div>
                {/* Order History List */}
                <div className="space-y-4">
                  {[
                    { id: "#ORD-2024-881", date: "Feb 14, 2024", items: "3 Items", price: "$340.00" },
                    { id: "#ORD-2024-742", date: "Jan 22, 2024", items: "1 Item", price: "$120.00" },
                    { id: "#ORD-2023-998", date: "Dec 01, 2023", items: "5 Items", price: "$1,150.00" },
                  ].map((order) => (
                    <div key={order.id} className="flex items-center justify-between p-3 bg-surface-container rounded border border-outline-variant/30">
                      <div>
                        <p className="text-xs font-bold">{order.id}</p>
                        <p className="text-[10px] text-text-secondary">{order.date} • {order.items}</p>
                      </div>
                      <p className="text-sm font-bold text-primary">{order.price}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </>
        )}
      </main>
    </div>
  );
}
