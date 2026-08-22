"use client";

import { useState } from 'react';
import Link from 'next/link';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

export default function Footer() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [subscribed, setSubscribed] = useState(false);

  const handleSubscribe = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;

    setLoading(true);
    try {
      await addDoc(collection(db, 'subscribers'), {
        email,
        subscribedAt: serverTimestamp(),
      });
      setSubscribed(true);
      setEmail('');
    } catch (err) {
      console.error('Error subscribing email:', err);
      // Fallback UI
      setSubscribed(true);
      setEmail('');
    } finally {
      setLoading(false);
    }
  };

  return (
    <footer className="w-full pt-16 pb-8 bg-surface-container-lowest border-t border-outline-variant/20">
      <div className="max-w-container-max mx-auto px-gutter grid grid-cols-1 md:grid-cols-4 gap-card-gap">
        <div className="md:col-span-1 mb-8 md:mb-0 space-y-4">
          <Link className="text-headline-md font-headline-md text-primary block font-serif font-bold" href="/">
            Sunnah Grandeur
          </Link>
          <p className="text-body-md text-text-secondary text-sm leading-relaxed">
            Elevating the everyday with premium halal fragrances inspired by timeless elegance and Islamic values.
          </p>
          <div className="text-text-secondary text-xs space-y-1.5 pt-2">
            <p className="font-semibold text-text-primary">Office Address:</p>
            <p className="whitespace-pre-line leading-relaxed">
              3715 73rd St, Suite 205
              Jackson Heights, NY 11372
              USA
            </p>
            <p className="pt-2">
              <a href="mailto:info@sunnahgrandeur.com" className="hover:text-primary transition-colors font-semibold">info@sunnahgrandeur.com</a>
            </p>
          </div>
          <div className="pt-2">
            <a 
              href="https://www.facebook.com/sunnahgrandeurnyc" 
              target="_blank" 
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 text-xs font-label-accent text-text-secondary hover:text-primary-container transition-colors uppercase tracking-widest"
            >
              <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
                <path d="M9 8h-3v4h3v12h5v-12h3.642l.358-4h-4v-1.667c0-.955.192-1.333 1.115-1.333h2.885v-5h-3.808c-3.596 0-5.192 1.583-5.192 4.615v3.385z"/>
              </svg>
              Facebook
            </a>
          </div>
        </div>

        <div className="flex flex-col space-y-3">
          <h4 className="text-label-accent font-label-accent text-text-primary uppercase mb-2 font-bold">Company</h4>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/about">About Us</Link>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/shop">Our Collection</Link>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/contact">Contact Us</Link>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/support">Customer Support</Link>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/faq">FAQ</Link>
        </div>

        <div className="flex flex-col space-y-3">
          <h4 className="text-label-accent font-label-accent text-text-primary uppercase mb-2 font-bold">Legal &amp; Policies</h4>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/privacy-policy">Privacy Policy</Link>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/terms-of-service">Terms &amp; Conditions</Link>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/disclaimer">Disclaimer</Link>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/cookie-policy">Cookie Policy</Link>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/shipping-info">Shipping &amp; Delivery</Link>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/payment-info">Payment Information</Link>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/order-cancellation">Order Cancellation</Link>
          <Link className="text-on-surface-variant hover:text-primary transition-colors text-label-accent font-label-accent uppercase text-xs" href="/returns-and-exchanges">Exchange Policy</Link>
        </div>

        <div className="flex flex-col">
          <h4 className="text-label-accent font-label-accent text-text-primary uppercase mb-4 font-bold">Join the List</h4>
          <p className="text-body-md text-text-secondary text-sm mb-4 leading-relaxed">
            Receive exclusive updates on new releases and artisanal stories.
          </p>

          {subscribed ? (
            <div className="p-3 bg-emerald-500/10 border border-emerald-500/30 rounded text-emerald-400 text-xs font-semibold text-center">
              ✓ Jazakallah Khair! You have been subscribed.
            </div>
          ) : (
            <form onSubmit={handleSubscribe} className="flex">
              <input
                className="bg-surface-card border-border-subtle border text-text-primary px-4 py-2 text-sm w-full focus:outline-none focus:border-primary-container transition-colors rounded-l-DEFAULT"
                placeholder="Email Address"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
              <button 
                type="submit" 
                disabled={loading}
                className="bg-primary-container text-bg-primary px-4 py-2 text-label-accent font-label-accent uppercase rounded-r-DEFAULT hover:bg-[#e6c364] transition-colors font-bold text-xs shrink-0 disabled:opacity-50"
              >
                {loading ? "..." : "Subscribe"}
              </button>
            </form>
          )}
        </div>
      </div>
      <div className="max-w-container-max mx-auto px-gutter mt-16 pt-8 border-t border-border-subtle flex flex-col sm:flex-row items-center justify-between gap-4 text-center sm:text-left">
        <p className="text-body-md text-text-secondary text-xs">
          © {new Date().getFullYear()} Sunnah Grandeur. All rights reserved.
        </p>
        <a 
          href="https://sunnah-grandeur-admin.web.app" 
          target="_blank" 
          rel="noopener noreferrer"
          className="text-[11px] text-text-secondary/40 hover:text-primary-container transition-colors font-mono uppercase tracking-widest flex items-center gap-1"
          title="Internal Staff &amp; Admin Management Portal"
        >
          <span className="material-symbols-outlined text-[13px]">lock</span>
          Staff Portal
        </a>
      </div>
    </footer>
  );
}
