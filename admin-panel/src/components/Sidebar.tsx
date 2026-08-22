"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export default function Sidebar() {
  const pathname = usePathname();

  const menuItems = [
    { name: "Dashboard", href: "/dashboard", icon: "dashboard" },
    { name: "Users", href: "/dashboard/users", icon: "group" },
    { name: "Media", href: "/dashboard/media", icon: "perm_media" },
    { name: "Shop", href: "/dashboard/shop", icon: "shopping_bag" },
    { name: "Settings", href: "/dashboard/settings", icon: "settings" },
  ];

  const isActive = (href: string) => pathname === href;

  return (
    <aside className="flex flex-col h-full py-6 px-4 w-64 fixed left-0 top-0 bg-surface-container-lowest border-r border-outline-variant z-50">
      <div className="mb-10 px-2">
        <h1 className="font-headline-md text-headline-md font-bold text-primary">Sunnah Grandeur</h1>
        <p className="font-label-accent text-on-surface-variant text-[10px] tracking-widest uppercase mt-1">Administrator</p>
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
            <span className="font-body-md">{item.name}</span>
          </Link>
        ))}
      </nav>
      <div className="mt-auto px-2">
        <button className="w-full py-3 bg-primary-container text-on-primary-container font-label-accent uppercase text-[10px] tracking-widest hover:brightness-110 transition-all flex items-center justify-center gap-2">
          <span className="material-symbols-outlined text-sm">add</span>
          New Product
        </button>
        <div className="mt-6 flex items-center gap-3 px-2 border-t border-outline-variant pt-6">
          <img
            alt="Admin User"
            className="w-10 h-10 rounded-full grayscale hover:grayscale-0 transition-all duration-500 object-cover"
            src="https://lh3.googleusercontent.com/aida-public/AB6AXuCzY87dMCJ2MTRg9sZFdP2f53VSS2o-MjzrrO420jbjTGf4gcLMQ5by5peZGq4i5gWxwxXWwwNi8nhG_BzcAdWdaMAYh9gUBvN1lD_DcXOFARICZZlWvgSft9O2T8idP29M-_hMm8Ft6_j8eKA7paaiAkZO9KVTMu3aUIzf7J4zdIfbJzCXxXBu18HCrZ72111muGsT3InlhZVYMqdgOr5I5c3PPfEBDFwfPc5CF1mK3dYj7doFAeq7jmtpjlKEtZXmt1xzWBYjkpw7"
          />
          <div>
            <p className="text-on-surface text-sm font-semibold">Admin User</p>
            <p className="text-on-surface-variant text-[10px]">Super Admin</p>
          </div>
        </div>
      </div>
    </aside>
  );
}
