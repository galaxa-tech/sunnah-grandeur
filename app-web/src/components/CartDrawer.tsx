"use client";
import React, { useEffect } from 'react';
import Link from 'next/link';
import { useCartStore } from '@/store/useCartStore';

interface CartDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function CartDrawer({ isOpen, onClose }: CartDrawerProps) {
  const { items, removeItem, updateQuantity, getSubtotal, getTotalItems } = useCartStore();
  const subtotal = getSubtotal();
  const totalCount = getTotalItems();

  // Free shipping & gift threshold: 2500 BDT
  const FREE_SHIPPING_THRESHOLD = 2500;
  const remainingForFree = Math.max(0, FREE_SHIPPING_THRESHOLD - subtotal);
  const progressPercent = Math.min(100, (subtotal / FREE_SHIPPING_THRESHOLD) * 100);

  // Close on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    if (isOpen) {
      document.body.style.overflow = "hidden";
      window.addEventListener("keydown", handleKeyDown);
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[100] flex justify-end">
      {/* Backdrop */}
      <div 
        onClick={onClose}
        className="fixed inset-0 bg-black/75 backdrop-blur-sm transition-opacity duration-500 animate-fadeIn"
      />

      {/* Drawer Container */}
      <div className="relative w-full max-w-md bg-[#0D0C0A] border-l border-primary/20 shadow-2xl flex flex-col h-full z-10 animate-slideLeft overflow-hidden">
        {/* Top Gold Accent Bar */}
        <div className="h-1 w-full bg-gradient-to-r from-transparent via-[#E6C364] to-transparent" />

        {/* Drawer Header */}
        <div className="p-6 border-b border-border-subtle flex items-center justify-between bg-[#12100C]/80 backdrop-blur-md">
          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-primary text-2xl">shopping_bag</span>
            <h3 className="font-cinzel text-lg font-bold tracking-wider text-text-primary">
              Shopping Bag <span className="text-primary text-sm font-sans font-normal">({totalCount})</span>
            </h3>
          </div>
          <button 
            onClick={onClose}
            className="w-9 h-9 rounded-full border border-border-subtle flex items-center justify-center text-text-secondary hover:text-primary hover:border-primary/50 transition-colors"
            aria-label="Close cart drawer"
          >
            <span className="material-symbols-outlined text-xl">close</span>
          </button>
        </div>

        {/* Free Shipping & Gift Progress */}
        <div className="p-4 bg-[#16130D] border-b border-border-subtle">
          <div className="flex justify-between items-center text-xs mb-2">
            <span className="text-text-secondary flex items-center gap-1.5">
              <span className="material-symbols-outlined text-primary text-sm">redeem</span>
              {remainingForFree === 0 ? (
                <span className="text-emerald-400 font-semibold">✨ Free Velvet Gift Box & Express Delivery Unlocked!</span>
              ) : (
                <span>Add <strong className="text-primary font-bold">৳{remainingForFree.toFixed(0)}</strong> for Free Express Delivery</span>
              )}
            </span>
            <span className="text-[10px] text-text-secondary font-mono">{progressPercent.toFixed(0)}%</span>
          </div>
          <div className="w-full h-1.5 bg-[#070707] rounded-full overflow-hidden border border-border-subtle">
            <div 
              className="h-full bg-gradient-to-r from-[#C9A84C] to-[#FFE8A3] transition-all duration-500 rounded-full"
              style={{ width: `${progressPercent}%` }}
            />
          </div>
        </div>

