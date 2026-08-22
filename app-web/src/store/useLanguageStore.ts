import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { Lang } from '@/translations';

interface LanguageState {
  language: Lang;
  setLanguage: (lang: Lang) => void;
}

export const useLanguageStore = create<LanguageState>()(
  persist(
    (set) => ({
      language: 'EN',
      setLanguage: (lang) => {
        if (typeof window !== 'undefined') {
          document.documentElement.dir = lang === 'AR' ? 'rtl' : 'ltr';
          document.documentElement.lang = lang.toLowerCase();
        }
        set({ language: lang });
      },
    }),
    {
      name: 'sunnah-lang-storage',
    }
  )
);
