"use client";
import Link from 'next/link';

export default function OrderCancellationPage() {
  return (
    <>
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern animate-fade-in"></div>

      <div className="flex-grow pt-32 pb-24 relative z-10">
        <div className="max-w-4xl mx-auto px-gutter">
          
          {/* Breadcrumbs */}
          <nav className="flex items-center gap-2 text-text-secondary text-xs mb-8 font-label-accent uppercase tracking-wider">
            <Link href="/" className="hover:text-primary-container transition-colors">Home</Link>
            <span className="material-symbols-outlined text-xs">chevron_right</span>
            <span className="text-primary-container">Order Cancellation</span>
          </nav>

          {/* Header */}
          <div className="border-b border-border-subtle pb-8 mb-10">
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-white mb-4">Order Cancellation</h1>
            <p className="text-text-secondary text-sm">Last Updated: August 2, 2026</p>
          </div>

          {/* Content */}
          <div className="prose prose-invert max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              At <strong>Sunnah Grandeur</strong>, we process orders quickly to ensure your luxury items are shipped without delay. If you need to cancel an order, please review our policy below.
            </p>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">Cancellation Policy</h2>
              <p>
                Orders can be cancelled <strong>before shipment only</strong>. 
              </p>
              <p>
                Once an order has been handed over to our courier partners and a tracking number has been generated, it is considered shipped and can no longer be cancelled.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">How to Request a Cancellation</h2>
              <p>
                To cancel your order, please contact our support team immediately:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Send an email to <a href="mailto:info@sunnahgrandeur.com" className="text-primary-container hover:underline font-semibold">info@sunnahgrandeur.com</a>.</li>
                <li>Use the subject line: <strong>Order Cancellation Request - [Your Order Number]</strong>.</li>
                <li>Provide your full name and the order details.</li>
              </ul>
              <p>
                Our support team will verify if your order has shipped and assist you with the cancellation process. If the order was cancelled successfully before shipment, we will initiate the refund back to your original payment method.
              </p>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <p>
                For further questions or inquiries regarding order processing and policies, please reach out to us at <a href="mailto:info@sunnahgrandeur.com" className="text-primary-container hover:underline">info@sunnahgrandeur.com</a>.
              </p>
            </section>
          </div>

        </div>
      </div>
    </>
  );
}
