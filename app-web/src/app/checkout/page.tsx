"use client";

import { useState, useEffect, useRef, useMemo } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { loadStripe } from '@stripe/stripe-js';
import { Elements, PaymentElement, useStripe, useElements } from '@stripe/react-stripe-js';
import { useCartStore } from '@/store/useCartStore';
import { httpsCallable } from 'firebase/functions';
import { signInAnonymously, updateProfile } from 'firebase/auth';
import { auth, functions } from '@/lib/firebase';
import { useAuth } from '@/context/AuthContext';
import { useCurrency } from '@/context/CurrencyContext';
import { formatUsd, formatUsdFromCents } from '@/lib/currency';
import { validateCheckout, formatUsPhone, type CheckoutFields } from '@/lib/checkoutValidation';

const US_STATES = [
  'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA',
  'KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
  'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT',
  'VA','WA','WV','WI','WY','DC',
];

const STRIPE_KEY = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY || '';
const PAYPAL_CLIENT_ID = process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID || '';
const stripePromise = STRIPE_KEY ? loadStripe(STRIPE_KEY) : null;

type Quote = { subtotalInCents: number; taxInCents: number; shippingInCents: number; totalInCents: number };
type PendingOrder = Quote & { orderId: string; clientSecret: string };

const inputCls =
  'w-full bg-bg-primary border rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none';
const labelCls = 'text-text-secondary uppercase font-bold text-[10px] block mb-1';

function friendlyError(err: any, fallback: string): string {
  const msg: string = err?.message || '';
  // Firebase wraps server messages like "FirebaseError: Message (functions/...)".
  return msg.replace(/^.*?:\s*/, '').replace(/\s*\(functions\/[\w-]+\)\.?$/, '') || fallback;
}

/* ── Stripe card / wallet form (rendered inside <Elements>) ───────────────── */
function StripePayForm({ orderId, totalInCents, onError }: { orderId: string; totalInCents: number; onError: (m: string | null) => void }) {
  const stripe = useStripe();
  const elements = useElements();
  const router = useRouter();
  const [busy, setBusy] = useState(false);

  const pay = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!stripe || !elements) return;
    setBusy(true);
    onError(null);
    const { error } = await stripe.confirmPayment({
      elements,
      confirmParams: { return_url: `${window.location.origin}/checkout/success/?order=${encodeURIComponent(orderId)}` },
      redirect: 'if_required',
    });
    if (error) {
      onError(`${error.message || 'Your payment could not be completed.'} You have not been charged — please check your details or try another payment method.`);
      setBusy(false);
      return;
    }
    router.push(`/checkout/success/?order=${encodeURIComponent(orderId)}`);
  };

  return (
    <form onSubmit={pay} className="space-y-4">
      <PaymentElement options={{ layout: 'tabs', defaultValues: { billingDetails: { address: { country: 'US' } } } }} />
      <button
        type="submit"
        disabled={!stripe || busy}
        className="w-full bg-primary-container text-bg-primary py-4 rounded-lg font-bold text-xs uppercase tracking-widest hover:bg-[#e6c364] transition-all disabled:opacity-50"
      >
        {busy ? 'Processing payment…' : `Pay ${formatUsdFromCents(totalInCents)}`}
      </button>
    </form>
  );
}

/* ── PayPal + Venmo buttons ───────────────────────────────────────────────── */
declare global { interface Window { paypal?: any } }

