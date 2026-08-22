"use client";
import Link from 'next/link';

export default function ShippingInfoPage() {
  return (
    <>
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern animate-fade-in"></div>

      <div className="flex-grow pt-32 pb-24 relative z-10">
        <div className="max-w-4xl mx-auto px-gutter">
          
          {/* Breadcrumbs */}
          <nav className="flex items-center gap-2 text-text-secondary text-xs mb-8 font-label-accent uppercase tracking-wider">
            <Link href="/" className="hover:text-primary-container transition-colors">Home</Link>
            <span className="material-symbols-outlined text-xs">chevron_right</span>
            <span className="text-primary-container">Shipping & Delivery</span>
          </nav>

          {/* Header */}
          <div className="border-b border-border-subtle pb-8 mb-10">
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-white mb-4">Shipping & Delivery</h1>
            <p className="text-text-secondary text-sm">Last Updated: August 2, 2026</p>
          </div>

          {/* Content */}
          <div className="prose prose-invert max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              Thank you for shopping at <strong>Sunnah Grandeur</strong>. We want to ensure that your premium alcohol-free fragrances and lifestyle artifacts are delivered to you in a safe and timely manner. Below are the details of our shipping policy.
            </p>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">1. Shipping Regions</h2>
              <p>
                We currently ship to addresses within the <strong>United States of America (USA) only</strong>. We do not support international shipping at this time.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">2. Shipping Fees</h2>
              <p>
                We are pleased to offer <strong>Free Shipping</strong> on all orders. There are no minimum purchase requirements or hidden handling fees.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">3. Estimated Delivery Times</h2>
              <p>
                Our estimated delivery timeframe is <strong>3–7 business days</strong> from the date of shipment.
              </p>
              <p>
                Please note that this is an estimated delivery window and not a guaranteed delivery date. Actual transit times may vary depending on local carrier schedules, inclement weather conditions, or public holidays.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">4. Order Tracking</h2>
              <p>
                Once your package has been handed over to the courier, you will receive a shipment confirmation email containing your tracking number and a link to trace your delivery. Please allow up to 24 hours for the tracking information to become active in the carrier's system.
              </p>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">5. Contact Support</h2>
              <p>
                If you have any questions or require support regarding your order's delivery status, please contact us at <a href="mailto:info@sunnahgrandeur.com" className="text-primary-container hover:underline">info@sunnahgrandeur.com</a>.
              </p>
            </section>
          </div>

        </div>
      </div>
    </>
  );
}
