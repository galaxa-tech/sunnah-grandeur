"use client";
import { useState } from 'react';
import Link from 'next/link';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/lib/firebase';
import { useAuth } from '@/context/AuthContext';
import AuthModal from '@/components/AuthModal';

// Public account-deletion page — the URL submitted to Google Play (Data safety →
// "Delete account URL") and linked from the App Store listing and the app.
// The "What is deleted" list mirrors deleteAccount in
// backend/functions/src/domains/users/index.js — keep them in sync.

export default function AccountDeletionPage() {
  const { user, logOut } = useAuth();
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [confirmText, setConfirmText] = useState('');
  const [status, setStatus] = useState<'idle' | 'deleting' | 'done' | 'error'>('idle');
  const [errorMsg, setErrorMsg] = useState('');

  const isRealAccount = !!user && !user.isAnonymous;

  const handleDelete = async () => {
    if (confirmText !== 'DELETE') return;
    setStatus('deleting');
    setErrorMsg('');
    try {
      await httpsCallable(functions, 'deleteAccount')({});
      await logOut().catch(() => {});
      setStatus('done');
    } catch (err: any) {
      setStatus('error');
      setErrorMsg(
        err?.message
          ? `We couldn't delete your account (${err.message}).`
          : "We couldn't delete your account."
      );
    }
  };

  return (
    <>
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern animate-fade-in"></div>

      <div className="flex-grow pt-32 pb-24 relative z-10">
        <div className="max-w-4xl mx-auto px-gutter">

          {/* Breadcrumbs */}
          <nav className="flex items-center gap-2 text-text-secondary text-xs mb-8 font-label-accent uppercase tracking-wider">
            <Link href="/" className="hover:text-primary-container transition-colors">Home</Link>
            <span className="material-symbols-outlined text-xs">chevron_right</span>
            <span className="text-primary-container">Account Deletion</span>
          </nav>

          {/* Header */}
          <div className="border-b border-border-subtle pb-8 mb-10">
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-text-primary mb-4">Delete Your Account &amp; Data</h1>
            <p className="text-text-secondary text-sm">Last Updated: September 30, 2026</p>
          </div>

          <div className="max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              You can permanently delete your <strong className="text-text-primary">Sunnah Grandeur</strong> account at any time. This applies to accounts created on our website (sunnahgrandeur.com) and in the Sunnah Grandeur mobile app for iOS and Android — it is the same account. There are three ways to do it:
            </p>

            {/* Option 1 — in the app */}
            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">1. In the Sunnah Grandeur app</h2>
              <ol className="list-decimal pl-6 space-y-2">
                <li>Open the app and go to the <strong className="text-text-primary">Profile</strong> tab.</li>
                <li>Tap <strong className="text-text-primary">Account &amp; Identity</strong>.</li>
                <li>Under <strong className="text-text-primary">Danger Zone</strong>, tap <strong className="text-text-primary">Delete Account</strong> and confirm.</li>
              </ol>
              <p>If you signed in with Apple, you&apos;ll be asked to confirm with Apple once more so we can also revoke Sign in with Apple access.</p>
            </section>

            {/* Option 2 — on this page */}
            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">2. Right here on the website</h2>

              <div className="bg-surface-card border border-border-subtle rounded-lg p-6 space-y-4">
                {status === 'done' ? (
                  <div className="flex items-start gap-3">
                    <span className="material-symbols-outlined text-emerald-500">check_circle</span>
                    <p className="text-text-primary">
                      Your account and personal data have been permanently deleted. You have been signed out. Thank you for being part of Sunnah Grandeur.
                    </p>
                  </div>
                ) : !isRealAccount ? (
                  <>
                    <p>Sign in with the email or Google account you use for Sunnah Grandeur, then return to this page to delete it.</p>
                    <button
                      onClick={() => setShowAuthModal(true)}
                      className="bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest px-6 py-2.5 rounded hover:bg-[#e6c364] transition-colors"
                    >
                      Sign In to Continue
                    </button>
                    <p className="text-xs">
                      Signed up in the app with Apple? Delete from inside the app (option 1) or email us (option 3).
                    </p>
                  </>
                ) : (
                  <>
                    <p>
                      Signed in as <strong className="text-text-primary">{user?.email || user?.displayName || 'your account'}</strong>. This permanently deletes your account and cannot be undone.
                    </p>
                    <label className="block space-y-2">
                      <span className="text-xs uppercase tracking-wider font-semibold text-text-primary">Type DELETE to confirm</span>
                      <input
                        type="text"
                        value={confirmText}
                        onChange={(e) => setConfirmText(e.target.value.trim().toUpperCase())}
                        placeholder="DELETE"
                        autoComplete="off"
                        className="w-full max-w-xs bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-sm text-text-primary focus:border-red-500 focus:outline-none"
                      />
                    </label>
                    {status === 'error' && (
                      <p className="text-xs text-red-500">
                        {errorMsg} Please try again, or email us and we&apos;ll delete it for you. If you signed in a long time ago, sign out and back in first.
                      </p>
                    )}
                    <button
                      onClick={handleDelete}
                      disabled={confirmText !== 'DELETE' || status === 'deleting'}
                      className="bg-red-600 text-white font-bold text-xs uppercase tracking-widest px-6 py-2.5 rounded hover:bg-red-700 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
                    >
                      {status === 'deleting' ? 'Deleting…' : 'Permanently Delete My Account'}
                    </button>
                  </>
                )}
              </div>
            </section>

            {/* Option 3 — email */}
            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">3. By email</h2>
              <p>
                Email <a href="mailto:info@sunnahgrandeur.us?subject=Account%20Deletion%20Request" className="text-primary-container hover:underline font-semibold">info@sunnahgrandeur.us</a> from the address on your account with the subject line <strong className="text-text-primary">Account Deletion Request</strong>. We may ask you to confirm ownership of the account, and we will complete the deletion within <strong className="text-text-primary">30 days</strong> (usually much sooner) and email you once it&apos;s done.
              </p>
            </section>

            {/* What happens */}
            <section className="space-y-4 border-t border-border-subtle pt-8">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">What is deleted</h2>
              <p>Deleting your account immediately and permanently removes:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Your sign-in account (email/password, Google or Apple login);</li>
                <li>Your profile — name, email address and phone number;</li>
                <li>Your shopping cart and saved favorites;</li>
                <li>Your tasbih (dhikr) history and other in-app activity stored with your account;</li>
                <li>Product reviews and app feedback you submitted.</li>
              </ul>
              <p>
                Preferences stored only on your device (theme, language, prayer-time settings, location for prayer times) are not sent to us; they are removed when you uninstall the app or clear your browser data.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">What we keep, and why</h2>
              <p>
                If you placed orders, we keep a record of each order (items, amounts, dates and order status) because U.S. tax and accounting law requires it. When you delete your account, <strong className="text-text-primary">we remove your name, email, phone number and delivery address from those records</strong> and unlink them from you. Anonymized order records are kept for up to 7 years.
              </p>
              <p>
                Messages you sent through our contact form or by email are kept only as long as needed to answer them. You can ask us to delete them by emailing us.
              </p>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">Questions</h2>
              <p>
                See our <Link href="/privacy-policy" className="text-primary-container hover:underline">Privacy Policy</Link> for full details, or contact us at <a href="mailto:info@sunnahgrandeur.us" className="text-primary-container hover:underline">info@sunnahgrandeur.us</a> / <a href="tel:+16465940396" className="text-primary-container hover:underline">+1 (646) 594-0396</a>.
              </p>
              <p className="text-xs">
                Sunnah Grandeur<br />
                3715 73rd St, Suite 205<br />
                Jackson Heights, NY 11372<br />
                USA
              </p>
            </section>
          </div>

        </div>
      </div>

      {showAuthModal && <AuthModal onClose={() => setShowAuthModal(false)} />}
    </>
  );
}
