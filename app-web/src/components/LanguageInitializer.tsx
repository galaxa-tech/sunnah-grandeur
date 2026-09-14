"use client";
import { useEffect } from 'react';

export default function LanguageInitializer() {
  useEffect(() => {
    try {
      const stored = localStorage.getItem('sunnah-lang-storage');
      if (stored) {
        const parsed = JSON.parse(stored);
        const lang = parsed?.state?.language;
        if (lang) {
          document.documentElement.dir = lang === 'AR' ? 'rtl' : 'ltr';
          document.documentElement.lang = lang.toLowerCase();
        }
      }
    } catch {
      // silently ignore storage errors
    }
  }, []);

  return null;
}
