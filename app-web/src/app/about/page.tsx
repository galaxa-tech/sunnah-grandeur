"use client";
import { useLanguageStore } from '@/store/useLanguageStore';
import { translations } from '@/translations';

export default function AboutPage() {
  const { language } = useLanguageStore();
  const t = translations[language];

  return (
    <>
      {/* Hero Section */}
      <section className="relative pt-section-padding pb-section-padding overflow-hidden geometric-texture mt-20">
        <div className="max-w-container-max mx-auto px-gutter relative z-10 grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          <div className="space-y-8">
            <span className="text-label-accent font-label-accent text-primary uppercase tracking-[0.2em]">{t.about.eyebrow}</span>
            <h1 className="font-serif text-4xl md:text-6xl font-bold text-white leading-tight">
              {t.about.title}
            </h1>
            <p className="text-body-lg font-body-lg text-text-secondary max-w-lg">
              {t.about.subtitle}
            </p>
          </div>
          <div className="relative h-[600px] w-full rounded-xl overflow-hidden border border-border-subtle shadow-lg group">
            <img
              alt="Sunnah Grandeur Heritage"
              className="w-full h-full object-cover rounded-lg transform group-hover:scale-105 transition-transform duration-700 ease-out"
              src="/about-image.jpg.png"
              onError={(e) => {
                e.currentTarget.src = 'https://lh3.googleusercontent.com/aida/ADBb0uhEEleu7KmJZIDy9o-R0e1n7ajgAMkENyQ4eHjdI4eQF3vTywhBkToaiHR9Wri96NN64i7sdHclPPVpRNUdvoSXdF59d4qSzwG1w_XHiLUvh838-UE1Woog14E6V3-19LDckStk_xuTsJvqDFf8BImFbh4GEmcgYt0syVIceAwHl2ugiPShK_VRzf64WhUtYCrvcfSypyUI1y-s1uKaTV92l8YhScZsofow7Y4QZLUxOOnthfZ42XzihYkrDRq3yIq2VB1P14_jsNs';
              }}
            />
            <div className="absolute inset-0 bg-gradient-to-t from-bg-primary via-transparent to-transparent opacity-80"></div>
          </div>
        </div>
      </section>

      {/* Values Section */}
      <section className="py-section-padding bg-surface-container-lowest border-y border-outline-variant/20">
        <div className="max-w-container-max mx-auto px-gutter text-center mb-16">
          <h2 className="text-headline-lg font-headline-lg text-primary mb-4">{t.about.pillarsTitle}</h2>
          <p className="text-body-md font-body-md text-text-secondary max-w-2xl mx-auto">{t.about.pillarsSubtitle}</p>
        </div>
        <div className="max-w-container-max mx-auto px-gutter grid grid-cols-1 md:grid-cols-3 gap-card-gap">
          {/* Pillar 1 */}
          <div className="bg-surface-card p-8 rounded-lg border border-border-subtle hover:border-primary/50 transition-colors duration-300 group flex flex-col items-center text-center">
            <div className="w-16 h-16 rounded-full bg-primary-container/10 flex items-center justify-center mb-6 group-hover:bg-primary-container/20 transition-colors">
              <span className="material-symbols-outlined text-primary text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>auto_awesome</span>
            </div>
            <h3 className="text-headline-md font-headline-md text-text-primary mb-3">{t.about.pillar1}</h3>
            <p className="text-body-md font-body-md text-text-secondary">{t.about.pillar1Desc}</p>
          </div>
          {/* Pillar 2 */}
          <div className="bg-surface-card p-8 rounded-lg border border-border-subtle hover:border-primary/50 transition-colors duration-300 group flex flex-col items-center text-center">
            <div className="w-16 h-16 rounded-full bg-primary-container/10 flex items-center justify-center mb-6 group-hover:bg-primary-container/20 transition-colors">
              <span className="material-symbols-outlined text-primary text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>verified</span>
            </div>
            <h3 className="text-headline-md font-headline-md text-text-primary mb-3">{t.about.pillar2}</h3>
            <p className="text-body-md font-body-md text-text-secondary">{t.about.pillar2Desc}</p>
          </div>
          {/* Pillar 3 */}
          <div className="bg-surface-card p-8 rounded-lg border border-border-subtle hover:border-primary/50 transition-colors duration-300 group flex flex-col items-center text-center">
            <div className="w-16 h-16 rounded-full bg-primary-container/10 flex items-center justify-center mb-6 group-hover:bg-primary-container/20 transition-colors">
              <span className="material-symbols-outlined text-primary text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>groups</span>
            </div>
            <h3 className="text-headline-md font-headline-md text-text-primary mb-3">{t.about.pillar3}</h3>
            <p className="text-body-md font-body-md text-text-secondary">{t.about.pillar3Desc}</p>
          </div>
        </div>
      </section>
    </>
  );
}
