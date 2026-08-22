"use client";

import { useState, useEffect } from "react";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";

export default function SettingsPage() {
  const [storeName, setStoreName] = useState("Sunnah Grandeur");
  const [currency, setCurrency] = useState("BDT");
  const [supportEmail, setSupportEmail] = useState("support@sunnahgrandeur.com");
  const [taxRate, setTaxRate] = useState("5");
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: "success" | "error" } | null>(null);

  useEffect(() => {
    async function loadSettings() {
      try {
        const snap = await getDoc(doc(db, "settings", "general"));
        if (snap.exists()) {
          const data = snap.data();
          if (data.storeName) setStoreName(data.storeName);
          if (data.currency) setCurrency(data.currency);
          if (data.supportEmail) setSupportEmail(data.supportEmail);
          if (data.taxRate) setTaxRate(data.taxRate.toString());
        }
      } catch (err) {
        console.error("Error loading store settings:", err);
      }
    }
    loadSettings();
  }, []);

  const handleSaveSettings = async () => {
    setSaving(true);
    setMessage(null);
    try {
      await setDoc(doc(db, "settings", "general"), {
        storeName,
        currency,
        supportEmail,
        taxRate: parseFloat(taxRate) || 5,
        updatedAt: new Date().toISOString(),
      }, { merge: true });

      setMessage({ text: "Store settings saved successfully to Firestore!", type: "success" });
    } catch (err: any) {
      console.error("Error saving settings:", err);
      setMessage({ text: err.message || "Failed to save settings.", type: "error" });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 flex flex-col min-h-screen relative bento-pattern overflow-hidden">
        <Header title="Store Settings" />

        <div className="p-8 max-w-[1000px] mx-auto w-full relative z-10 space-y-8">
          {message && (
            <div className={`p-4 rounded-lg text-xs font-semibold text-center border ${
              message.type === "success" 
                ? "bg-emerald-500/10 border-emerald-500/30 text-emerald-400" 
                : "bg-red-500/10 border-red-500/30 text-red-400"
            }`}>
              {message.text}
            </div>
          )}

          {/* General Store Information */}
          <div className="bg-surface-card border border-border-subtle rounded-xl p-8 shadow-xl space-y-6">
            <h3 className="font-headline-md text-xl text-primary border-b border-border-subtle pb-4 font-bold">
              General Store Configuration
            </h3>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 text-sm">
              <div className="space-y-2">
                <label className="block text-xs font-label-accent uppercase text-on-surface-variant">Store Name</label>
                <input
                  type="text"
                  value={storeName}
                  onChange={(e) => setStoreName(e.target.value)}
                  className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-on-surface focus:outline-none focus:border-primary text-xs"
                />
              </div>

              <div className="space-y-2">
                <label className="block text-xs font-label-accent uppercase text-on-surface-variant">Default Currency</label>
                <select 
                  value={currency}
                  onChange={(e) => setCurrency(e.target.value)}
                  className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-on-surface focus:outline-none focus:border-primary text-xs"
                >
                  <option value="BDT">BDT (৳) - Bangladeshi Taka</option>
                  <option value="USD">USD ($) - US Dollar</option>
                  <option value="SAR">SAR (﷼) - Saudi Riyal</option>
                </select>
              </div>

              <div className="space-y-2">
                <label className="block text-xs font-label-accent uppercase text-on-surface-variant">Support Email</label>
                <input
                  type="email"
                  value={supportEmail}
                  onChange={(e) => setSupportEmail(e.target.value)}
                  className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-on-surface focus:outline-none focus:border-primary text-xs"
                />
              </div>

              <div className="space-y-2">
                <label className="block text-xs font-label-accent uppercase text-on-surface-variant">Tax Rate (%)</label>
                <input
                  type="number"
                  value={taxRate}
                  onChange={(e) => setTaxRate(e.target.value)}
                  className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-on-surface focus:outline-none focus:border-primary text-xs"
                />
              </div>
            </div>

            <div className="flex justify-end pt-4">
              <button
                onClick={handleSaveSettings}
                disabled={saving}
                className="bg-primary text-on-primary font-label-accent text-xs px-8 py-3 rounded uppercase tracking-widest hover:brightness-110 shadow-lg shadow-primary/20 transition-all font-bold disabled:opacity-50"
              >
                {saving ? "Saving to Firestore..." : "Save Settings"}
              </button>
            </div>
          </div>

          {/* Security & Authentication */}
          <div className="bg-surface-card border border-border-subtle rounded-xl p-8 shadow-xl space-y-6">
            <h3 className="font-headline-md text-xl text-primary border-b border-border-subtle pb-4 font-bold">
              Security &amp; Permissions
            </h3>
            
            <div className="space-y-4 text-xs text-on-surface-variant">
              <div className="flex items-center justify-between p-4 bg-dark-900 rounded-lg border border-border-subtle">
                <div>
                  <p className="font-semibold text-white text-sm">Require Auth for Admin Panel Access</p>
                  <p className="text-[11px] text-slate-400">Restricted access enforced via Firebase Auth session verification.</p>
                </div>
                <span className="text-emerald-400 font-bold text-[10px] uppercase px-3 py-1 bg-emerald-950 rounded-full border border-emerald-800">
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