        {/* Cart Items List */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {items.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center text-center p-6 space-y-4">
              <div className="w-16 h-16 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center text-primary">
                <span className="material-symbols-outlined text-3xl">shopping_bag</span>
              </div>
              <div className="space-y-1">
                <h4 className="font-serif-luxury text-xl text-text-primary font-bold">Your Bag is Empty</h4>
                <p className="text-xs text-text-secondary max-w-xs">Discover pure non-alcoholic artisanal attars and handcrafted Islamic artifacts.</p>
              </div>
              <button 
                onClick={onClose}
                className="bg-primary/10 border border-primary/40 text-primary px-6 py-2.5 rounded text-xs font-bold uppercase tracking-widest hover:bg-primary hover:text-black transition-all"
              >
                Explore Collection
              </button>
            </div>
          ) : (
            items.map((item) => (
              <div 
                key={item.id} 
                className="flex gap-4 p-3.5 rounded-lg bg-[#14120E] border border-border-subtle hover:border-primary/30 transition-colors relative group"
              >
                {/* Product Thumbnail */}
                <div className="w-20 h-20 rounded bg-[#090806] border border-border-subtle overflow-hidden flex-shrink-0 relative">
                  {item.image ? (
                    <img 
                      src={item.image} 
                      alt={item.name} 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-primary/30">
                      <span className="material-symbols-outlined text-2xl">eco</span>
                    </div>
                  )}
                </div>

                {/* Details */}
                <div className="flex-1 flex flex-col justify-between">
                  <div>
                    <span className="text-[9px] text-primary/70 uppercase tracking-widest font-bold block">{item.category}</span>
                    <h4 className="text-xs font-bold text-text-primary line-clamp-1 group-hover:text-primary transition-colors">
                      {item.name}
                    </h4>
                    {item.size && (
                      <span className="text-[10px] text-text-secondary block mt-0.5">{item.size}</span>
                    )}
                  </div>

                  <div className="flex items-center justify-between mt-2">
                    {/* Quantity Selector */}
                    <div className="flex items-center border border-border-subtle rounded bg-[#0A0907]">
                      <button 
                        onClick={() => updateQuantity(item.id, item.quantity - 1)}
                        className="w-6 h-6 flex items-center justify-center text-text-secondary hover:text-primary transition-colors text-xs"
                        aria-label="Decrease quantity"
                      >
                        -
                      </button>
                      <span className="px-2 text-xs font-mono font-bold text-text-primary">{item.quantity}</span>
                      <button 
                        onClick={() => updateQuantity(item.id, item.quantity + 1)}
                        className="w-6 h-6 flex items-center justify-center text-text-secondary hover:text-primary transition-colors text-xs"
                        aria-label="Increase quantity"
                      >
                        +
                      </button>
                    </div>

                    {/* Price */}
                    <span className="font-mono font-bold text-sm text-primary">
                      ৳{(item.price * item.quantity).toLocaleString()}
                    </span>
                  </div>
                </div>

                {/* Remove Button */}
                <button 
                  onClick={() => removeItem(item.id)}
                  className="text-text-secondary hover:text-red-400 transition-colors p-1 self-start"
                  aria-label="Remove item"
                >
                  <span className="material-symbols-outlined text-base">delete</span>
                </button>
              </div>
            ))
          )}
        </div>

        {/* Footer Checkout Section */}
        {items.length > 0 && (
          <div className="p-6 border-t border-border-subtle bg-[#12100C]/90 backdrop-blur-md space-y-4">
            <div className="space-y-1.5 text-xs">
              <div className="flex justify-between text-text-secondary">
                <span>Subtotal</span>
                <span className="font-mono text-text-primary">৳{subtotal.toLocaleString()}</span>
              </div>
              <div className="flex justify-between text-text-secondary">
                <span>Estimated Shipping</span>
                <span className="font-mono text-text-primary">
                  {remainingForFree === 0 ? <span className="text-emerald-400">FREE</span> : "Calculated at checkout"}
                </span>
              </div>
              <div className="flex justify-between text-sm font-bold text-text-primary pt-2 border-t border-border-subtle">
                <span className="font-cinzel">Total</span>
                <span className="text-primary font-mono text-base">৳{subtotal.toLocaleString()} BDT</span>
              </div>
            </div>

            <div className="space-y-2 pt-1">
              <Link
                href="/cart"
                onClick={onClose}
                className="w-full block text-center bg-gradient-to-r from-[#E6C364] via-[#C9A84C] to-[#E6C364] text-black font-cinzel font-bold py-3 px-6 rounded text-xs uppercase tracking-widest hover:shadow-[0_0_20px_rgba(201,168,76,0.4)] hover:brightness-110 transition-all duration-300"
              >
                Proceed to Checkout
              </Link>
              <button
                onClick={onClose}
                className="w-full text-center text-text-secondary hover:text-primary transition-colors text-[11px] uppercase tracking-wider py-1 font-mono"
              >
                Continue Shopping
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
