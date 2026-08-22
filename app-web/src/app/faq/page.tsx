"use client";
import { useState } from 'react';
import Link from 'next/link';

export default function FAQPage() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  const faqs = [
    {
      q: "Where does Sunnah Grandeur ship?",
      a: "We currently ship to addresses within the United States of America (USA) only. We do not support international delivery at this time."
    },
    {
      q: "How much does shipping cost?",
      a: "Shipping is completely free for all orders. There are no minimum purchase requirements or hidden delivery charges."
    },
    {
      q: "How long does delivery take?",
      a: "Estimated delivery timeframe is 3–7 business days from the date of shipment. Please note that this is an estimate and not a guaranteed delivery date."
    },
    {
      q: "Will I receive tracking information?",
      a: "Yes. Once your order has been shipped, tracking details will be automatically emailed to the address you provided at checkout."
    },
    {
      q: "What payment methods are accepted?",
      a: "We accept Visa, Mastercard, American Express, Apple Pay, Google Pay, PayPal, and Shop Pay."
    },
    {
      q: "Can I cancel my order?",
      a: "Yes, orders can be cancelled before shipment only. Please contact our support team as soon as possible at info@sunnahgrandeur.com to request a cancellation."
    },
    {
      q: "What should I do if I receive a damaged or incorrect item?",
      a: "Please contact our customer support team at info@sunnahgrandeur.com within 48 hours of delivery. In your email, include your order number, a description of the issue, and clear photos of the damaged or incorrect item."
    },
    {
      q: "How do I request an exchange?",
      a: "Exchange requests are handled directly from our main office in Jackson Heights, NY. Please email info@sunnahgrandeur.com to coordinate your request."
    },
    {
      q: "How can I contact Sunnah Grandeur?",
      a: "You can reach us directly via email at info@sunnahgrandeur.com. Our office is located at 3715 73rd St, Suite 205, Jackson Heights, NY 11372, USA."
    }
  ];

  return (
    <>
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern animate-fade-in"></div>

      <div className="flex-grow pt-32 pb-24 relative z-10">
        <div className="max-w-3xl mx-auto px-gutter">
          
          {/* Breadcrumbs */}
          <nav className="flex items-center gap-2 text-text-secondary text-xs mb-8 font-label-accent uppercase tracking-wider">
            <Link href="/" className="hover:text-primary-container transition-colors">Home</Link>
            <span className="material-symbols-outlined text-xs">chevron_right</span>
            <span className="text-primary-container">FAQ</span>
          </nav>

          {/* Header */}
          <div className="border-b border-border-subtle pb-8 mb-12 text-center sm:text-left">
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-white mb-4">Frequently Asked Questions</h1>
            <p className="text-text-secondary text-sm md:text-base max-w-xl">
              Find quick answers to common questions about shipping, delivery, payments, exchanges, and cancellations.
            </p>
          </div>

          {/* FAQ Accordion */}
          <div className="space-y-4">
            {faqs.map((faq, index) => {
              const isOpen = openIndex === index;
              return (
                <div 
                  key={index} 
                  className="bg-surface-card border border-border-subtle rounded-lg overflow-hidden transition-colors hover:border-border-subtle"
                >
                  <button
                    onClick={() => setOpenIndex(isOpen ? null : index)}
                    className="w-full flex items-center justify-between p-5 text-left text-text-primary hover:text-primary-container transition-colors font-serif font-semibold text-sm md:text-base"
                  >
                    <span>{faq.q}</span>
                    <span className="material-symbols-outlined text-primary-container select-none ml-4">
                      {isOpen ? 'expand_less' : 'expand_more'}
                    </span>
                  </button>
                  
                  {isOpen && (
                    <div className="p-5 pt-0 text-text-secondary text-xs md:text-sm leading-relaxed border-t border-border-subtle/50 bg-[#161616]/30">
                      {faq.a}
                    </div>
                  )}
                </div>
              );
            })}
          </div>

        </div>
      </div>
    </>
  );
}
