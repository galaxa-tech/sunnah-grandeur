"use client";
import Link from 'next/link';

// Covers the storefront website AND the Sunnah Grandeur iOS/Android app.
// This URL is the Privacy Policy URL in App Store Connect and Google Play —
// keep it in sync with the App Privacy label / Data safety form and with
// what app-mobile actually collects.

const H2 = "font-serif text-xl md:text-2xl font-bold text-text-primary";
const H3 = "font-serif text-lg font-semibold text-text-primary";
const B = "text-text-primary";
const A = "text-primary-container hover:underline";

export default function PrivacyPolicyPage() {
  return (
    <>
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern animate-fade-in"></div>

      <div className="flex-grow pt-32 pb-24 relative z-10">
        <div className="max-w-4xl mx-auto px-gutter">

          {/* Breadcrumbs */}
          <nav className="flex items-center gap-2 text-text-secondary text-xs mb-8 font-label-accent uppercase tracking-wider">
            <Link href="/" className="hover:text-primary-container transition-colors">Home</Link>
            <span className="material-symbols-outlined text-xs">chevron_right</span>
            <span className="text-primary-container">Privacy Policy</span>
          </nav>

          {/* Header */}
          <div className="border-b border-border-subtle pb-8 mb-10">
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-text-primary mb-4">Privacy Policy</h1>
            <p className="text-text-secondary text-sm">Last Updated: September 30, 2026</p>
          </div>

          {/* Content */}
          <div className="max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              At <strong className={B}>Sunnah Grandeur</strong> (&ldquo;we&rdquo;, &ldquo;us&rdquo;), we value and respect your privacy. This Privacy Policy explains what personal information we collect, how we use and share it, and the choices you have. It applies to:
            </p>
            <ul className="list-disc pl-6 space-y-2">
              <li>our online store at <strong className={B}>sunnahgrandeur.com</strong> (the &ldquo;Website&rdquo;); and</li>
              <li>the <strong className={B}>Sunnah Grandeur mobile app</strong> for iOS and Android, including its web version (the &ldquo;App&rdquo;).</li>
            </ul>
            <p>Together these are the &ldquo;Services&rdquo;. By using the Services you agree to this policy.</p>

            <section className="space-y-4">
              <h2 className={H2}>1. Information We Collect</h2>

              <h3 className={H3}>a) Information you give us</h3>
              <ul className="list-disc pl-6 space-y-2">
                <li><strong className={B}>Account information:</strong> your name, email address and (optionally) phone number when you create an account.</li>
                <li><strong className={B}>Sign-in with Google or Apple:</strong> if you choose Google Sign-In or Sign in with Apple, we receive your name, email address and a unique account identifier from that provider. With Apple you may choose to hide your email, in which case we receive an Apple relay address. We never receive your Google or Apple password.</li>
                <li><strong className={B}>Order information:</strong> delivery name, phone, email, shipping address, the products you order and order history.</li>
                <li><strong className={B}>Content you submit:</strong> product reviews, app ratings/feedback, and messages sent through our contact form or by email.</li>
              </ul>

              <h3 className={H3}>b) Information collected by the App on your device</h3>
              <ul className="list-disc pl-6 space-y-2">
                <li>
                  <strong className={B}>Location (optional):</strong> with your permission, the App uses your device&apos;s precise or approximate location <em>while the App is in use</em> to calculate prayer times, show the Qibla direction and find nearby mosques. Your location is processed on your device and is <strong className={B}>not stored on our servers</strong>. When you use the mosque finder, your approximate coordinates are sent to Google Maps / Places to return nearby results. You can deny or revoke location access at any time in your device settings and enter a city manually instead.
                </li>
                <li>
                  <strong className={B}>Notifications:</strong> if you allow notifications, the App schedules Adhan and prayer reminders <em>locally on your device</em>. We do not use push-notification tracking.
                </li>
                <li>
                  <strong className={B}>On-device preferences:</strong> theme, language, prayer calculation method, tasbih counts, prayer tracking and similar settings are stored only on your device.
                </li>
                <li>
                  <strong className={B}>Camera and microphone:</strong> the App itself does not use your camera or microphone. Your device may show a permission prompt only if embedded YouTube video content requests it; you can decline without affecting the App.
                </li>
              </ul>

              <h3 className={H3}>c) Payment information</h3>
              <p>
                We currently accept <strong className={B}>Cash on Delivery</strong> only, so we do not collect any card or bank details. When card payments launch, they will be processed by Stripe, and your full card number will be handled by Stripe and never stored on our servers.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className={H2}>2. How We Use Your Information</h2>
              <ul className="list-disc pl-6 space-y-2">
                <li>To create and secure your account and let you sign in on the Website and App;</li>
                <li>To process, fulfill and deliver your orders, and send order confirmations and shipping updates;</li>
                <li>To provide App features such as prayer times, Qibla direction, the mosque finder, Quran and Islamic media;</li>
                <li>To provide customer support and respond to your inquiries;</li>
                <li>To show your product reviews to other customers (by the display name you chose);</li>
                <li>To maintain security, prevent fraud and improve the Services; and</li>
                <li>To comply with legal, tax and accounting obligations.</li>
              </ul>
              <p>We do <strong className={B}>not</strong> use your information for targeted advertising, and we do not track you across other companies&apos; apps or websites.</p>
            </section>

            <section className="space-y-4">
              <h2 className={H2}>3. Selling and Sharing Information</h2>
              <p><strong className={B}>We do not sell or rent your personal information.</strong></p>
              <p>We share information only with service providers that help us run the Services, under their own privacy and security terms:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li><strong className={B}>Google Firebase</strong> (Authentication, Cloud Firestore database, Cloud Functions, Storage and Hosting) — stores your account, cart, favorites, orders and reviews on servers in the United States.</li>
                <li><strong className={B}>Google Sign-In</strong> and <strong className={B}>Sign in with Apple</strong> — only if you choose to sign in with them.</li>
                <li><strong className={B}>Google Maps / Places</strong> — for the mosque finder.</li>
                <li><strong className={B}>YouTube</strong> — Islamic lectures and media in the App are played through YouTube&apos;s embedded player, which is subject to the <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer" className={A}>Google Privacy Policy</a>.</li>
                <li><strong className={B}>Stripe</strong> — for card payments, once available.</li>
                <li><strong className={B}>Shipping couriers</strong> — your name, phone and address, to deliver your order.</li>
              </ul>
              <p>We may also disclose information if required by law, or to protect the rights, property or safety of Sunnah Grandeur, our customers or others.</p>
            </section>

            <section className="space-y-4">
              <h2 className={H2}>4. Cookies and Local Storage</h2>
              <p>
                The Website does not use advertising cookies or third-party marketing trackers (such as Meta Pixel or Google Analytics). We use your browser&apos;s <strong className={B}>localStorage</strong> for preferences such as your theme, language and cart, and Firebase Authentication stores a session token so you stay signed in. See our <Link href="/cookie-policy" className={A}>Cookie Policy</Link>.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className={H2}>5. Data Retention and Account Deletion</h2>
              <p>
                We keep your account information for as long as your account is active. You can <strong className={B}>delete your account at any time</strong> — in the App (Profile → Account &amp; Identity → Delete Account), on our <Link href="/account-deletion" className={A}>Account Deletion page</Link>, or by emailing us.
              </p>
              <p>
                When you delete your account we permanently delete your sign-in account, profile, cart, favorites, reviews and app feedback. Order records are kept for up to 7 years for tax and accounting purposes, but your name, email, phone and address are removed from them.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className={H2}>6. Your Rights and Choices</h2>
              <p>Depending on where you live (including under the California Consumer Privacy Act), you may have the right to:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li>access the personal information we hold about you;</li>
                <li>correct inaccurate information (you can edit your name in your account at any time);</li>
                <li>delete your information (see section 5);</li>
                <li>withdraw consent, for example by turning off location or notifications in your device settings.</li>
              </ul>
              <p>To make a request, email <a href="mailto:info@sunnahgrandeur.us" className={A}>info@sunnahgrandeur.us</a>. We will respond within 30 days and will not discriminate against you for exercising your rights.</p>
            </section>

            <section className="space-y-4">
              <h2 className={H2}>7. Security</h2>
              <p>
                All data is transmitted over encrypted HTTPS connections and stored with Google Firebase, which encrypts data at rest. Access to your data is restricted by security rules so that only you (and authorized Sunnah Grandeur staff, for order fulfillment) can see it. No method of transmission or storage is 100% secure, but we work hard to protect your information.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className={H2}>8. Children&apos;s Privacy</h2>
              <p>
                The Services are not directed to children under 13, and we do not knowingly collect personal information from children under 13. If you believe a child has given us personal information, please contact us and we will delete it.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className={H2}>9. Changes to This Policy</h2>
              <p>
                We may update this Privacy Policy from time to time. We will post the updated version on this page and change the &ldquo;Last Updated&rdquo; date above. Significant changes will also be announced in the App or on the Website.
              </p>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <h2 className={H2}>10. Contact Us</h2>
              <p>
                If you have questions about this Privacy Policy or our privacy practices, contact us at <a href="mailto:info@sunnahgrandeur.us" className={A}>info@sunnahgrandeur.us</a> or <a href="tel:+16465940396" className={A}>+1 (646) 594-0396</a>.
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
    </>
  );
}
