"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { onAuthStateChanged, signOut, User } from "firebase/auth";
import { auth } from "@/lib/firebase";

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [isMobileOpen, setIsMobileOpen] = useState(false);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
    });
    return () => unsubscribe();
  }, []);

  // Close the mobile drawer whenever the admin navigates to a new section.
  useEffect(() => {
    setIsMobileOpen(false);
  }, [pathname]);

  const handleLogout = async () => {
    try {
      await signOut(auth);
      router.push("/login");
    } catch (err) {
      console.error("Logout error:", err);
    }
  };

  const menuItems = [
    { name: "Dashboard", href: "/dashboard", icon: "dashboard" },
    { name: "Users", href: "/dashboard/users", icon: "group" },
    { name: "Shop & Orders", href: "/dashboard/shop", icon: "shopping_bag" },
    { name: "Media", href: "/dashboard/media", icon: "video_library" },
    { name: "Settings", href: "/dashboard/settings", icon: "settings" },
  ];

  const isActive = (href: string) => pathname === href;

  const displayName = user?.displayName || user?.email?.split('@')[0] || "Super Admin";
  const userEmail = user?.email || "admin@sunnahgrandeur.com";

  return (
    <>
      {/* Mobile menu trigger — the sidebar is off-screen by default below md */}
      <button
        onClick={() => setIsMobileOpen(true)}
        aria-label="Open menu"
        className="md:hidden fixed top-4 left-4 z-40 w-10 h-10 rounded-lg bg-surface-container-lowest border border-outline-variant flex items-center justify-center text-primary"
      >
        <span className="material-symbols-outlined">menu</span>
      </button>

      {/* Backdrop, mobile only, while the drawer is open */}
      {isMobileOpen && (
        <div
          onClick={() => setIsMobileOpen(false)}
          className="md:hidden fixed inset-0 bg-black/70 z-40"
        />
      )}

      <aside
        className={`flex flex-col h-full py-6 px-4 w-64 fixed left-0 top-0 bg-surface-container-lowest border-r border-outline-variant z-50 transition-transform duration-300 ease-in-out ${
          isMobileOpen ? "translate-x-0" : "-translate-x-full"
        } md:translate-x-0`}
      >
        <button
          onClick={() => setIsMobileOpen(false)}
          aria-label="Close menu"
          className="md:hidden self-end mb-2 w-8 h-8 flex items-center justify-center text-on-surface-variant hover:text-primary"
        >
          <span className="material-symbols-outlined">close</span>
        </button>
        <div className="mb-10 px-2">
          <h1 className="font-headline-md text-headline-md font-bold text-primary">Sunnah Grandeur</h1>
          <p className="font-label-accent text-on-surface-variant text-[10px] tracking-widest uppercase mt-1">Administrator Portal</p>
        </div>

      <nav className="flex-1 space-y-1">
        {menuItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={`flex items-center px-4 py-3 transition-all duration-300 ease-in-out group ${
              isActive(item.href)
                ? "text-primary bg-secondary-container/10 border-r-2 border-primary"
                : "text-on-surface-variant hover:bg-surface-container-high hover:text-primary"
            }`}
          >
            <span className="material-symbols-outlined mr-3">{item.icon}</span>
            <span className="font-body-md text-sm font-medium">{item.name}</span>
          </Link>
        ))}
      </nav>

      <div className="mt-auto px-2 space-y-4">
        <Link 
          href="/dashboard/shop"
          className="w-full py-3 bg-primary-container text-on-primary-container font-label-accent uppercase text-[10px] tracking-widest hover:brightness-110 transition-all flex items-center justify-center gap-2 rounded"
        >
          <span className="material-symbols-outlined text-sm">add</span>
          Add New Product
        </Link>

        <div className="flex items-center justify-between gap-2 px-2 border-t border-outline-variant pt-4">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="w-8 h-8 rounded-full bg-primary/20 border border-primary/40 flex items-center justify-center text-primary font-bold text-xs shrink-0">
              {displayName.charAt(0).toUpperCase()}
            </div>
            <div className="min-w-0">
              <p className="text-on-surface text-xs font-bold truncate">{displayName}</p>
              <p className="text-on-surface-variant text-[9px] truncate" title={userEmail}>{userEmail}</p>
            </div>
          </div>

          <button 
            onClick={handleLogout}
            title="Sign Out"
            className="p-1.5 text-on-surface-variant hover:text-red-400 hover:bg-red-500/10 rounded transition-colors"
          >
            <span className="material-symbols-outlined text-lg">logout</span>
          </button>
        </div>
      </div>
      </aside>
    </>
  );
}
