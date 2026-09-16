"use client";

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useCartStore } from '@/store/useCartStore';
import { httpsCallable } from 'firebase/functions';
import { signInAnonymously, updateProfile } from 'firebase/auth';
import { auth, functions } from '@/lib/firebase';
import { useAuth } from '@/context/AuthContext';
import { useCurrency } from '@/context/CurrencyContext';
import { formatUsd, formatUsdFromCents } from '@/lib/currency';

const US_STATES = [
  'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA',
  'KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
  'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT',
  'VA','WA','WV','WI','WY','DC',
];

export default function CheckoutPage() {
  const { items, getSubtotal, clearCart } = useCartStore();
  const { user, linkGuestAccount } = useAuth();
  const { usdRate } = useCurrency();

  // Estimate shown before the order is placed. The Cloud Function computes
  // the authoritative total server-side from real settings — this estimate
  // is replaced by that authoritative figure the moment the order confirms.
  const subtotal = getSubtotal();
  const estimatedTax = Math.round(subtotal * 0.0 /* no live per-state tax engine yet */);
  const total = subtotal + estimatedTax;

  // Form state
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [address, setAddress] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('NY');
  const [postalCode, setPostalCode] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [orderConfirmed, setOrderConfirmed] = useState<{ id: string; trackingCode: string; totalInCents: number } | null>(null);
  const [wasGuest, setWasGuest] = useState(false);
  const [upgradePassword, setUpgradePassword] = useState('');
  const [upgradeError, setUpgradeError] = useState('');
  const [upgradeSuccess, setUpgradeSuccess] = useState(false);
  const [upgrading, setUpgrading] = useState(false);

  // A signed-in customer shouldn't have to retype what we already know.
  // Anonymous/guest users (auth.currentUser but no real email) get no prefill.
  useEffect(() => {
    if (!user || user.isAnonymous) return;
    if (user.email) setEmail((prev) => prev || user.email!);
    if (user.displayName) setFullName((prev) => prev || user.displayName!);
  }, [user]);

  // Cash on Delivery — the only payment method wired up right now. Card
  // checkout is deferred until live Stripe keys are available.
  const handleSubmitCOD = async (e: React.FormEvent) => {
    e.preventDefault();
    if (items.length === 0) return;

    setIsSubmitting(true);
    setErrorMsg(null);

    try {
      // Firestore rules forbid direct client writes to /orders — order
      // creation must go through the createOrder Cloud Function, which
      // prices the order server-side and is the only thing allowed to
      // write the document.
      if (!auth.currentUser) {
        await signInAnonymously(auth);
      }
      setWasGuest(!!auth.currentUser?.isAnonymous);
      // Populate the session's display name from the checkout form so
      // "Signed in as" and the Profile tab aren't blank for guest orders —
      // anonymous users can have a displayName, just not an email/password.
      if (auth.currentUser?.isAnonymous && fullName) {
        await updateProfile(auth.currentUser, { displayName: fullName });
      }

      const createOrder = httpsCallable(functions, 'createOrder');
      const result: any = await createOrder({
        items: items.map((i) => ({ productId: i.id, quantity: i.quantity })),
        shipping: {
          name: fullName,
          phone,
          email: email || '',
          line1: address,
          city,
          state,
          postalCode: postalCode || '00000',
          country: 'US',
          method: 'standard',
        },
        paymentMethod: 'cod',
      });

      const { orderId, totalInCents } = result.data as { orderId: string; totalInCents: number };
      setOrderConfirmed({ id: orderId, trackingCode: orderId, totalInCents });
      clearCart();
    } catch (error: any) {
      console.error('Error placing order:', error);
      setErrorMsg(
        error?.message ||
          'Could not place your order — please check your details and try again.'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  if (orderConfirmed) {
    return (
      <div className="pt-32 pb-24 px-4 max-w-2xl mx-auto text-center space-y-6">
        <div className="w-20 h-20 bg-primary-container/20 text-primary-container rounded-full flex items-center justify-center mx-auto border border-primary-container/40 animate-in zoom-in">
          <span className="material-symbols-outlined text-4xl">check_circle</span>
        </div>
        <h1 className="text-3xl font-bold text-text-primary font-serif">Alhamdulillah! Order Placed</h1>
        <p className="text-text-secondary text-sm">
          Thank you for shopping with Sunnah Grandeur. Your order reference is{' '}
          <span className="font-mono font-bold text-primary-container text-base">{orderConfirmed.trackingCode}</span>.
        </p>

        <div className="p-6 bg-surface-card border border-border-subtle rounded-xl text-left space-y-3 text-xs">
          <div className="flex justify-between border-b border-border-subtle pb-2">
            <span className="text-text-secondary">Delivery Status</span>
            <span className="text-emerald-400 font-semibold uppercase tracking-wider">Processing</span>
          </div>
          <div className="flex justify-between">
            <span className="text-text-secondary">Payment Method</span>
            <span className="text-text-primary uppercase font-medium">Cash on Delivery</span>
          </div>
          <div className="flex justify-between">
            <span className="text-text-secondary">Total Amount</span>
            <span className="text-primary-container font-bold text-sm">{formatUsdFromCents(orderConfirmed.totalInCents)}</span>
          </div>
        </div>

        {wasGuest && (
          <div className="p-6 bg-surface-card border border-primary-container/30 rounded-xl text-left space-y-3">
            {upgradeSuccess ? (
              <p className="text-emerald-400 text-sm font-semibold text-center">
                ✓ Account created! You can now sign in with {email} anytime to track this order.
              </p>
            ) : (
              <>
                <h3 className="text-text-primary font-bold text-sm">Create an account to track this order anywhere</h3>
                <p className="text-text-secondary text-xs">
                  We&apos;ll use <span className="text-text-primary font-semibold">{email || 'the email you provided'}</span>.
                  Just set a password below — no need to retype anything.
                </p>
                {upgradeError && <p className="text-red-400 text-xs">{upgradeError}</p>}
                <form
                  onSubmit={async (e) => {
                    e.preventDefault();
                    if (!email) {
                      setUpgradeError('Please provide an email above before creating an account.');
                      return;
                    }
                    setUpgrading(true);
                    setUpgradeError('');
                    try {
                      await linkGuestAccount(email, upgradePassword, fullName);
                      setUpgradeSuccess(true);
                    } catch (err: any) {
                      setUpgradeError(err?.code?.includes('email-already-in-use')
                        ? 'An account with this email already exists — sign in from the account menu instead.'
                        : 'Could not create your account right now. Please try again.');
                    } finally {
                      setUpgrading(false);
                    }
                  }}
                  className="flex flex-col sm:flex-row gap-2"
                >
                  <input
                    type="password"
                    required
                    minLength={6}
                    value={upgradePassword}
                    onChange={(e) => setUpgradePassword(e.target.value)}
                    placeholder="Set a password"
                    className="flex-1 bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-sm text-text-primary focus:border-primary-container focus:outline-none"
                  />
                  <button
                    type="submit"
                    disabled={upgrading}
                    className="bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest px-5 py-2.5 rounded hover:bg-[#e6c364] transition-colors disabled:opacity-50 whitespace-nowrap"
                  >
                    {upgrading ? 'Creating...' : 'Create Account'}
                  </button>
                </form>
              </>
            )}
          </div>
        )}

        <div className="pt-4">
          <Link
            href="/shop"
            className="inline-block bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest px-8 py-3.5 rounded hover:bg-[#e6c364] transition-colors"
          >
            Return to Storefront
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-grow pt-32 pb-section-padding px-gutter max-w-container-max mx-auto w-full">
      <h1 className="text-headline-xl font-headline-xl text-primary mb-8 font-serif">Checkout &amp; Payment</h1>

      {errorMsg && (
        <div className="mb-6 p-4 bg-red-500/10 border border-red-500/30 rounded-lg text-red-400 text-xs font-semibold text-center">
          {errorMsg}
        </div>
      )}

      {items.length === 0 ? (
        <div className="text-center py-16 bg-surface-card rounded-xl border border-border-subtle">
          <p className="text-text-secondary text-sm mb-4">Your cart is empty.</p>
          <Link href="/shop" className="text-primary-container font-bold hover:underline text-xs uppercase tracking-widest">
            ➔ Browse Products
          </Link>
        </div>
      ) : (
        <form onSubmit={handleSubmitCOD} className="grid grid-cols-1 lg:grid-cols-12 gap-12">
          {/* Shipping & Payment Options */}
          <div className="lg:col-span-7 space-y-8">
            {/* 1. Contact Information */}
            <div className="bg-surface-card border border-border-subtle p-6 rounded-xl space-y-4">
              <h2 className="text-headline-md text-primary font-bold flex items-center gap-2 text-base">
                <span className="material-symbols-outlined text-primary-container">local_shipping</span>
                1. Shipping Information
              </h2>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                <div>
                  <label className="text-text-secondary uppercase font-bold text-[10px] block mb-1">Full Name *</label>
                  <input
                    type="text"
                    required
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    placeholder="Ahmed Al-Mansour"
                    className="w-full bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                  />
                </div>
                <div>
                  <label className="text-text-secondary uppercase font-bold text-[10px] block mb-1">Phone Number *</label>
                  <input
                    type="tel"
                    required
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="+1 (212) 555-0100"
                    className="w-full bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                  />
                </div>
                <div className="sm:col-span-2">
                  <label className="text-text-secondary uppercase font-bold text-[10px] block mb-1">Shipping Address *</label>
                  <input
                    type="text"
                    required
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    placeholder="3715 73rd St, Suite 205"
                    className="w-full bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                  />
                </div>
                <div>
                  <label className="text-text-secondary uppercase font-bold text-[10px] block mb-1">City *</label>
                  <input
                    type="text"
                    required
                    value={city}
                    onChange={(e) => setCity(e.target.value)}
                    placeholder="Jackson Heights"
                    className="w-full bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                  />
                </div>
                <div>
                  <label className="text-text-secondary uppercase font-bold text-[10px] block mb-1">State *</label>
                  <select
                    value={state}
                    onChange={(e) => setState(e.target.value)}
                    className="w-full bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                  >
                    {US_STATES.map((abbr) => (
                      <option key={abbr} value={abbr}>{abbr}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-text-secondary uppercase font-bold text-[10px] block mb-1">ZIP Code *</label>
                  <input
                    type="text"
                    required
                    value={postalCode}
                    onChange={(e) => setPostalCode(e.target.value)}
                    placeholder="11372"
                    className="w-full bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                  />
                </div>
                <div>
                  <label className="text-text-secondary uppercase font-bold text-[10px] block mb-1">Email Address</label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    className="w-full bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                  />
                </div>
              </div>
            </div>

            {/* 2. Payment Method */}
            <div className="bg-surface-card border border-border-subtle p-6 rounded-xl space-y-4">
              <h2 className="text-headline-md text-primary font-bold flex items-center gap-2 text-base">
                <span className="material-symbols-outlined text-primary-container">payments</span>
                2. Select Payment Method
              </h2>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <label
                  className="p-4 rounded-lg border border-border-subtle opacity-50 cursor-not-allowed flex items-center gap-3"
                  title="Card payments are coming soon."
                >
                  <input type="radio" name="payment" checked={false} disabled onChange={() => {}} className="accent-amber-500" />
                  <div>
                    <p className="font-semibold text-sm text-text-primary">Stripe Credit / Debit Card</p>
                    <p className="text-xs text-text-secondary">Coming soon</p>
                  </div>
                </label>

                <label className="p-4 rounded-lg border border-primary-container bg-primary-container/10 flex items-center gap-3">
                  <input type="radio" name="payment" checked readOnly className="accent-amber-500" />
                  <div>
                    <p className="font-semibold text-sm text-text-primary">Cash on Delivery</p>
                    <p className="text-xs text-text-secondary">Pay upon package arrival</p>
                  </div>
                </label>
              </div>
            </div>
          </div>

          {/* Right Column: Summary & Checkout Button */}
          <div className="lg:col-span-5">
            <div className="sticky top-28 bg-surface-card rounded-xl border border-border-subtle p-8 shadow-xl space-y-6">
              <h2 className="text-headline-lg font-headline-lg text-primary border-b border-border-subtle pb-4 font-bold text-lg">
                Order Items ({items.length})
              </h2>

              <div className="max-h-60 overflow-y-auto space-y-3 pr-2 border-b border-border-subtle pb-4">
                {items.map((i) => (
                  <div key={i.id} className="flex justify-between items-center text-xs">
                    <div>
                      <p className="font-bold text-text-primary">{i.name}</p>
                      <p className="text-[10px] text-text-secondary">Qty: {i.quantity}</p>
                    </div>
                    <span className="font-mono font-semibold text-primary-container">{formatUsd(i.price * i.quantity, usdRate)}</span>
                  </div>
                ))}
              </div>

              <div className="space-y-2 text-xs">
                <div className="flex justify-between">
                  <span className="text-text-secondary">Subtotal</span>
                  <span className="text-text-primary font-semibold">{formatUsd(subtotal, usdRate)}</span>
                </div>
                <p className="text-[10px] text-text-secondary/70 -mt-1">Tax and any shipping fee are calculated at checkout confirmation.</p>
                <div className="flex justify-between text-sm font-bold pt-2 border-t border-border-subtle">
                  <span className="text-text-primary">Estimated Total</span>
                  <span className="text-primary-container">{formatUsd(total, usdRate)}</span>
                </div>
              </div>

              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full bg-primary-container text-bg-primary py-4 rounded-lg font-bold text-xs uppercase tracking-widest hover:bg-[#e6c364] transition-all duration-300 shadow-lg disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {isSubmitting ? (
                  <span>Placing Order...</span>
                ) : (
                  <>
                    <span>Place COD Order</span>
                    <span className="material-symbols-outlined text-sm">check</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </form>
      )}
    </div>
  );
}
