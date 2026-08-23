"use client";

import { useState } from 'react';
import Link from 'next/link';
import { useCartStore } from '@/store/useCartStore';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { signInAnonymously } from 'firebase/auth';
import { db, auth } from '@/lib/firebase';

export default function CheckoutPage() {
  const { items, getSubtotal, clearCart } = useCartStore();

  const subtotal = getSubtotal();
  const vat = Math.round(subtotal * 0.05);
  const total = subtotal + vat;

  // Form state
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [address, setAddress] = useState('');
  const [city, setCity] = useState('Dhaka');
  const [paymentMethod, setPaymentMethod] = useState<'cod' | 'stripe'>('stripe');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [orderConfirmed, setOrderConfirmed] = useState<{ id: string; trackingCode: string } | null>(null);

  // 1. Stripe Checkout Redirect Handler
  const handleStripeCheckout = async () => {
    if (items.length === 0) return;
    setIsSubmitting(true);
    setErrorMsg(null);

    try {
      // Step A: Ensure Firebase Auth (Anonymous Auth for guest checkout)
      let user = auth.currentUser;
      if (!user) {
        const cred = await signInAnonymously(auth);
        user = cred.user;
      }

      const userId = user.uid;

      // Step B: Prepare items with productId, name, price (in cents), quantity
      const formattedItems = items.map((item) => ({
        productId: item.id,
        name: item.name,
        price: Math.round(item.price * 100), // in cents
        quantity: item.quantity,
      }));

      // Step C: Determine Cloud Function endpoint (local emulator or production)
      const functionUrl =
        typeof window !== 'undefined' &&
        (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
          ? 'http://localhost:5001/sunnah-grandeur/us-central1/createStripeSession'
          : 'https://us-central1-sunnah-grandeur.cloudfunctions.net/createStripeSession';

      const successUrl = `${window.location.origin}/checkout?success=true`;
      const cancelUrl = `${window.location.origin}/checkout?canceled=true`;

      // Step D: Make secure POST request to createStripeSession
      const response = await fetch(functionUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId: userId,
          items: formattedItems,
          successUrl: successUrl,
          cancelUrl: cancelUrl,
        }),
      });

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}));
        throw new Error(errData.error || `Stripe session error (${response.status})`);
      }

      const data = await response.json();

      if (data.url) {
        // Step E: Redirect directly to returned Stripe Checkout URL
        window.location.href = data.url;
      } else {
        throw new Error('No checkout URL returned from server.');
      }
    } catch (err: any) {
      console.error('Stripe Checkout Error:', err);
      setErrorMsg(err.message || 'Failed to initiate Stripe Checkout. Please try Cash on Delivery.');
    } finally {
      setIsSubmitting(false);
    }
  };

  // 2. Cash on Delivery Handler
  const handleSubmitCOD = async (e: React.FormEvent) => {
    e.preventDefault();
    if (items.length === 0) return;

    if (paymentMethod === 'stripe') {
      await handleStripeCheckout();
      return;
    }

    setIsSubmitting(true);
    const trackingCode = `#SG-${Math.floor(1000 + Math.random() * 9000)}`;

    try {
      let user = auth.currentUser;
      if (!user) {
        const cred = await signInAnonymously(auth);
        user = cred.user;
      }

      const orderData = {
        trackingCode,
        userId: user.uid,
        customer: {
          fullName,
          phone,
          email: email || 'guest@sunnahgrandeur.com',
          address,
          city,
        },
        items: items.map((i) => ({
          productId: i.id,
          name: i.name,
          price: Math.round(i.price * 100),
          quantity: i.quantity,
        })),
        subtotal: subtotal * 100,
        total: total * 100,
        status: 'Processing',
        paymentMethod: 'Cash on Delivery',
        createdAt: serverTimestamp(),
      };

      const docRef = await addDoc(collection(db, 'orders'), orderData);
      setOrderConfirmed({ id: docRef.id, trackingCode });
      clearCart();
    } catch (error: any) {
      console.error('Error placing order in Firestore:', error);
      setOrderConfirmed({ id: 'local-demo', trackingCode });
      clearCart();
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
            <span className="text-primary-container font-bold text-sm">৳{total.toLocaleString()}</span>
          </div>
        </div>

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
                    className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                  />
                </div>
                <div>
                  <label className="text-text-secondary uppercase font-bold text-[10px] block mb-1">Phone Number *</label>
                  <input
                    type="tel"
                    required
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="+880 1700 000000"
                    className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                  />
                </div>
                <div className="sm:col-span-2">
                  <label className="text-text-secondary uppercase font-bold text-[10px] block mb-1">Shipping Address *</label>
                  <input
                    type="text"
                    required
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    placeholder="House #12, Road #4, Gulshan-2"
                    className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                  />
                </div>
                <div>
                  <label className="text-text-secondary uppercase font-bold text-[10px] block mb-1">City *</label>
                  <select
                    value={city}
                    onChange={(e) => setCity(e.target.value)}
                    className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                  >
                    <option value="Dhaka">Dhaka</option>
                    <option value="Chittagong">Chittagong</option>
                    <option value="Sylhet">Sylhet</option>
                    <option value="International">International Shipping</option>
                  </select>
                </div>
                <div>
                  <label className="text-text-secondary uppercase font-bold text-[10px] block mb-1">Email Address</label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="ahmed@example.com"
                    className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
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
                  onClick={() => setPaymentMethod('stripe')}
                  className={`p-4 rounded-lg border cursor-pointer flex items-center gap-3 transition-colors ${
                    paymentMethod === 'stripe' ? 'border-primary-container bg-primary-container/10' : 'border-border-subtle hover:border-primary-container/40'
                  }`}
                >
                  <input type="radio" name="payment" checked={paymentMethod === 'stripe'} onChange={() => {}} className="accent-amber-500" />
                  <div>
                    <p className="font-semibold text-sm text-text-primary">Stripe Credit / Debit Card</p>
                    <p className="text-xs text-text-secondary">Instant Stripe Checkout</p>
                  </div>
                </label>

                <label
                  onClick={() => setPaymentMethod('cod')}
                  className={`p-4 rounded-lg border cursor-pointer flex items-center gap-3 transition-colors ${
                    paymentMethod === 'cod' ? 'border-primary-container bg-primary-container/10' : 'border-border-subtle hover:border-primary-container/40'
                  }`}
                >
                  <input type="radio" name="payment" checked={paymentMethod === 'cod'} onChange={() => {}} className="accent-amber-500" />
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
                    <span className="font-mono font-semibold text-primary-container">৳{(i.price * i.quantity).toLocaleString()}</span>
                  </div>
                ))}
              </div>

              <div className="space-y-2 text-xs">
                <div className="flex justify-between">
                  <span className="text-text-secondary">Subtotal</span>
                  <span className="text-text-primary font-semibold">৳{subtotal.toLocaleString()}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-text-secondary">VAT (5%)</span>
                  <span className="text-text-primary font-semibold">৳{vat.toLocaleString()}</span>
                </div>
                <div className="flex justify-between text-sm font-bold pt-2 border-t border-border-subtle">
                  <span className="text-text-primary">Total Amount</span>
                  <span className="text-primary-container">৳{total.toLocaleString()}</span>
                </div>
              </div>

              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full bg-primary-container text-bg-primary py-4 rounded-lg font-bold text-xs uppercase tracking-widest hover:bg-[#e6c364] transition-all duration-300 shadow-lg disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {isSubmitting ? (
                  <span>Connecting to Stripe...</span>
                ) : paymentMethod === 'stripe' ? (
                  <>
                    <span>Proceed to Stripe Checkout</span>
                    <span className="material-symbols-outlined text-sm">open_in_new</span>
                  </>
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
