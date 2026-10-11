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
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-text-primary mb-4">Order Cancellation</h1>
            <p className="text-text-secondary text-sm">Last Updated: October 12, 2026</p>
          </div>

          {/* Content */}
          <div className="prose prose-invert max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              At <strong>Sunnah Grandeur</strong>, we process orders quickly to ensure your luxury items are shipped without delay. If you need to cancel an order, please review our policy below.
            </p>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">Cancellation Policy</h2>
              <p>
                Orders can be cancelled <strong>before shipment only</strong>. Once an order has been handed to our courier and a tracking number has been generated, it is considered shipped and can no longer be cancelled (see our <Link href="/returns-and-exchanges" className="text-primary-container hover:underline">Returns &amp; Refunds</Link> policy instead).
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">How to Cancel Your Order</h2>
              <ol className="list-decimal pl-6 space-y-2">
                <li>Go to <Link href="/account?tab=orders" className="text-primary-container hover:underline font-semibold">My Account → My Orders</Link> (sign in with the email you used at checkout).</li>
                <li>Find your order and press <strong>Cancel Order</strong>.</li>
                <li>You will see a confirmation immediately.</li>
              </ol>
              <p>
                If the Cancel button is not shown, your order has already shipped. Cannot sign in? Email <a href="mailto:info@sunnahgrandeur.us" className="text-primary-container hover:underline font-semibold">info@sunnahgrandeur.us</a> with the subject <strong>Order Cancellation Request - [Your Order Number]</strong> and we will help.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-text-primary">Refunds for Cancelled Orders</h2>
              <p>
                If you already paid, the full amount (including tax) is refunded to your original payment method. Card refunds usually appear within 5-10 business days depending on your bank; PayPal and Venmo refunds are processed by our team shortly after cancellation.
              </p>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <p>
                For further questions or inquiries regarding order processing and policies, please reach out to us at <a href="mailto:info@sunnahgrandeur.us" className="text-primary-container hover:underline">info@sunnahgrandeur.us</a>.
              </p>
            </section>
          </div>

        </div>
      </div>
    </>
  );
}
