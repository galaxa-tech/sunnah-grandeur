"use client";
import { useEffect } from 'react';

export default function ThemeInitializer() {
  useEffect(() => {
    try {
      const stored = localStorage.getItem('sunnah-theme');
      if (stored) {
        const parsed = JSON.parse(stored);
        const theme = parsed?.state?.theme;
        if (theme === 'light' || theme === 'dark') {
          document.documentElement.dataset.theme = theme;
        }
      }
    } catch {
      // silently ignore storage errors
    }
  }, []);

  return null;
}
