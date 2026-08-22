"use client";

import { useState } from 'react';
import Link from 'next/link';
import { useCartStore } from '@/store/useCartStore';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

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
  const [paymentMethod, setPaymentMethod] = useState<'cod' | 'card'>('cod');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [orderConfirmed, setOrderConfirmed] = useState<{ id: string; trackingCode: string } | null>(null);

  const handleSubmitOrder = async (e: React.FormEvent) => {
    e.preventDefault();
    if (items.length === 0) return;

    setIsSubmitting(true);
    const trackingCode = `#SG-${Math.floor(1000 + Math.random() * 9000)}`;

    const orderData = {
      trackingCode,
      customer: {
        fullName,
        phone,
        email: email || 'guest@sunnahgrandeur.com',
        address,
        city,
      },
      items: items.map((i) => ({
        id: i.id,
        name: i.name,
        price: i.price,
        quantity: i.quantity,
        size: i.size || '',
      })),
      subtotal,
      vat,
      total,
      paymentMethod,
      status: 'Processing',
      createdAt: serverTimestamp(),
    };

    try {
      const docRef = await addDoc(collection(db, 'orders'), orderData);
      setOrderConfirmed({ id: docRef.id, trackingCode });
      clearCart();
    } catch (error) {
      console.error('Error placing order in Firestore:', error);
      // Local fallback for offline/demo mode
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
            <span className="text-text-primary uppercase font-medium">{paymentMethod === 'cod' ? 'Cash on Delivery' : 'Card Payment'}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-text-secondary">Total Amount Paid</span>
            <span className="text-primary-container font-bold text-sm">৳{total.toLocaleString()}</span>
          </div>
        </div>

        <div className="pt-4">
          <Link
            href="/shop"
            className="inline-block bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest px-8 py-3.5 rounded hover:bg-[#e6c364] transition-colors shadow-lg"
          >
            Continue Shopping
          </Link>
        </div>
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="pt-32 pb-24 text-center space-y-4">
        <h2 className="text-xl font-bold text-text-primary">Your cart is empty</h2>
        <p className="text-xs text-text-secondary">Please add items to your cart before proceeding to checkout.</p>
        <Link href="/shop" className="inline-block bg-primary-container text-bg-primary px-6 py-2.5 rounded text-xs font-bold uppercase">
          Return to Shop
        </Link>
      </div>
    );
  }

  return (
    <div className="pt-32 pb-24 px-gutter max-w-container-max mx-auto">
      <h1 className="text-3xl font-bold text-primary mb-2 font-serif">Checkout</h1>
      <p className="text-sm text-text-secondary mb-8">Enter your delivery information to complete your order.</p>

      <form onSubmit={handleSubmitOrder} className="grid grid-cols-1 lg:grid-cols-12 gap-12">
        {/* Left Column: Shipping Info & Payment */}
        <div className="lg:col-span-7 space-y-8">
          {/* Shipping Form */}
          <div className="bg-surface-card border border-border-subtle p-6 rounded-xl space-y-4">
            <h2 className="text-lg font-semibold text-text-primary border-b border-border-subtle pb-3 flex items-center gap-2">
              <span className="material-symbols-outlined text-primary-container">local_shipping</span>
              1. Delivery Information
            </h2>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              <div className="space-y-1">
                <label className="text-text-secondary uppercase font-bold tracking-wider">Full Name *</label>
                <input
                  type="text"
                  required
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="e.g. Tariq Ahmad"
                  className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                />
              </div>

              <div className="space-y-1">
                <label className="text-text-secondary uppercase font-bold tracking-wider">Phone Number *</label>
                <input
                  type="tel"
                  required
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="01700000000"
                  className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                />
              </div>

              <div className="col-span-full space-y-1">
                <label className="text-text-secondary uppercase font-bold tracking-wider">Email Address (Optional)</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="tariq@example.com"
                  className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                />
              </div>

              <div className="col-span-full space-y-1">
                <label className="text-text-secondary uppercase font-bold tracking-wider">Delivery Address *</label>
                <textarea
                  required
                  rows={2}
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="House/Apartment #, Road, Block/Area..."
                  className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                />
              </div>

              <div className="space-y-1">
                <label className="text-text-secondary uppercase font-bold tracking-wider">City / District *</label>
                <select
                  value={city}
                  onChange={(e) => setCity(e.target.value)}
                  className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-text-primary focus:border-primary-container focus:outline-none"
                >
                  <option value="Dhaka">Dhaka</option>
                  <option value="Chittagong">Chittagong</option>
                  <option value="Sylhet">Sylhet</option>
                  <option value="Rajshahi">Rajshahi</option>
                  <option value="Khulna">Khulna</option>
                </select>
              </div>
            </div>
          </div>

          {/* Payment Method */}
          <div className="bg-surface-card border border-border-subtle p-6 rounded-xl space-y-4">
            <h2 className="text-lg font-semibold text-text-primary border-b border-border-subtle pb-3 flex items-center gap-2">
              <span className="material-symbols-outlined text-primary-container">payments</span>
              2. Payment Method
            </h2>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <label
                onClick={() => setPaymentMethod('cod')}
                className={`p-4 rounded-lg border cursor-pointer flex items-center gap-3 transition-colors ${
                  paymentMethod === 'cod' ? 'border-primary-container bg-primary-container/10' : 'border-border-subtle hover:border-primary-container/40'
                }`}
              >
                <input type="radio" name="payment" checked={paymentMethod === 'cod'} onChange={() => {}} className="accent-amber-500" />
                <div>
                  <p className="font-semibold text-sm text-text-primary">Cash on Delivery</p>
                  <p className="text-xs text-text-secondary">Pay upon receiving your order</p>
                </div>
              </label>

              <label
                onClick={() => setPaymentMethod('card')}
                className={`p-4 rounded-lg border cursor-pointer flex items-center gap-3 transition-colors ${
                  paymentMethod === 'card' ? 'border-primary-container bg-primary-container/10' : 'border-border-subtle hover:border-primary-container/40'
                }`}
              >
                <input type="radio" name="payment" checked={paymentMethod === 'card'} onChange={() => {}} className="accent-amber-500" />
                <div>
                  <p className="font-semibold text-sm text-text-primary">Online Payment / Card</p>
                  <p className="text-xs text-text-secondary">Visa, Mastercard, bKash</p>
                </div>
              </label>
            </div>
          </div>
        </div>

        {/* Right Column: Order Summary */}
        <div className="lg:col-span-5">
          <div className="bg-surface-card border border-border-subtle p-6 rounded-xl space-y-4 sticky top-28 shadow-xl">
            <h2 className="text-lg font-semibold text-primary border-b border-border-subtle pb-3">Order Summary</h2>

            <div className="space-y-3 max-h-60 overflow-y-auto">
              {items.map((item) => (
                <div key={item.id} className="flex items-center gap-3 text-xs">
                  <img src={item.image} alt={item.name} className="w-12 h-12 object-cover rounded bg-surface border border-border-subtle" />
                  <div className="flex-grow min-w-0">
                    <p className="font-semibold text-text-primary truncate">{item.name}</p>
                    <p className="text-text-secondary">Qty: {item.quantity}</p>
                  </div>
                  <div className="font-bold text-primary-container">৳{(item.price * item.quantity).toLocaleString()}</div>
                </div>
              ))}
            </div>

            <div className="border-t border-border-subtle pt-4 space-y-2 text-xs">
              <div className="flex justify-between">
                <span className="text-text-secondary">Subtotal</span>
                <span className="text-text-primary">৳{subtotal.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-text-secondary">VAT (5%)</span>
                <span className="text-text-primary">৳{vat.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-text-secondary">Shipping</span>
                <span className="text-green-400 font-semibold">FREE</span>
              </div>
              <div className="border-t border-border-subtle pt-3 flex justify-between items-end text-sm font-bold">
                <span className="text-text-primary">Total Amount</span>
                <span className="text-primary-container text-lg">৳{total.toLocaleString()}</span>
              </div>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest py-4 rounded hover:bg-[#e6c364] transition-colors shadow-lg shadow-primary-container/20 flex justify-center items-center gap-2 disabled:opacity-50"
            >
              {isSubmitting ? (
                <span>Placing Order...</span>
              ) : (
                <>
                  <span>CONFIRM &amp; PLACE ORDER</span>
                  <span className="material-symbols-outlined text-sm">arrow_forward</span>
                </>
              )}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}
