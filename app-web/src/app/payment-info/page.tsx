"use client";
import Link from 'next/link';

export default function PaymentInfoPage() {
  const paymentMethods = [
    { name: "Visa", icon: "credit_card" },
    { name: "Mastercard", icon: "credit_card" },
    { name: "American Express", icon: "credit_card" },
    { name: "Apple Pay", icon: "contactless" },
    { name: "Google Pay", icon: "contactless" },
    { name: "PayPal", icon: "account_balance_wallet" },
    { name: "Shop Pay", icon: "shopping_bag" }
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
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-white mb-4">Payment Information</h1>
            <p className="text-text-secondary text-sm">Last Updated: August 2, 2026</p>
          </div>

          {/* Content */}
          <div className="prose prose-invert max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              We want to ensure your purchasing experience at <strong>Sunnah Grandeur</strong> is as convenient and secure as possible. Below are the details regarding accepted payments.
            </p>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">Accepted Payment Methods</h2>
              <p>
                We accept a wide range of popular payment options:
              </p>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4 pt-2">
                {paymentMethods.map((method, index) => (
                  <div key={index} className="bg-surface-card border border-border-subtle p-5 rounded-lg flex items-center gap-3">
                    <span className="material-symbols-outlined text-primary-container text-2xl">{method.icon}</span>
                    <span className="font-semibold text-text-primary text-sm">{method.name}</span>
                  </div>
                ))}
              </div>
            </section>

            <section className="space-y-4 pt-4 border-t border-border-subtle">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">Security & Transaction Processing</h2>
              <p>
                To protect your financial transactions, all payments are securely encrypted using standard Secure Socket Layer (SSL) technology and processed via external compliant payment gateways. 
              </p>
              <div className="p-4 bg-primary-container/10 border border-primary-container/20 rounded text-xs text-primary-container leading-relaxed">
                <strong>Important Notice:</strong> Our online storefront and checkout system are currently running in **demonstration mode**. No live payment transactions can be completed, and your card will not be charged. This mockup checkout is provided to show the final design and integration flow. We will flag active payment processing connections once they are officially online.
              </div>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <p>
                For questions regarding payments or billing inquiries, please contact our support team at <a href="mailto:info@sunnahgrandeur.com" className="text-primary-container hover:underline">info@sunnahgrandeur.com</a>.
              </p>
            </section>
          </div>

        </div>
      </div>
    </>
  );
}
