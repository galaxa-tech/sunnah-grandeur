"use client";
import Link from 'next/link';

export default function ReturnsAndExchangesPage() {
  return (
    <>
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern animate-fade-in"></div>

      <div className="flex-grow pt-32 pb-24 relative z-10">
        <div className="max-w-4xl mx-auto px-gutter">
          
          {/* Breadcrumbs */}
          <nav className="flex items-center gap-2 text-text-secondary text-xs mb-8 font-label-accent uppercase tracking-wider">
            <Link href="/" className="hover:text-primary-container transition-colors">Home</Link>
            <span className="material-symbols-outlined text-xs">chevron_right</span>
            <span className="text-primary-container">Exchange Policy</span>
          </nav>

          {/* Header */}
          <div className="border-b border-border-subtle pb-8 mb-10">
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-white mb-4">Exchange & Damage Policy</h1>
            <p className="text-text-secondary text-sm">Last Updated: August 2, 2026</p>
          </div>

          {/* Content */}
          <div className="prose prose-invert max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              At <strong>Sunnah Grandeur</strong>, we are committed to providing premium quality alcohol-free fragrances and products. Please review our policies regarding exchanges and handling damaged or incorrect orders.
            </p>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">1. Damaged or Incorrect Items</h2>
              <p>
                In the rare event that you receive a damaged product or an incorrect item, please notify our customer support team within <strong>48 hours of delivery</strong>.
              </p>
              <p>
                To help us resolve the issue quickly, please send an email to <a href="mailto:info@sunnahgrandeur.com" className="text-primary-container hover:underline font-semibold">info@sunnahgrandeur.com</a> with the following details:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Your order number;</li>
                <li>A description of the issue; and</li>
                <li>Clear photos showing the damage or the incorrect item received.</li>
              </ul>
              <p>
                Our customer support team will review your photos and information to provide an appropriate resolution.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">2. Exchange Policy</h2>
              <p>
                All exchange requests are handled directly from our main office.
              </p>
              <p>
                To initiate an exchange, please email us at <a href="mailto:info@sunnahgrandeur.com" className="text-primary-container hover:underline font-semibold">info@sunnahgrandeur.com</a>. We will coordinate with you regarding the exchange process.
              </p>
              <p className="text-xs">
                Office Location:<br />
                3715 73rd St, Suite 205<br />
                Jackson Heights, NY 11372<br />
                USA
              </p>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">3. Returns & Refunds</h2>
              <p>
                For questions regarding returns or refunds, please contact our support team at <a href="mailto:info@sunnahgrandeur.com" className="text-primary-container hover:underline font-semibold">info@sunnahgrandeur.com</a>.
              </p>
            </section>
          </div>

        </div>
      </div>
    </>
  );
}