function PayPalButtons({ orderId, onError }: { orderId: string; onError: (m: string | null) => void }) {
  const ref = useRef<HTMLDivElement>(null);
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!PAYPAL_CLIENT_ID) return;
    let cancelled = false;
    const render = () => {
      if (cancelled || !ref.current || !window.paypal) return;
      ref.current.replaceChildren();
      const funding = [window.paypal.FUNDING.PAYPAL, window.paypal.FUNDING.VENMO];
      funding.forEach((fundingSource: any) => {
        const btn = window.paypal.Buttons({
          fundingSource,
          style: { layout: 'vertical', shape: 'rect', height: 44 },
          createOrder: async () => {
            const r: any = await httpsCallable(functions, 'createPaypalOrder')({ orderId });
            return r.data.paypalOrderId;
          },
          onApprove: async (data: any) => {
            try {
              await httpsCallable(functions, 'capturePaypalOrder')({ orderId, paypalOrderId: data.orderID });
              router.push(`/checkout/success/?order=${encodeURIComponent(orderId)}`);
            } catch (err: any) {
              onError(friendlyError(err, 'PayPal payment was not completed. You have not been charged.'));
            }
          },
          onCancel: () => onError('Payment cancelled — you have not been charged. You can try again below.'),
          onError: () => onError('PayPal could not complete the payment. You have not been charged — please try again or use a card.'),
        });
        if (btn.isEligible()) btn.render(ref.current!);
      });
      setReady(true);
    };
    if (window.paypal) {
      render();
    } else {
      const s = document.createElement('script');
      s.src = `https://www.paypal.com/sdk/js?client-id=${encodeURIComponent(PAYPAL_CLIENT_ID)}&currency=USD&intent=capture&components=buttons&enable-funding=venmo`;
      s.async = true;
      s.onload = render;
      s.onerror = () => onError('Could not load PayPal. Please use a card instead.');
      document.body.appendChild(s);
    }
    return () => { cancelled = true; };
  }, [orderId, onError, router]);

  if (!PAYPAL_CLIENT_ID) return null;
  return (
    <div className="space-y-2">
      <p className="text-[11px] text-text-secondary uppercase tracking-widest font-bold">Or pay with PayPal / Venmo</p>
      <div ref={ref} className="min-h-[44px]" />
      {!ready && <p className="text-[11px] text-text-secondary">Loading PayPal…</p>}
    </div>
  );
}

