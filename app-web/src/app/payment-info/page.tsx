"use client";
import Link from 'next/link';

export default function PaymentInfoPage() {
  const methods = [
    { name: "Credit & debit cards", note: "Visa, Mastercard, American Express, Discover", icon: "credit_card" },
    { name: "Apple Pay & Google Pay", note: "On supported devices and browsers", icon: "contactless" },
    { name: "PayPal", note: "Pay with your PayPal balance, bank or card", icon: "account_balance_wallet" },
    { name: "Venmo", note: "Available to US customers via PayPal checkout", icon: "smartphone" },
  ];

  return (
    <>
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern animate-fade-in"></div>

      <div className="flex-grow pt-32 pb-24 relative z-10">
        <div className="max-w-4xl mx-auto px-gutter">
          
          {/* Breadcrumbs */}
          <nav className="flex items-center gap-2 text-text-secondary text-xs mb-8 font-label-accent uppercase tracking-wider">
            <Link href="/" className="hover:text-primary-container transition-colors">Home</Link>
            <span className="material-symbols-outlined text-xs">chevron_right</span>
            <span className="text-primary-container">Payment Information</span>
          </nav>

          {/* Header */}
          <div className="border-b border-border-subtle pb-8 mb-10">
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-text-primary mb-4">Payment Information</h1>
            <p className="text-text-secondary text-sm">Last Updated: October 12, 2026</p>
          </div>

          {/* Content */}
          <div className="max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              We want to ensure your purchasing experience at <strong>Sunnah Grandeur</strong> is as convenient and secure as possible. Below are the details regarding accepted payments.
            </p>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">Accepted Payment Methods</h2>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
                {methods.map((m) => (
                  <div key={m.name} className="bg-surface-card border border-border-subtle p-4 rounded-lg flex items-start gap-3">
                    <span className="material-symbols-outlined text-primary-container text-2xl">{m.icon}</span>
                    <div>
                      <p className="font-semibold text-text-primary text-sm">{m.name}</p>
                      <p className="text-xs">{m.note}</p>
                    </div>
                  </div>
                ))}
              </div>
              <p className="text-xs">
                Cash on Delivery is not available for US orders. All payments are made online at checkout.
              </p>
            </section>

            <section className="space-y-4 pt-4 border-t border-border-subtle">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">Payment Security</h2>
              <ul className="list-disc pl-6 space-y-2">
                <li>Card and wallet payments are processed by <strong>Stripe</strong>; PayPal and Venmo payments by <strong>PayPal</strong>. Both are PCI-DSS certified payment providers.</li>
                <li>All payment pages use encrypted (SSL/TLS) connections.</li>
                <li>Your full card number is entered directly with Stripe and is <strong>never stored on our servers</strong>.</li>
              </ul>
            </section>

            <section className="space-y-4 pt-4 border-t border-border-subtle">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">If a Payment Fails</h2>
              <ul className="list-disc pl-6 space-y-2">
                <li>If your payment is declined, cancelled or fails, <strong>you are not charged</strong> and you will see a clear message on the checkout page so you can try again or choose another method.</li>
                <li>Your items stay reserved for 60 minutes while you retry. If payment is not completed in that time, the order is cancelled automatically and no charge is made.</li>
                <li>If you ever see a pending authorization from your bank for a failed payment, it is released by your bank automatically, usually within 3-5 business days.</li>
                <li>Still having trouble? Contact us and we will help right away.</li>
              </ul>
            </section>

            <section className="space-y-4 pt-4 border-t border-border-subtle">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">Sales Tax</h2>
              <p>Sales tax is calculated from your delivery ZIP code and shown at checkout before you pay.</p>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <p>
                For questions regarding payments or billing inquiries, please contact our support team at <a href="mailto:info@sunnahgrandeur.us" className="text-primary-container hover:underline">info@sunnahgrandeur.us</a>.
              </p>
            </section>
          </div>

        </div>
      </div>
    </>
  );
}
