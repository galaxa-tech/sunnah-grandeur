"use client";

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';

interface Props {
  productId: string;
  saved: boolean;
  onToggleSave: () => void;
  onAddToCart?: () => void;
  soldOut?: boolean;
}

// Three-dot menu on a product card: Save for later (wishlist), add to cart, view.
// Click/tap driven (not hover) so it works on touch devices and in Safari.
export default function ProductMenu({ productId, saved, onToggleSave, onAddToCart, soldOut }: Props) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const close = (e: Event) => { if (!ref.current?.contains(e.target as Node)) setOpen(false); };
    const esc = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    document.addEventListener('mousedown', close);
    document.addEventListener('touchstart', close);
    document.addEventListener('keydown', esc);
    return () => {
      document.removeEventListener('mousedown', close);
      document.removeEventListener('touchstart', close);
      document.removeEventListener('keydown', esc);
    };
  }, [open]);

  const item = 'w-full flex items-center gap-2 px-3 py-2.5 text-left text-xs text-text-primary hover:bg-primary/10 transition-colors';

  return (
    <div ref={ref} className="absolute top-2 right-2 z-30">
      <button
        type="button"
        aria-label="More options"
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((o) => !o)}
        className="w-9 h-9 rounded-full bg-black/60 border border-white/10 flex items-center justify-center text-white hover:bg-black/80 transition-colors"
      >
        <span className="material-symbols-outlined text-xl">more_vert</span>
      </button>
      {open && (
        <div role="menu" className="absolute right-0 mt-1 w-44 rounded-lg bg-surface-card border border-border-subtle shadow-2xl overflow-hidden">
          <button role="menuitem" type="button" className={item} onClick={() => { onToggleSave(); setOpen(false); }}>
            <span className="material-symbols-outlined text-base text-primary-container" style={{ fontVariationSettings: saved ? "'FILL' 1" : "'FILL' 0" }}>favorite</span>
            {saved ? 'Remove from wishlist' : 'Save for later'}
          </button>
          {onAddToCart && !soldOut && (
            <button role="menuitem" type="button" className={item} onClick={() => { onAddToCart(); setOpen(false); }}>
              <span className="material-symbols-outlined text-base">add_shopping_cart</span>
              Add to cart
            </button>
          )}
          <Link role="menuitem" href={`/product/${productId}`} className={item} onClick={() => setOpen(false)}>
            <span className="material-symbols-outlined text-base">visibility</span>
            View details
          </Link>
        </div>
      )}
    </div>
  );
}
