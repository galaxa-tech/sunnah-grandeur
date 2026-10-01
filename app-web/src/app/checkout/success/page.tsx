"use client";

import { Suspense, useEffect } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useCartStore } from '@/store/useCartStore';

function SuccessContent() {
  const orderId = useSearchParams().get('order');
  const clearCart = useCartStore((s) => s.clearCart);

  // Stripe only redirects here after a completed payment; the webhook marks the
  // order paid server-side, so this page just clears the local cart.
  useEffect(() => { clearCart(); }, [clearCart]);

  return (
    <div className="pt-32 pb-24 px-4 max-w-2xl mx-auto text-center space-y-6">
      <div className="w-20 h-20 bg-primary-container/20 text-primary-container rounded-full flex items-center justify-center mx-auto border border-primary-container/40">
        <span className="material-symbols-outlined text-4xl">check_circle</span>
      </div>
      <h1 className="text-3xl font-bold text-text-primary font-serif">Payment Received — Thank You!</h1>
      <p className="text-text-secondary text-sm">
        Your order is being processed.
        {orderId && <> Reference: <span className="font-mono font-bold text-primary-container text-base">{orderId}</span></>}
      </p>
      <Link
        href="/shop"
        className="inline-block bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest px-8 py-3.5 rounded hover:bg-[#e6c364] transition-colors"
      >
        Return to Storefront
      </Link>
    </div>
  );
}

export default function CheckoutSuccessPage() {
  return <Suspense fallback={null}><SuccessContent /></Suspense>;
}
