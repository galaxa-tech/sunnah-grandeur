"use client";

import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";

export default function SettingsPage() {
  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 flex flex-col min-h-screen relative bento-pattern overflow-hidden">
        <Header title="Store Settings" />

        <div className="p-8 max-w-[1000px] mx-auto w-full relative z-10 space-y-8">
          {/* General Store Information */}
          <div className="bg-surface-card border border-border-subtle rounded-xl p-8 shadow-xl space-y-6">
            <h3 className="font-headline-md text-xl text-primary border-b border-border-subtle pb-4">
              General Store Settings
            </h3>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 text-sm">
              <div className="space-y-2">
                <label className="block text-xs font-label-accent uppercase text-on-surface-variant">Store Name</label>
                <input
                  type="text"
                  defaultValue="Sunnah Grandeur"
                  className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-on-surface focus:outline-none focus:border-primary"
                />
              </div>

              <div className="space-y-2">
                <label className="block text-xs font-label-accent uppercase text-on-surface-variant">Default Currency</label>
                <select className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-on-surface focus:outline-none focus:border-primary">
                  <option value="BDT">BDT (৳) - Bangladeshi Taka</option>
                  <option value="USD">USD ($) - US Dollar</option>
                  <option value="SAR">SAR (﷼) - Saudi Riyal</option>
                </select>
              </div>

              <div className="space-y-2">
                <label className="block text-xs font-label-accent uppercase text-on-surface-variant">Support Email</label>
                <input
                  type="email"
                  defaultValue="support@sunnahgrandeur.com"
                  className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-on-surface focus:outline-none focus:border-primary"
                />
              </div>

              <div className="space-y-2">
                <label className="block text-xs font-label-accent uppercase text-on-surface-variant">Tax Rate (%)</label>
                <input
                  type="number"
                  defaultValue="5"
                  className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-on-surface focus:outline-none focus:border-primary"
                />
              </div>
            </div>

            <div className="flex justify-end pt-4">
              <button
                onClick={() => alert("Settings saved successfully.")}
                className="bg-primary text-on-primary font-label-accent text-xs px-8 py-3 rounded uppercase tracking-widest hover:brightness-110 shadow-lg shadow-primary/20 transition-all"
              >
                Save Settings
              </button>
            </div>
          </div>

          {/* Security & Authentication */}
          <div className="bg-surface-card border border-border-subtle rounded-xl p-8 shadow-xl space-y-6">
            <h3 className="font-headline-md text-xl text-primary border-b border-border-subtle pb-4">
              Security & Firebase Permissions
            </h3>
            
            <div className="space-y-4 text-xs text-on-surface-variant">
              <div className="flex items-center justify-between p-4 bg-surface-container rounded-lg border border-border-subtle">
                <div>
                  <p className="font-semibold text-on-background text-sm">Require Auth for Dashboard Access</p>
                  <p>Restricted access enforced via Firebase Auth role checks.</p>
                </div>
                <span className="text-emerald-400 font-bold px-3 py-1 bg-emerald-950 rounded-full border border-emerald-800">
                  ACTIVE
                </span>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
