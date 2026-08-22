"use client";
import Link from 'next/link';

export default function CookiePolicyPage() {
  return (
    <>
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern animate-fade-in"></div>

      <div className="flex-grow pt-32 pb-24 relative z-10">
        <div className="max-w-4xl mx-auto px-gutter">
          
          {/* Breadcrumbs */}
          <nav className="flex items-center gap-2 text-text-secondary text-xs mb-8 font-label-accent uppercase tracking-wider">
            <Link href="/" className="hover:text-primary-container transition-colors">Home</Link>
            <span className="material-symbols-outlined text-xs">chevron_right</span>
            <span className="text-primary-container">Cookie Policy</span>
          </nav>

          {/* Header */}
          <div className="border-b border-border-subtle pb-8 mb-10">
            <h1 className="font-serif text-3xl md:text-5xl font-bold text-white mb-4">Cookie Policy</h1>
            <p className="text-text-secondary text-sm">Last Updated: August 2, 2026</p>
          </div>

          {/* Content */}
          <div className="prose prose-invert max-w-none space-y-8 font-body-md text-text-secondary text-sm md:text-base leading-relaxed">
            <p>
              At <strong>Sunnah Grandeur</strong>, we believe in being clear and open about how we collect and use data. This policy provides detailed information about how we use cookies and local storage on our website.
            </p>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">1. Do We Use Cookies?</h2>
              <p>
                Our website does <strong>not</strong> use advertising cookies, marketing tracking pixels (such as Meta/Facebook Pixel), or third-party analytic trackers (such as Google Analytics) to monitor your browsing behavior or serve targeted ads.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">2. Use of Local Storage</h2>
              <p>
                Instead of cookies, we use your browser's standard <strong>localStorage</strong> to store user preferences that improve your experience:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li><strong>sunnah-theme:</strong> Used to save your dark mode or light mode preference so that the site loads with your chosen appearance on subsequent visits.</li>
              </ul>
              <p>
                This data is stored locally on your device and is not transmitted to our servers or shared with any third parties.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="font-serif text-xl md:text-2xl font-bold text-white">3. Controlling Your Settings</h2>
              <p>
                You can clear your browser's local storage or cookies at any time through your browser settings. Please note that clearing local storage will reset your visual preferences (like dark/light theme) to the site defaults.
              </p>
            </section>

            <section className="space-y-4 border-t border-border-subtle pt-8">
              <p>
                For questions regarding our privacy practices or data policies, please contact us at <a href="mailto:info@sunnahgrandeur.com" className="text-primary-container hover:underline">info@sunnahgrandeur.com</a>.
              </p>
            </section>
          </div>

        </div>
      </div>
    </>
  );
}
