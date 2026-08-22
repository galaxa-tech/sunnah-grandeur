"use client";
import Link from 'next/link';

export default function SupportPage() {
  const topics = [
    { title: "Order Inquiries", desc: "Questions about placing an order, order changes, or billing details." },
    { title: "Order Status", desc: "Request updates on processing, packaging, or tracking information." },
    { title: "Shipping & Delivery", desc: "Inquiries regarding delivery timelines within the USA." },
    { title: "Payment Questions", desc: "Information on accepted payment methods and billing." },
    { title: "Damaged / Incorrect Items", desc: "Report items damaged in transit or incorrect product shipments." },
    { title: "Exchange Requests", desc: "Initiate product size, variation, or perfume exchanges." },
    { title: "Product Information", desc: "Details on fragrance notes, ingredients, or lifestyle artifacts." },
    { title: "General Support", desc: "Any other questions or feedback about Sunnah Grandeur." },
  ];

  return (
    <>
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern animate-fade-in"></div>

      <div className="flex-grow pt-32 pb-24 relative z-10">
        <div className="max-w-5xl mx-auto px-gutter">
          
          {/* Breadcrumbs */}
          <nav className="flex items-center gap-2 text-text-secondary text-xs mb-8 font-label-accent uppercase tracking-wider">
            <Link href="/" className="hover:text-primary-container transition-colors">Home</Link>
            <span className="material-symbols-outlined text-xs">chevron_right</span>
            <span className="text-primary-container">Customer Support</span>
          </nav>

          {/* Header */}
          <div className="border-b border-border-subtle pb-8 mb-12">
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-white mb-4">Customer Support</h1>
            <p className="text-text-secondary text-sm md:text-base max-w-2xl">
              We are here to assist the Ummah with any questions regarding our premium collections or services. Reach out to experience true grandeur.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
            
            {/* Left/Main Column - Topics Grid */}
            <div className="lg:col-span-2 space-y-8">
              <h2 className="font-serif text-2xl font-bold text-white mb-6">Support Topics</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {topics.map((topic, index) => (
                  <div key={index} className="bg-surface-card border border-border-subtle p-6 rounded-lg hover:border-primary-container transition-colors">
                    <h3 className="font-serif text-lg font-semibold text-white mb-2">{topic.title}</h3>
                    <p className="text-text-secondary text-xs md:text-sm leading-relaxed">{topic.desc}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Right Column - Contact Channels */}
            <div className="space-y-6">
              <div className="bg-surface-card border border-border-subtle p-6 rounded-lg space-y-6">
                <h2 className="font-serif text-xl font-bold text-white border-b border-border-subtle pb-3">Contact Channels</h2>
                
                <div className="space-y-4">
                  <div className="flex items-start gap-3">
                    <span className="material-symbols-outlined text-primary-container text-xl mt-0.5">mail</span>
                    <div>
                      <p className="text-xs font-semibold text-text-primary uppercase tracking-wider font-label-accent">Email Support</p>
                      <a href="mailto:info@sunnahgrandeur.com" className="text-sm text-primary-container hover:underline font-bold">info@sunnahgrandeur.com</a>
                    </div>
                  </div>

                  <div className="flex items-start gap-3 pt-3 border-t border-border-subtle/50">
                    <span className="material-symbols-outlined text-primary-container text-xl mt-0.5">location_on</span>
                    <div>
                      <p className="text-xs font-semibold text-text-primary uppercase tracking-wider font-label-accent">Office Address</p>
                      <p className="text-xs text-text-secondary whitespace-pre-line leading-relaxed">
                        3715 73rd St, Suite 205
                        Jackson Heights, NY 11372
                        USA
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Policy Quick Notes */}
              <div className="bg-primary-container/5 border border-primary-container/10 p-6 rounded-lg space-y-4">
                <h3 className="text-sm font-bold text-primary-container uppercase tracking-wider font-label-accent">Policy Highlights</h3>
                
                <div className="text-xs space-y-3 text-text-secondary leading-relaxed">
                  <p>
                    <strong className="text-text-primary">Damaged & Incorrect Items:</strong> Please contact support within 48 hours of delivery and provide clear photos of the damaged or incorrect item.
                  </p>
                  <p>
                    <strong className="text-text-primary">Exchanges:</strong> All exchange requests are processed directly from our Jackson Heights office.
                  </p>
                  <p>
                    <strong className="text-text-primary">Returns:</strong> For questions regarding returns or refunds, please contact our support team.
                  </p>
                </div>
              </div>

            </div>

          </div>

        </div>
      </div>
    </>
  );
}
