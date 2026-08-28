"use client";

import { useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { collection, onSnapshot, doc, updateDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";

export default function UserManagementPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<any>(null);

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "users"), (snapshot) => {
      const list: any[] = [];
      snapshot.forEach((doc) => {
        list.push({ id: doc.id, ...doc.data() });
      });
      setUsers(list);
      setLoading(false);
    }, (error) => {
      console.error("Error listening to users collection:", error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // System Team Accounts Fallback if Firestore collection is empty
  const defaultAdmins = [
    { id: "admin-1", name: "Sunnah Grandeur SuperAdmin", email: "sunnahgrandeur.nyc@gmail.com", role: "SuperAdmin", status: "Active", joinDate: "Aug 2026" },
    { id: "admin-2", name: "Talha RRC (Admin)", email: "talharrc@gmail.com", role: "Administrator", status: "Active", joinDate: "Aug 2026" },
    { id: "admin-3", name: "Rihad Hamid (Admin)", email: "rihadhamid20@gmail.com", role: "Administrator", status: "Active", joinDate: "Aug 2026" },
  ];

  const displayUsers = users.length > 0 ? users : defaultAdmins;

  const handleToggleUserRole = async (userId: string, currentRole: string) => {
    if (userId.startsWith("admin-")) return;
    try {
      const newRole = currentRole === "admin" ? "user" : "admin";
      await updateDoc(doc(db, "users", userId), { role: newRole });
    } catch (err) {
      console.error("Error updating user role:", err);
    }
  };

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
              <span className="bg-primary text-on-primary px-6 py-2 rounded-full font-label-accent text-[10px] tracking-widest font-bold uppercase">
                Registered Accounts ({displayUsers.length})
              </span>
              <span className="bg-surface-card border border-outline-variant text-on-surface-variant px-6 py-2 rounded-full font-label-accent text-[10px] tracking-widest uppercase">
                Active Firestore Session
              </span>
            </div>
          </div>

          {/* Table Container */}
          <div className="bg-surface-card border border-border-subtle rounded-xl overflow-hidden shadow-2xl">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-outline-variant bg-surface-container-lowest">
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest">Avatar</th>
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest">User Details</th>
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest">Role</th>
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest">Status</th>
                    <th className="px-6 py-4 font-headline-md text-[10px] text-primary uppercase tracking-widest text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-outline-variant/20">
                  {displayUsers.map((user) => {
                    const name = user.name || user.email?.split('@')[0] || "User";
                    const initial = name.charAt(0).toUpperCase();
                    const isAdmin = user.role === "admin" || user.role === "superAdmin" || user.role === "SuperAdmin" || user.role === "Administrator";

                    return (
                      <tr 
                        key={user.id} 
                        className="hover:bg-surface-container-low transition-colors group"
                      >
                        <td className="px-6 py-4">
                          <div className="w-10 h-10 rounded-full bg-primary/20 border border-primary/40 text-primary font-bold text-sm flex items-center justify-center">
                            {initial}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex flex-col">
                            <span className="font-bold text-on-surface text-sm">{name}</span>
                            <span className="text-xs text-text-secondary font-mono">{user.email}</span>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <span className={`text-[10px] font-bold uppercase tracking-wider px-2.5 py-1 rounded border ${
                            isAdmin ? "border-gold-400/40 bg-gold-400/10 text-gold-400" : "border-slate-700 bg-slate-800 text-slate-300"
                          }`}>
                            {user.role || "User"}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <span className="text-[10px] font-bold uppercase tracking-wider px-2.5 py-1 rounded bg-emerald-500/10 border border-emerald-500/30 text-emerald-400">
                            Active
                          </span>
                        </td>
                        <td className="px-6 py-4 text-right">
                          <button
                            onClick={() => handleToggleUserRole(user.id, user.role || "user")}
                            className="text-xs text-primary hover:underline font-semibold"
                          >
                            {isAdmin ? "Demote to User" : "Promote to Admin"}
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
