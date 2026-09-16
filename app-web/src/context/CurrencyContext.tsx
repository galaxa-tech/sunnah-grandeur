"use client";
import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { doc, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { DEFAULT_BDT_TO_USD_RATE } from "@/lib/currency";

interface CurrencyContextType {
  usdRate: number;
}

const CurrencyContext = createContext<CurrencyContextType | null>(null);

export function CurrencyProvider({ children }: { children: ReactNode }) {
  const [usdRate, setUsdRate] = useState(DEFAULT_BDT_TO_USD_RATE);

  useEffect(() => {
    const unsub = onSnapshot(doc(db, "settings", "app_config"), (snap) => {
      const rate = snap.data()?.usdToLocalRate;
      if (typeof rate === "number" && rate > 0) setUsdRate(rate);
    }, (error) => {
      console.error("Error listening to app_config:", error);
    });
    return unsub;
  }, []);

  return (
    <CurrencyContext.Provider value={{ usdRate }}>
      {children}
    </CurrencyContext.Provider>
  );
}

export function useCurrency() {
  const ctx = useContext(CurrencyContext);
  if (!ctx) throw new Error("useCurrency must be used inside CurrencyProvider");
  return ctx;
}
