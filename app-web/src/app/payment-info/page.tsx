"use client";
import Link from 'next/link';

export default function PaymentInfoPage() {
  // Cash on Delivery is the only live method. Card checkout (Stripe) is built
  // but stays "Coming Soon" until live keys are configured — update this list
  // and the FAQ together when it launches.
  const comingSoon = [
    { name: "Visa", icon: "credit_card" },
    { name: "Mastercard", icon: "credit_card" },
    { name: "American Express", icon: "credit_card" },
    { name: "Apple Pay", icon: "contactless" },
    { name: "Google Pay", icon: "contactless" },
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
            <p className="text-text-secondary text-sm">Last Updated: September 30, 2026</p>
          </div>

          {/* Content */}
          <div className="max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              We want to ensure your purchasing experience at <strong>Sunnah Grandeur</strong> is as convenient and secure as possible. Below are the details regarding accepted payments.
            </p>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">Accepted Payment Method</h2>
              <div className="bg-surface-card border border-primary-container/40 p-5 rounded-lg flex items-start gap-4 max-w-xl">
                <span className="material-symbols-outlined text-primary-container text-3xl">local_shipping</span>
                <div>
                  <p className="font-semibold text-text-primary">Cash on Delivery (COD)</p>
                  <p className="text-xs md:text-sm mt-1">
                    Available on all orders within the USA, on our website and in the Sunnah Grandeur app. Place your order online and pay the courier in cash when your package arrives. Please have the exact order total ready.
                  </p>
                </div>
              </div>
            </section>

            <section className="space-y-4 pt-4 border-t border-border-subtle">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">Coming Soon</h2>
              <p>
                Secure online card and wallet payments are on the way. Until then, these methods cannot be selected at checkout:
              </p>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4 pt-2">
                {comingSoon.map((method) => (
                  <div key={method.name} className="bg-surface-card border border-border-subtle p-4 rounded-lg flex flex-col items-start gap-2 opacity-70">
                    <span className="material-symbols-outlined text-primary-container text-2xl">{method.icon}</span>
                    <span className="font-semibold text-text-primary text-sm">{method.name}</span>
                    <span className="text-[10px] uppercase tracking-wider text-text-secondary">Coming soon</span>
                  </div>
                ))}
              </div>
              <p className="text-xs">
                When card payments launch, they will be processed securely by Stripe over encrypted (SSL/TLS) connections. Your full card number is handled by Stripe and never stored on our servers.
              </p>
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
