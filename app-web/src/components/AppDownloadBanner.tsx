"use client";

import { useState, useEffect } from 'react';
import { usePathname } from 'next/navigation';

const DISMISSED_KEY = 'sunnah-app-banner-dismissed';

export default function AppDownloadBanner() {
  const pathname = usePathname();
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    let dismissed = false;
    try {
      dismissed = localStorage.getItem(DISMISSED_KEY) === '1';
    } catch {
      // localStorage unavailable (private mode, etc.) — fall back to showing it
    }
    if (dismissed) return;
    // Show banner after a slight delay
    const timer = setTimeout(() => {
      setIsVisible(true);
    }, 1500);
    return () => clearTimeout(timer);
  }, []);

  const handleDismiss = () => {
    setIsVisible(false);
    try {
      localStorage.setItem(DISMISSED_KEY, '1');
    } catch {
      // ignore — worst case it reappears next visit
    }
  };

  if (!isVisible) return null;

  // The cart page's sticky order summary (with its Proceed to Checkout CTA)
  // sits in the same bottom-right area, so shift the banner up there to avoid
  // covering it.
  const cartOffset = pathname === '/cart' ? 'md:bottom-32' : '';

  return (
    <div className={`fixed bottom-4 right-4 md:bottom-8 md:right-8 ${cartOffset} z-40 animate-in slide-in-from-bottom-5`}>
      <div className="bg-surface-card border border-primary-container shadow-[0_8px_30px_rgb(0,0,0,0.4)] rounded-xl p-4 flex items-center gap-4 max-w-sm relative">
        <button
          onClick={handleDismiss}
          className="absolute -top-2 -right-2 bg-surface-card border border-border-subtle rounded-full p-1 text-text-secondary hover:text-text-primary transition-colors"
        >
          <span className="material-symbols-outlined text-sm">close</span>
        </button>
        
        <div className="w-12 h-12 bg-primary-container/20 rounded-lg flex items-center justify-center flex-shrink-0 text-primary-container border border-primary-container/30">
          <span className="material-symbols-outlined text-2xl">mosque</span>
        </div>
        
        <div className="flex-1">
          <h4 className="text-text-primary font-bold text-sm">Muslim Productivity App</h4>
          <p className="text-text-secondary text-xs mt-0.5 leading-snug">Adhan alarms, Qibla finder, daily Hadiths &amp; Mobile Store.</p>
          <a 
            href="https://sunnah-grandeur-app.web.app" 
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 mt-2 text-[10px] font-label-accent tracking-widest uppercase bg-primary-container text-bg-primary px-3 py-1.5 rounded font-bold hover:bg-[#e6c364] transition-colors"
          >
            <span className="material-symbols-outlined text-xs">download</span>
            Get App / APK
          </a>
        </div>
      </div>
    </div>
  );
}
