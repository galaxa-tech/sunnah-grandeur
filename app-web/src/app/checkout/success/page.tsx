"use client";

import { Suspense, useEffect, useState } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { doc, onSnapshot } from 'firebase/firestore';
import { useCartStore } from '@/store/useCartStore';
import { useAuth } from '@/context/AuthContext';
import { db } from '@/lib/firebase';
import { formatUsdFromCents } from '@/lib/currency';

function SuccessContent() {
  const orderId = useSearchParams().get('order');
  const clearCart = useCartStore((s) => s.clearCart);
  const { user, linkGuestAccount } = useAuth();
  const [order, setOrder] = useState<any>(null);
  const [password, setPassword] = useState('');
  const [upgradeError, setUpgradeError] = useState('');
  const [upgraded, setUpgraded] = useState(false);
  const [busy, setBusy] = useState(false);

  useEffect(() => { clearCart(); }, [clearCart]);

  // Live order status — the Stripe webhook / PayPal capture flips it to Processing.
  useEffect(() => {
    if (!orderId) return;
    return onSnapshot(doc(db, 'orders', orderId), (s) => setOrder(s.exists() ? s.data() : null), () => setOrder(null));
  }, [orderId, user?.uid]);

  const paid = order?.paymentStatus === 'paid' || order?.status === 'Processing';
  const email: string = order?.shipping?.email || '';

  return (
    <div className="pt-32 pb-24 px-4 max-w-2xl mx-auto text-center space-y-6">
      <div className="w-20 h-20 bg-primary-container/20 text-primary-container rounded-full flex items-center justify-center mx-auto border border-primary-container/40">
        <span className="material-symbols-outlined text-4xl">{paid ? 'check_circle' : 'hourglass_top'}</span>
      </div>
      <h1 className="text-3xl font-bold text-text-primary font-serif">
        {paid ? 'Alhamdulillah! Order Confirmed' : 'Confirming your payment…'}
      </h1>
      <p className="text-text-secondary text-sm">
        {paid
          ? <>Thank you for shopping with Sunnah Grandeur.{email && <> A confirmation email is on its way to <strong className="text-text-primary">{email}</strong>.</>}</>
          : 'This usually takes a few seconds. Please keep this page open.'}
        {orderId && <><br />Order number: <span className="font-mono font-bold text-primary-container text-base">{orderId}</span></>}
      </p>

      {order && (
        <div className="p-6 bg-surface-card border border-border-subtle rounded-xl text-left space-y-3 text-xs">
          <div className="flex justify-between border-b border-border-subtle pb-2">
            <span className="text-text-secondary">Status</span>
            <span className="text-emerald-400 font-semibold uppercase tracking-wider">{order.status === 'pending_payment' ? 'Awaiting payment confirmation' : order.status}</span>
          </div>
          <div className="flex justify-between"><span className="text-text-secondary">Subtotal</span><span className="text-text-primary">{formatUsdFromCents(order.subtotalInCents)}</span></div>
          <div className="flex justify-between"><span className="text-text-secondary">Shipping</span><span className="text-emerald-400">FREE</span></div>
          <div className="flex justify-between"><span className="text-text-secondary">Sales tax</span><span className="text-text-primary">{formatUsdFromCents(order.taxInCents)}</span></div>
          <div className="flex justify-between border-t border-border-subtle pt-2"><span className="text-text-secondary">Total paid</span><span className="text-primary-container font-bold text-sm">{formatUsdFromCents(order.totalInCents)}</span></div>
          <p className="text-text-secondary pt-2">Estimated delivery: 3–7 business days after shipment. Need to cancel? You can do it any time before it ships from <Link href="/account?tab=orders" className="text-primary-container underline">My Orders</Link>.</p>
        </div>
      )}

      {user?.isAnonymous && !upgraded && email && (
        <div className="p-6 bg-surface-card border border-primary-container/30 rounded-xl text-left space-y-3">
          <h3 className="text-text-primary font-bold text-sm">Create an account to track or cancel this order anywhere</h3>
          <p className="text-text-secondary text-xs">We&apos;ll use <span className="text-text-primary font-semibold">{email}</span>. Just set a password.</p>
          {upgradeError && <p className="text-red-400 text-xs">{upgradeError}</p>}
          <form
            onSubmit={async (e) => {
              e.preventDefault();
              setBusy(true);
              setUpgradeError('');
              try {
                await linkGuestAccount(email, password, order?.shipping?.name || '');
                setUpgraded(true);
              } catch (err: any) {
                setUpgradeError(err?.code?.includes('email-already-in-use')
                  ? 'An account with this email already exists — sign in from the account menu instead.'
                  : 'Could not create your account right now. Please try again.');
              } finally { setBusy(false); }
            }}
            className="flex flex-col sm:flex-row gap-2"
          >
            <input type="password" required minLength={6} value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Set a password"
              className="flex-1 bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-sm text-text-primary focus:border-primary-container focus:outline-none" />
            <button type="submit" disabled={busy} className="bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest px-5 py-2.5 rounded hover:bg-[#e6c364] disabled:opacity-50 whitespace-nowrap">
              {busy ? 'Creating...' : 'Create Account'}
            </button>
          </form>
        </div>
      )}
      {upgraded && <p className="text-emerald-400 text-sm font-semibold">✓ Account created! Sign in with {email} anytime.</p>}

      <Link href="/shop" className="inline-block bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest px-8 py-3.5 rounded hover:bg-[#e6c364] transition-colors">
        Continue Shopping
      </Link>
    </div>
  );
}

export default function CheckoutSuccessPage() {
  return <Suspense fallback={null}><SuccessContent /></Suspense>;
}
