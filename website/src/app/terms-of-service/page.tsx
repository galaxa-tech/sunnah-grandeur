"use client";
import Link from 'next/link';

export default function TermsOfServicePage() {
  return (
    <>
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern animate-fade-in"></div>

      <div className="flex-grow pt-32 pb-24 relative z-10">
        <div className="max-w-4xl mx-auto px-gutter">
          
          {/* Breadcrumbs */}
          <nav className="flex items-center gap-2 text-text-secondary text-xs mb-8 font-label-accent uppercase tracking-wider">
            <Link href="/" className="hover:text-primary-container transition-colors">Home</Link>
            <span className="material-symbols-outlined text-xs">chevron_right</span>
            <span className="text-primary-container">Terms & Conditions</span>
          </nav>

          {/* Header */}
          <div className="border-b border-border-subtle pb-8 mb-10">
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-white mb-4">Terms & Conditions</h1>
            <p className="text-text-secondary text-sm">Last Updated: August 2, 2026</p>
          </div>

          {/* Content */}
          <div className="prose prose-invert max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              By accessing, browsing, or placing an order on the <strong>Sunnah Grandeur</strong> website, you agree to comply with and be bound by the following Terms & Conditions. Please read them carefully before using our services.
            </p>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">1. Agreement to Terms</h2>
              <p>
                By using our Site, you warrant that you are at least the age of majority in your jurisdiction and that you agree to all terms, conditions, policies, and notices stated here.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">2. Product Availability & Specifications</h2>
              <p>
                All products on our website are subject to availability. We reserve the right to limit the quantities of any products or services we offer. We make every effort to display the colors, descriptions, and pricing of our premium fragrances as accurately as possible. However, occasional pricing errors or visual variations may occur.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">3. Pricing & Order Processing</h2>
              <p>
                Prices for our products are subject to change without prior notice.
              </p>
              <p>
                We reserve the right to cancel or refuse any order placed with us. Cases for order refusal include, but are not limited to:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Pricing errors or clear description inaccuracies;</li>
                <li>Suspected fraudulent or unauthorized transactions;</li>
                <li>Product stock unavailability or unforeseen delivery restrictions.</li>
              </ul>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">4. Shipping & Delivery</h2>
              <p>
                Shipping estimates provided at checkout are estimates only. Delivery timeframes may vary depending on local carriers, weather conditions, or holidays.
              </p>
              <p>
                Customers are solely responsible for providing accurate and complete shipping information. Sunnah Grandeur is not liable for orders delivered to incorrect addresses provided by the customer.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">5. Exchanges & Damaged Deliveries</h2>
              <p>
                Exchanges and damaged or incorrect item requests are handled strictly in accordance with our customer support and exchange policies. Exchange requests are processed directly from our office. If you receive a damaged or wrong product, you must contact support within 48 hours of delivery and provide photos of the item.
              </p>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">6. Legal Compliance & Contact</h2>
              <p>
                Users agree to use our website only for lawful purposes. These terms are governed by applicable local and federal laws.
              </p>
              <p>
                For questions regarding returns, exchanges, or terms, please contact our support team at <a href="mailto:info@sunnahgrandeur.com" className="text-primary-container hover:underline">info@sunnahgrandeur.com</a>.
              </p>
            </section>
          </div>

        </div>
      </div>
    </>
  );
}
