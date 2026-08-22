import { create } from 'zustand';
import { persist } from 'zustand/middleware';

type Theme = 'dark' | 'light';

interface ThemeState {
  theme: Theme;
  setTheme: (theme: Theme) => void;
  toggleTheme: () => void;
}

export const useThemeStore = create<ThemeState>()(
  persist(
    (set, get) => ({
      theme: 'dark',
      setTheme: (theme) => {
        if (typeof window !== 'undefined') {
          document.documentElement.dataset.theme = theme;
        }
        set({ theme });
      },
      toggleTheme: () => {
        const next = get().theme === 'dark' ? 'light' : 'dark';
        if (typeof window !== 'undefined') {
          document.documentElement.dataset.theme = next;
        }
        set({ theme: next });
      },
    }),
    {
      name: 'sunnah-theme',
    }
  )
);
