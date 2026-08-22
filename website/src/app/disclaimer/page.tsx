"use client";
import Link from 'next/link';

export default function DisclaimerPage() {
  return (
    <>
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern animate-fade-in"></div>

      <div className="flex-grow pt-32 pb-24 relative z-10">
        <div className="max-w-4xl mx-auto px-gutter">
          
          {/* Breadcrumbs */}
          <nav className="flex items-center gap-2 text-text-secondary text-xs mb-8 font-label-accent uppercase tracking-wider">
            <Link href="/" className="hover:text-primary-container transition-colors">Home</Link>
            <span className="material-symbols-outlined text-xs">chevron_right</span>
            <span className="text-primary-container">Disclaimer</span>
          </nav>

          {/* Header */}
          <div className="border-b border-border-subtle pb-8 mb-10">
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-white mb-4">Disclaimer</h1>
            <p className="text-text-secondary text-sm">Last Updated: August 2, 2026</p>
          </div>

          {/* Content */}
          <div className="prose prose-invert max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            
            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">1. General Information</h2>
              <p>
                The information provided on the <strong>Sunnah Grandeur</strong> website is for general informational purposes only. While we endeavor to keep the information up-to-date and correct, we make no representations or warranties of any kind, express or implied, about the completeness, accuracy, reliability, suitability, or availability of the website or the information, products, services, or related graphics contained on the website.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">2. Product Accuracy & Descriptions</h2>
              <p>
                Product descriptions, images, and pricing are intended to be as accurate as possible. However, occasional typographical errors, description inaccuracies, or pricing mistakes may occur. We reserve the right to correct any errors, inaccuracies, or omissions, and to change or update information at any time without prior notice.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">3. Fragrance Performance & Individual Sensitivities</h2>
              <p>
                Fragrance performance, projection, and longevity may vary significantly depending on individual skin chemistry, type, ambient climate, and application methods.
              </p>
              <p>
                We construct our premium fragrances and alcohol-free attars using high-quality ingredients. However, we strongly encourage all customers to perform a **patch test** on a small area of skin before regular use to ensure compatibility.
              </p>
              <p>
                Sunnah Grandeur is not responsible for any individual allergic reactions, skin irritations, or adverse effects resulting from sensitivities to ingredients or product misuse. If irritation occurs, discontinue use immediately and consult a qualified medical professional.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">4. No Medical Claims</h2>
              <p>
                Any information, statements, or product descriptions on this website are not intended to diagnose, treat, cure, or prevent any health condition or disease. They should not be used as a substitute for professional medical advice.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">5. Intellectual Property</h2>
              <p>
                All trademarks, logos, brand emblems, custom photography, graphics, text, and other content displayed on this website are the property of Sunnah Grandeur and their respective owners. No content may be copied, reproduced, or used without our express prior written permission.
              </p>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <p>
                For questions or support regarding our products, please contact us at <a href="mailto:info@sunnahgrandeur.com" className="text-primary-container hover:underline">info@sunnahgrandeur.com</a>.
              </p>
            </section>
          </div>

        </div>
      </div>
    </>
  );
}
