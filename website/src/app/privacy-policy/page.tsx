"use client";
import Link from 'next/link';

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
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-white mb-4">Privacy Policy</h1>
            <p className="text-text-secondary text-sm">Last Updated: August 2, 2026</p>
          </div>

          {/* Content */}
          <div className="prose prose-invert max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              At <strong>Sunnah Grandeur</strong>, we value and respect your privacy. This Privacy Policy describes how we collect, use, and share your personal information when you visit our website or make a purchase from our store.
            </p>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">1. Information We Collect</h2>
              <p>
                When you visit our site or attempt to place an order, we may collect the following personal information:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li><strong>Contact Information:</strong> Name, email address, and phone number.</li>
                <li><strong>Shipping & Billing Details:</strong> Billing address, shipping address, and order details.</li>
                <li><strong>Payment Information:</strong> Necessary details for transaction processing. (Please note that all payment processing is handled securely by our third-party payment gateways, and we do not store your raw credit card credentials on our servers).</li>
              </ul>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">2. How We Use Your Information</h2>
              <p>
                We use the personal information we collect generally to:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Process, fulfill, and ship your orders;</li>
                <li>Provide customer support and respond to your inquiries;</li>
                <li>Communicate with you regarding order confirmations, updates, or shipping notifications;</li>
                <li>Improve and optimize our services and website user experience; and</li>
                <li>Comply with applicable legal, tax, or regulatory requirements.</li>
              </ul>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">3. Selling and Sharing Information</h2>
              <p>
                <strong>We do not sell your personal information.</strong>
              </p>
              <p>
                We only share your information with trusted third-party service providers who assist us in operating our business and delivering products to you:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li><strong>Vercel:</strong> For hosting and operational delivery of the website.</li>
                <li><strong>Stripe:</strong> For secure payment gateway processing.</li>
                <li><strong>Shipping Couriers:</strong> For order fulfillment and package delivery.</li>
              </ul>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">4. Cookies and Local Storage</h2>
              <p>
                Our website does not use advertising tracking cookies or third-party marketing trackers (such as Meta Pixels or Google Analytics) to track your behavior. We only utilize standard browser <strong>localStorage</strong> to store user preferences, such as your dark/light theme selection, to ensure a seamless visual experience.
              </p>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">5. Contact Us</h2>
              <p>
                If you have questions about our privacy practices, please contact us via email at <a href="mailto:info@sunnahgrandeur.com" className="text-primary-container hover:underline">info@sunnahgrandeur.com</a>.
              </p>
              <p className="text-xs">
                Sunnah Grandeur Office Address:<br />
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
