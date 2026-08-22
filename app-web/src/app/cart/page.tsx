"use client";
import Link from 'next/link';
import { useCartStore } from '@/store/useCartStore';

export default function CartPage() {
  const { items, updateQuantity, removeItem, clearCart, getSubtotal } = useCartStore();

  const subtotal = getSubtotal();
  const vat = Math.round(subtotal * 0.05); // 5% VAT
  const total = subtotal + vat;

  return (
    <div className="flex-grow pt-32 pb-section-padding px-gutter max-w-container-max mx-auto w-full min-h-[75vh]">
      <div className="mb-12 flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-headline-xl font-headline-xl text-primary mb-2">Your Cart</h1>
          <p className="text-body-lg font-body-lg text-on-surface-variant">
            Review your selections before completing your purchase.
          </p>
        </div>
        {items.length > 0 && (
          <button
            onClick={() => clearCart()}
            className="text-xs text-text-secondary hover:text-red-400 flex items-center gap-1 transition-colors"
          >
            <span className="material-symbols-outlined text-base">delete_sweep</span>
            Clear Cart
          </button>
        )}
      </div>

      {items.length === 0 ? (
        <div className="text-center py-20 bg-surface-card rounded-xl border border-border-subtle max-w-xl mx-auto space-y-4">
          <span className="material-symbols-outlined text-5xl text-primary-container">shopping_bag</span>
          <h2 className="text-xl font-bold text-text-primary">Your cart is currently empty</h2>
          <p className="text-sm text-text-secondary">Explore our exclusive collections of artisanal fragrances, thobes, and prayer tools.</p>
          <Link
            href="/shop"
            className="inline-block mt-4 bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest px-8 py-3.5 rounded hover:bg-[#e6c364] transition-colors"
          >
            Continue Shopping
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 relative">
          {/* Cart Items List (Left Column) */}
          <div className="lg:col-span-8 space-y-6">
            {items.map((item) => (
              <div
                key={item.id}
                className="bg-surface-card rounded-lg border border-border-subtle p-6 flex flex-col sm:flex-row gap-6 relative group hover:border-primary/50 transition-colors duration-300"
              >
                {/* Image */}
                <div className="w-full sm:w-32 h-32 flex-shrink-0 bg-surface rounded overflow-hidden border border-border-subtle">
                  <img
                    alt={item.name}
                    className="w-full h-full object-cover"
                    src={item.image}
                  />
                </div>

                {/* Details */}
                <div className="flex-grow flex flex-col justify-between">
                  <div className="flex justify-between items-start">
                    <div>
                      <h3 className="text-body-lg font-body-lg font-medium text-on-surface mb-1">
                        {item.name}
                      </h3>
                      <p className="text-body-md font-body-md text-on-surface-variant mb-2">
                        {item.size || item.category}
                      </p>
                      {item.giftWrap && (
                        <span className="inline-flex items-center gap-1 text-[11px] bg-primary-container/20 text-primary-container px-2 py-0.5 rounded">
                          <span className="material-symbols-outlined text-xs">card_giftcard</span>
                          Gift Wrapped (+৳50)
                        </span>
                      )}
                    </div>
                    <button
                      onClick={() => removeItem(item.id)}
                      aria-label="Remove item"
                      className="text-on-surface-variant hover:text-error transition-colors"
                    >
                      <span className="material-symbols-outlined">delete</span>
                    </button>
                  </div>

                  <div className="flex justify-between items-end mt-4">
                    {/* Quantity Controls */}
                    <div className="flex items-center border border-border-subtle rounded-DEFAULT bg-surface">
                      <button
                        onClick={() => updateQuantity(item.id, item.quantity - 1)}
                        className="w-8 h-8 flex items-center justify-center text-on-surface-variant hover:text-primary transition-colors"
                      >
                        <span className="material-symbols-outlined text-sm">remove</span>
                      </button>
                      <span className="w-8 text-center text-body-md font-body-md">
                        {item.quantity}
                      </span>
                      <button
                        onClick={() => updateQuantity(item.id, item.quantity + 1)}
                        className="w-8 h-8 flex items-center justify-center text-on-surface-variant hover:text-primary transition-colors"
                      >
                        <span className="material-symbols-outlined text-sm">add</span>
                      </button>
                    </div>

                    {/* Price */}
                    <div className="text-headline-md font-headline-md text-primary">
                      ৳{(item.price * item.quantity).toLocaleString()}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Order Summary (Right Column - Sticky) */}
          <div className="lg:col-span-4">
            <div className="sticky top-28 bg-surface-card rounded-lg border border-border-subtle p-8 shadow-xl">
              <h2 className="text-headline-lg font-headline-lg text-primary border-b border-border-subtle pb-4 mb-6">
                Order Summary
              </h2>
              <div className="space-y-4 text-body-md font-body-md">
                <div className="flex justify-between">
                  <span className="text-on-surface-variant">Subtotal</span>
                  <span className="text-on-surface">৳{subtotal.toLocaleString()}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-on-surface-variant">Estimated VAT (5%)</span>
                  <span className="text-on-surface">৳{vat.toLocaleString()}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-on-surface-variant">Shipping</span>
                  <span className="text-green-400 font-medium">Free (Standard)</span>
                </div>
              </div>
              <div className="border-t border-border-subtle mt-6 pt-6 flex justify-between items-end">
                <span className="text-body-lg font-body-lg text-on-surface">Total</span>
                <span className="text-headline-lg font-headline-lg text-primary">
                  ৳{total.toLocaleString()}
                </span>
              </div>
              <Link
                href="/checkout"
                className="w-full mt-8 bg-primary-container text-[#0A0A0A] py-4 rounded-DEFAULT text-label-accent font-label-accent hover:shadow-[0_0_15px_rgba(201,168,76,0.3)] transition-all duration-300 uppercase tracking-widest flex justify-center items-center gap-2"
              >
                <span>Proceed to Checkout</span>
                <span className="material-symbols-outlined text-sm">arrow_forward</span>
              </Link>

              <div className="mt-6 flex justify-center items-center gap-4 text-on-surface-variant/50">
                <span className="material-symbols-outlined" style={{ fontVariationSettings: "'FILL' 1" }}>
                  lock
                </span>
                <span className="text-label-accent font-label-accent">Secure Encrypted Checkout</span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