/* ── Page ─────────────────────────────────────────────────────────────────── */
export default function CheckoutPage() {
  const { items, getSubtotal } = useCartStore();
  const { user } = useAuth();
  const { usdRate } = useCurrency();
  const subtotal = getSubtotal();

  const [f, setF] = useState<CheckoutFields>({
    fullName: '', phone: '', email: '', address: '', city: '', state: 'NY', postalCode: '',
  });
  const [touched, setTouched] = useState<Record<string, boolean>>({});
  const [submitted, setSubmitted] = useState(false);
  const [quote, setQuote] = useState<Quote | null>(null);
  const [quoting, setQuoting] = useState(false);
  const [pending, setPending] = useState<PendingOrder | null>(null);
  const [creating, setCreating] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const requestId = useRef<string>('');

  const set = (k: keyof CheckoutFields) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
    setF((p) => ({ ...p, [k]: e.target.value }));
  const blur = (k: string) => () => setTouched((p) => ({ ...p, [k]: true }));

  const errors = useMemo(() => validateCheckout(f), [f]);
  const err = (k: keyof CheckoutFields) => (touched[k] || submitted ? errors[k] : undefined);
  const locked = !!pending;

  useEffect(() => {
    if (!user || user.isAnonymous) return;
    if (user.email) setF((p) => ({ ...p, email: p.email || user.email! }));
    if (user.displayName) setF((p) => ({ ...p, fullName: p.fullName || user.displayName! }));
  }, [user]);

  // Live tax quote by ZIP/state (free shipping on all US orders).
  const cartKey = items.map((i) => `${i.id}:${i.quantity}`).join(',');
  useEffect(() => {
    if (errors.postalCode || errors.state || items.length === 0) { setQuote(null); return; }
    let live = true;
    setQuoting(true);
    const t = setTimeout(async () => {
      try {
        if (!auth.currentUser) await signInAnonymously(auth);
        const r: any = await httpsCallable(functions, 'quoteOrder')({
          items: items.map((i) => ({ productId: i.id, quantity: i.quantity })),
          shipping: { line1: f.address, city: f.city, state: f.state, postalCode: f.postalCode },
        });
        if (live) setQuote(r.data as Quote);
      } catch {
        if (live) setQuote(null);
      } finally {
        if (live) setQuoting(false);
      }
    }, 500);
    return () => { live = false; clearTimeout(t); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [f.postalCode, f.state, cartKey]);

  const continueToPayment = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
    setErrorMsg(null);
    if (Object.keys(errors).length > 0) {
      setErrorMsg('Please fix the highlighted fields before continuing.');
      return;
    }
    if (items.length === 0) return;
    if (!stripePromise) {
      setErrorMsg('Card payments are temporarily unavailable. Please try again later.');
      return;
    }

    setCreating(true);
    try {
      if (!auth.currentUser) await signInAnonymously(auth);
      if (auth.currentUser?.isAnonymous && f.fullName) {
        await updateProfile(auth.currentUser, { displayName: f.fullName });
      }
      if (!requestId.current) requestId.current = crypto.randomUUID();

      const created: any = await httpsCallable(functions, 'createOrder')({
        items: items.map((i) => ({ productId: i.id, quantity: i.quantity })),
        shipping: {
          name: f.fullName.trim(), phone: f.phone, email: f.email.trim(),
          line1: f.address.trim(), city: f.city.trim(), state: f.state,
          postalCode: f.postalCode.trim(), country: 'US', method: 'standard',
        },
        paymentMethod: 'card',
        requestId: requestId.current,
      });
      const o = created.data as Quote & { orderId: string };

      // Payment always happens on this page (Stripe Payment Element) — the
      // customer is never sent to another site.
      const intent: any = await httpsCallable(functions, 'createPaymentIntent')({ orderId: o.orderId });
      setPending({ ...o, clientSecret: intent.data.clientSecret });
    } catch (error: any) {
      requestId.current = '';
      setErrorMsg(friendlyError(error, 'Could not place your order — please check your details and try again.'));
    } finally {
      setCreating(false);
    }
  };

  // Editing details after the order was reserved: release it, start fresh.
  const editDetails = async () => {
    if (pending) {
      try { await httpsCallable(functions, 'cancelOrder')({ orderId: pending.orderId }); } catch { /* cron releases it */ }
    }
    requestId.current = '';
    setPending(null);
    setErrorMsg(null);
  };

  const shown = pending ?? quote;
  const total = shown ? shown.totalInCents : null;

  return (
    <div className="flex-grow pt-32 pb-section-padding px-gutter max-w-container-max mx-auto w-full">
      <h1 className="text-headline-xl font-headline-xl text-primary mb-2 font-serif">Checkout &amp; Payment</h1>
      <p className="text-xs text-text-secondary mb-8">Free shipping on all US orders · Delivered in 3–7 business days · Sales tax calculated from your ZIP code</p>

      {errorMsg && (
        <div role="alert" className="mb-6 p-4 bg-red-500/10 border border-red-500/30 rounded-lg text-red-400 text-xs font-semibold text-center">
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
        <form onSubmit={continueToPayment} noValidate className="grid grid-cols-1 lg:grid-cols-12 gap-12">
          <div className="lg:col-span-7 space-y-8">
            {/* 1. Shipping */}
            <div className="bg-surface-card border border-border-subtle p-6 rounded-xl space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="text-primary font-bold flex items-center gap-2 text-base">
                  <span className="material-symbols-outlined text-primary-container">local_shipping</span>
                  1. Shipping Information
                </h2>
                {locked && (
                  <button type="button" onClick={editDetails} className="text-[11px] text-primary-container uppercase font-bold tracking-widest hover:underline">
                    Edit details
                  </button>
                )}
              </div>
              <p className="text-[11px] text-text-secondary">We deliver within the United States only.</p>
              <fieldset disabled={locked} className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs disabled:opacity-60">
                <div>
                  <label className={labelCls} htmlFor="co-name">Full Name *</label>
                  <input id="co-name" autoComplete="name" value={f.fullName} onChange={set('fullName')} onBlur={blur('fullName')} placeholder="Ahmed Al-Mansour" className={`${inputCls} ${err('fullName') ? 'border-red-500' : 'border-border-subtle'}`} />
                  {err('fullName') && <p className="text-red-400 text-[11px] mt-1">{err('fullName')}</p>}
                </div>
                <div>
                  <label className={labelCls} htmlFor="co-phone">US Phone Number *</label>
                  <input id="co-phone" type="tel" inputMode="tel" autoComplete="tel" value={f.phone}
                    onChange={(e) => setF((p) => ({ ...p, phone: formatUsPhone(e.target.value) }))}
                    onBlur={blur('phone')} placeholder="(212) 555-0100" className={`${inputCls} ${err('phone') ? 'border-red-500' : 'border-border-subtle'}`} />
                  {err('phone') && <p className="text-red-400 text-[11px] mt-1">{err('phone')}</p>}
                </div>
                <div className="sm:col-span-2">
                  <label className={labelCls} htmlFor="co-email">Email Address *</label>
                  <input id="co-email" type="email" autoComplete="email" value={f.email} onChange={set('email')} onBlur={blur('email')} placeholder="you@example.com" className={`${inputCls} ${err('email') ? 'border-red-500' : 'border-border-subtle'}`} />
                  {err('email') && <p className="text-red-400 text-[11px] mt-1">{err('email')}</p>}
                </div>
                <div className="sm:col-span-2">
                  <label className={labelCls} htmlFor="co-address">Street Address *</label>
                  <input id="co-address" autoComplete="address-line1" value={f.address} onChange={set('address')} onBlur={blur('address')} placeholder="3715 73rd St, Suite 205" className={`${inputCls} ${err('address') ? 'border-red-500' : 'border-border-subtle'}`} />
                  {err('address') && <p className="text-red-400 text-[11px] mt-1">{err('address')}</p>}
                </div>
                <div>
                  <label className={labelCls} htmlFor="co-city">City *</label>
                  <input id="co-city" autoComplete="address-level2" value={f.city} onChange={set('city')} onBlur={blur('city')} placeholder="Jackson Heights" className={`${inputCls} ${err('city') ? 'border-red-500' : 'border-border-subtle'}`} />
                  {err('city') && <p className="text-red-400 text-[11px] mt-1">{err('city')}</p>}
                </div>
                <div>
                  <label className={labelCls} htmlFor="co-state">State *</label>
                  <select id="co-state" autoComplete="address-level1" value={f.state} onChange={set('state')} onBlur={blur('state')} className={`${inputCls} border-border-subtle`}>
                    {US_STATES.map((abbr) => <option key={abbr} value={abbr}>{abbr}</option>)}
                  </select>
                </div>
                <div>
                  <label className={labelCls} htmlFor="co-zip">ZIP Code *</label>
                  <input id="co-zip" inputMode="numeric" autoComplete="postal-code" maxLength={10} value={f.postalCode} onChange={set('postalCode')} onBlur={blur('postalCode')} placeholder="11372" className={`${inputCls} ${err('postalCode') ? 'border-red-500' : 'border-border-subtle'}`} />
                  {err('postalCode') && <p className="text-red-400 text-[11px] mt-1">{err('postalCode')}</p>}
                </div>
              </fieldset>
            </div>

            {/* 2. Payment */}
            <div className="bg-surface-card border border-border-subtle p-6 rounded-xl space-y-4">
              <h2 className="text-primary font-bold flex items-center gap-2 text-base">
                <span className="material-symbols-outlined text-primary-container">payments</span>
                2. Payment
              </h2>
              <p className="text-[11px] text-text-secondary flex items-center gap-1.5">
                <span className="material-symbols-outlined text-sm text-emerald-400">lock</span>
                Credit &amp; debit cards, Apple Pay, Google Pay, PayPal and Venmo. Payments are processed securely by Stripe and PayPal — we never see or store your card details.
              </p>

              {!pending ? (
                <div className="space-y-3">
                  <button
                    type="submit"
                    disabled={creating}
                    className="w-full bg-primary-container text-bg-primary py-4 rounded-lg font-bold text-xs uppercase tracking-widest hover:bg-[#e6c364] transition-all disabled:opacity-50"
                  >
                    {creating ? 'Reserving your order…' : 'Continue to Payment'}
                  </button>
                  <p className="text-[11px] text-text-secondary text-center">Your payment options appear here after your shipping details are confirmed.</p>
                </div>
              ) : (
                <div className="space-y-6">
                  {stripePromise && pending.clientSecret && (
                    <Elements stripe={stripePromise} options={{ clientSecret: pending.clientSecret, appearance: { theme: 'night', variables: { colorPrimary: '#e9c46a' } } }}>
                      <StripePayForm orderId={pending.orderId} totalInCents={pending.totalInCents} onError={setErrorMsg} />
                    </Elements>
                  )}
                  <PayPalButtons orderId={pending.orderId} onError={setErrorMsg} />
                  <p className="text-[11px] text-text-secondary leading-relaxed">
                    If a payment fails or is cancelled, you are <strong>not charged</strong> and your items stay reserved for 60 minutes so you can try again. After that the order is cancelled automatically.
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Summary */}
          <div className="lg:col-span-5">
            <div className="sticky top-28 bg-surface-card rounded-xl border border-border-subtle p-8 shadow-xl space-y-6">
              <h2 className="text-primary border-b border-border-subtle pb-4 font-bold text-lg">Order Items ({items.length})</h2>
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
                  <span className="text-text-primary font-semibold">{shown ? formatUsdFromCents(shown.subtotalInCents) : formatUsd(subtotal, usdRate)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-text-secondary">Shipping (US)</span>
                  <span className="text-emerald-400 font-semibold">FREE</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-text-secondary">Sales tax</span>
                  <span className="text-text-primary font-semibold">
                    {shown ? formatUsdFromCents(shown.taxInCents) : quoting ? 'Calculating…' : 'Enter ZIP code'}
                  </span>
                </div>
                <div className="flex justify-between text-sm font-bold pt-2 border-t border-border-subtle">
                  <span className="text-text-primary">{total !== null ? 'Total' : 'Subtotal'}</span>
                  <span className="text-primary-container">{total !== null ? formatUsdFromCents(total) : formatUsd(subtotal, usdRate)}</span>
                </div>
              </div>
            </div>
          </div>
        </form>
      )}
    </div>
  );
}
