import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface CartItem {
  id: string;
  name: string;
  price: number;
  image: string;
  category: string;
  quantity: number;
  size?: string;
  giftWrap?: boolean;
}

interface CartState {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  getTotalItems: () => number;
  getSubtotal: () => number;
}

export const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      items: [
        {
          id: '1',
          name: 'Oud Al-Majd Parfum',
          price: 1850,
          image: 'https://lh3.googleusercontent.com/aida/ADBb0uhEEleu7KmJZIDy9o-R0e1n7ajgAMkENyQ4eHjdI4eQF3vTywhBkToaiHR9Wri96NN64i7sdHclPPVpRNUdvoSXdF59d4qSzwG1w_XHiLUvh838-UE1Woog14E6V3-19LDckStk_xuTsJvqDFf8BImFbh4GEmcgYt0syVIceAwHl2ugiPShK_VRzf64WhUtYCrvcfSypyUI1y-s1uKaTV92l8YhScZsofow7Y4QZLUxOOnthfZ42XzihYkrDRq3yIq2VB1P14_jsNs',
          category: 'Fragrances',
          quantity: 1,
          size: '50ml / Extrait de Parfum'
        },
        {
          id: '2',
          name: 'Misbaha - Black Onyx',
          price: 1200,
          image: 'https://lh3.googleusercontent.com/aida/ADBb0uhsU8VEnWQ1uBQTs_keaDDehAZQcdpIeUxWBS5oK64jU-SKUjoSVsafpJ_sgbzSLDQZ9fc9foE4Qx90LwDtrZxRPaQ_GptANfkOMTQyowXQrmOxL8rPdbd446pAZLymnr5qbrAfNKYatrYHFQsDluDaWaSNICpEeVukO0ZafXKi4tzDm40sA9Awp18xY6mhzxruAg53cGKkiUy6hXoCDvg-JJg9NHAhaPpT61MOTrp8BP7GyKeGKgys1YS1BLQQ7XqxEhe9FyX2Whw',
          category: 'Salah & Worship',
          quantity: 2,
          size: '99 Beads'
        }
      ],
      addItem: (newItem) => {
        set((state) => {
          const existingIndex = state.items.findIndex((i) => i.id === newItem.id);
          if (existingIndex > -1) {
            const updated = [...state.items];
            updated[existingIndex].quantity += newItem.quantity;
            return { items: updated };
          }
          return { items: [...state.items, newItem] };
        });
      },
      removeItem: (id) => {
        set((state) => ({
          items: state.items.filter((i) => i.id !== id)
        }));
      },
      updateQuantity: (id, quantity) => {
        if (quantity <= 0) {
          get().removeItem(id);
          return;
        }
        set((state) => ({
          items: state.items.map((i) => (i.id === id ? { ...i, quantity } : i))
        }));
      },
      clearCart: () => set({ items: [] }),
      getTotalItems: () => get().items.reduce((total, i) => total + i.quantity, 0),
      getSubtotal: () => get().items.reduce((total, i) => total + i.price * i.quantity, 0)
    }),
    {
      name: 'sunnah-grandeur-cart'
    }
  )
);
