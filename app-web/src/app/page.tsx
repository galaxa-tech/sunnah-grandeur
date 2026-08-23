"use client";
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useLanguageStore } from '@/store/useLanguageStore';
import { translations } from '@/translations';
import { products, Product } from '@/data/products';
import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';

const BROWSE_IDS = ['7', '8', '11', '13', '16', '17', '19', '22', '24', '26', '28', '29'];

export default function HomePage() {
  const { language } = useLanguageStore();
  const t = translations[language];

  const [dbProducts, setDbProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, 'products'), where('isActive', '==', true));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list: Product[] = [];
      snapshot.forEach((doc) => {
        list.push({ id: doc.id, ...doc.data() } as Product);
      });
      setDbProducts(list);
      setLoading(false);
    }, (error) => {
      console.error('Error listening to Firestore products:', error);
      setDbProducts([]);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  const browseProducts = BROWSE_IDS
    .map((id) => dbProducts.find((p) => p.id === id))
    .filter(Boolean) as Product[];

  return (
    <>
      {/* Hero Section */}
      <section className="relative min-h-[42vh] md:min-h-[52vh] lg:min-h-[55vh] flex items-center overflow-hidden bg-[#070707]">
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[900px] h-[900px] rounded-full bg-[#C9A84C]/10 blur-[140px]" />
          <div className="absolute bottom-0 right-1/4 w-[500px] h-[500px] rounded-full bg-[#C9A84C]/8 blur-[100px]" />
          <div className="absolute top-1/4 left-1/4 w-[300px] h-[300px] rounded-full bg-[#C9A84C]/6 blur-[80px]" />
        </div>
        <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-[#C9A84C]/40 to-transparent" />

        <div className="relative z-10 w-full max-w-container-max mx-auto px-gutter grid grid-cols-1 lg:grid-cols-2 gap-6 items-center pt-20 pb-6">
          <div className="flex flex-col items-start">
            <span className="inline-flex items-center gap-2 text-primary-container text-label-accent font-label-accent tracking-[0.25em] uppercase mb-3 text-xs">
              <span className="block w-8 h-[1px] bg-primary-container" />
              {t.hero.newCollection}
              <span className="block w-8 h-[1px] bg-primary-container" />
            </span>
            <h1 className="text-3xl md:text-5xl font-serif font-bold text-text-primary mb-4 whitespace-pre-line leading-tight">
              {t.hero.title}
            </h1>
            <p className="text-sm md:text-base text-text-secondary mb-6 max-w-md leading-relaxed">
              {t.hero.subtitle}
            </p>
            <div className="flex flex-col sm:flex-row items-start gap-3">
              <Link
                href="/shop"
                className="bg-primary-container text-bg-primary px-6 py-2.5 text-label-accent font-label-accent uppercase tracking-widest hover:shadow-[0_0_24px_rgba(201,168,76,0.5)] hover:bg-[#e6c364] transition-all duration-300 text-center"
              >
                {t.hero.shopBtn}
              </Link>
              <Link
                href="/about"
                className="border border-primary-container/60 text-primary-container px-6 py-2.5 text-label-accent font-label-accent uppercase tracking-widest hover:bg-primary-container/10 hover:border-primary-container transition-all duration-300 text-center"
              >
                {t.hero.exploreBtn}
              </Link>
            </div>
            <div className="mt-6 flex items-center gap-4 flex-wrap">
              <div className="flex items-center gap-1.5 text-text-secondary text-xs">
                <span className="material-symbols-outlined text-primary-container text-sm">verified</span>
                100% Halal
              </div>
              <div className="w-[1px] h-3 bg-border-subtle" />
              <div className="flex items-center gap-1.5 text-text-secondary text-xs">
                <span className="material-symbols-outlined text-primary-container text-sm">water_drop</span>
                0% Alcohol
              </div>
              <div className="w-[1px] h-3 bg-border-subtle" />
              <div className="flex items-center gap-1.5 text-text-secondary text-xs">
                <span className="material-symbols-outlined text-primary-container text-sm">workspace_premium</span>
                50 ML Premium
              </div>
            </div>
          </div>

          {/* Right — Product showcase */}
          <div className="relative flex items-center justify-center h-[220px] md:h-[280px] lg:h-[320px]">
            <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
              <div className="w-40 h-40 rounded-full bg-[#C9A84C]/15 blur-[50px]" />
            </div>
            <div className="absolute left-4 sm:left-10 bottom-8 z-10 opacity-75 hover:opacity-100 transition-opacity duration-500">
              <img src="/products/PhotoshopExtension_Image_1.png" alt="Perfume" className="h-28 sm:h-36 md:h-44 w-auto object-contain drop-shadow-[0_20px_40px_rgba(201,168,76,0.25)] hover:scale-105 transition-transform duration-500" />
            </div>
            <div className="absolute z-20 bottom-4">
              <img src="/products/PhotoshopExtension_Image_3.png" alt="Perfume" className="h-36 sm:h-48 md:h-56 w-auto object-contain drop-shadow-[0_24px_60px_rgba(201,168,76,0.35)] hover:scale-105 transition-transform duration-500" />
            </div>
            <div className="absolute right-4 sm:right-10 bottom-8 z-10 opacity-75 hover:opacity-100 transition-opacity duration-500">
              <img src="/products/PhotoshopExtension_Image_2.png" alt="Perfume" className="h-28 sm:h-36 md:h-44 w-auto object-contain drop-shadow-[0_20px_40px_rgba(201,168,76,0.25)] hover:scale-105 transition-transform duration-500" />
            </div>
            <div className="absolute bottom-1 left-1/2 -translate-x-1/2 w-48 h-[1px] bg-gradient-to-r from-transparent via-[#C9A84C]/50 to-transparent" />
          </div>
        </div>
        <div className="absolute bottom-0 left-0 w-full h-16 bg-gradient-to-t from-[#070707] to-transparent pointer-events-none" />
      </section>

      {/* ── Browse Categories Section ─────────────────────────────── */}
      <section className="py-12 bg-surface-card/20 border-y border-border-subtle">
        <div className="max-w-container-max mx-auto px-gutter">
          {/* Header */}
          <div className="flex flex-col sm:flex-row sm:items-end justify-between mb-8 gap-4">
            <div>
              <span className="text-primary-container text-label-accent font-label-accent tracking-[0.2em] uppercase text-xs mb-2 block">Explore</span>
              <h2 className="text-2xl md:text-3xl font-serif font-bold text-text-primary">Browse Categories</h2>
            </div>
            <Link
              href="/shop"
              className="inline-flex items-center gap-2 text-primary-container text-label-accent font-label-accent uppercase tracking-wider text-xs border-b border-primary-container/50 hover:border-primary-container pb-0.5 transition-colors flex-shrink-0"
            >
              View All
              <span className="material-symbols-outlined text-sm">arrow_forward</span>
            </Link>
          </div>

          {/* Product grid */}
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
            {browseProducts.map((product) => (
              <Link
                key={product.id}
                href={`/shop?cat=${product.categoryId}`}
                className="group relative bg-surface-card rounded-DEFAULT border border-border-subtle hover:border-primary-container transition-all duration-300 overflow-hidden flex flex-col"
              >
                <div className="relative aspect-square overflow-hidden">
                  {product.image ? (
                    <img
                      src={product.image}
                      alt={product.name}
                      className="w-full h-full object-cover opacity-75 group-hover:scale-105 group-hover:opacity-100 transition-all duration-500"
                    />
                  ) : (
                    <div
                      className="w-full h-full flex flex-col items-center justify-center gap-1.5"
                      style={{ background: product.bgGradient ?? 'linear-gradient(145deg,#1a1206,#2d1f08)' }}
                    >
                      {product.bgIcon && (
                        <span
                          className="material-symbols-outlined opacity-30 group-hover:opacity-50 transition-opacity"
                          style={{ fontSize: '40px', color: '#C9A84C' }}
                        >
                          {product.bgIcon}
                        </span>
                      )}
                    </div>
                  )}
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                  <div className="absolute bottom-2 left-0 right-0 text-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                    <span className="text-[9px] text-primary-container font-bold uppercase tracking-widest">Shop Now</span>
                  </div>
                </div>
                <div className="p-2.5">
                  <p className="text-[9px] text-primary-container/60 uppercase tracking-widest font-bold">{product.category}</p>
                  <h4 className="text-text-primary font-bold text-[11px] leading-tight line-clamp-2 mt-0.5">{product.name}</h4>
                  <p className="text-primary-container font-bold text-xs mt-1">৳{product.price}</p>
                </div>
              </Link>
            ))}
          </div>

          {/* CTA */}
          <div className="mt-10 text-center">
            <Link
              href="/shop"
              className="inline-flex items-center gap-3 bg-primary-container text-bg-primary px-8 py-3 text-label-accent font-label-accent uppercase tracking-widest hover:shadow-[0_0_24px_rgba(201,168,76,0.4)] hover:bg-[#e6c364] transition-all duration-300"
            >
              Browse All Categories
              <span className="material-symbols-outlined text-base">arrow_forward</span>
            </Link>
          </div>
        </div>
      </section>

      {/* ── Signature Collection Section ──────────────────────────── */}
      <section className="pt-12 pb-16 max-w-container-max mx-auto px-gutter">
        <div className="flex flex-col sm:flex-row sm:items-end justify-between mb-6 gap-4">
          <div>
            <span className="text-primary-container text-label-accent font-label-accent tracking-[0.2em] uppercase text-xs mb-2 block">Limited Edition</span>
            <h2 className="text-headline-lg font-headline-lg text-text-primary">{t.sections.featured}</h2>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-card-gap">
          {dbProducts.slice(0, 6).map((product) => (
            <div key={product.id} className="group relative bg-surface-card rounded-DEFAULT border border-border-subtle hover:border-primary-container transition-colors duration-300 overflow-hidden flex flex-col h-full">
              <Link href={`/product/${product.id}`} className="relative aspect-[4/5] bg-bg-primary overflow-hidden block">
                {product.tag && (
                  <span className={`absolute top-4 left-4 z-10 px-3 py-1 text-[10px] font-label-accent uppercase rounded-full ${
                    product.isSoldOut ? 'bg-[#1F1F1F] text-text-secondary border border-border-subtle' : 'bg-primary-container text-bg-primary'
                  }`}>
                    {product.isSoldOut ? t.cart.outOfStock : product.tag}
                  </span>
                )}
                {product.originalPrice && !product.isSoldOut && (
                  <span className="absolute top-4 right-4 z-10 bg-red-600 text-white px-2 py-1 text-[10px] font-bold rounded-full">
                    ৳{product.originalPrice - product.price} Off
                  </span>
                )}
                <img
                  className={`w-full h-full object-cover transition-all duration-500 ${
                    product.isSoldOut ? 'opacity-40 grayscale' : 'opacity-80 group-hover:scale-105 group-hover:opacity-100'
                  }`}
                  src={product.image}
                  alt={product.name}
                />
                <div className="absolute bottom-0 left-0 w-full p-4 translate-y-full group-hover:translate-y-0 transition-transform duration-300 bg-gradient-to-t from-bg-primary to-transparent">
                  {product.isSoldOut ? (
                    <button className="w-full bg-[#1F1F1F] text-text-secondary py-3 text-label-accent font-label-accent uppercase rounded-DEFAULT cursor-not-allowed">{t.cart.outOfStock}</button>
                  ) : (
                    <button className="w-full bg-primary-container text-bg-primary py-3 text-label-accent font-label-accent uppercase rounded-DEFAULT hover:bg-primary-fixed transition-colors">{t.cart.addToCart} — ৳{product.price}</button>
                  )}
                </div>
              </Link>
              <div className={`p-6 flex-grow flex flex-col justify-between ${product.isSoldOut ? 'opacity-60' : ''}`}>
                <div>
                  <Link href={`/product/${product.id}`} className="block hover:text-primary transition-colors">
                    <h4 className="text-body-lg font-body-lg text-text-primary mb-1">{product.name}</h4>
                  </Link>
                  <p className="text-body-md font-body-md text-text-secondary text-sm line-clamp-2">{product.description}</p>
                </div>
                <div className="mt-4 flex items-center gap-3">
                  <span className="text-body-lg font-body-lg text-primary-container">৳{product.price.toFixed(0)}</span>
                  {product.originalPrice && (
                    <span className="text-sm text-text-secondary line-through">৳{product.originalPrice}</span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-10 text-center">
          <Link
            href="/collections"
            className="inline-flex items-center gap-2 border border-primary-container text-primary-container px-8 py-3 text-label-accent font-label-accent uppercase tracking-widest hover:bg-primary-container hover:text-bg-primary transition-all duration-300"
          >
            {t.sections.viewAll} Collections
            <span className="material-symbols-outlined text-base">arrow_forward</span>
          </Link>
        </div>
      </section>

      {/* Trust Badges */}
      <section className="border-y border-border-subtle bg-surface-card/50 py-8">
        <div className="max-w-container-max mx-auto px-gutter grid grid-cols-2 md:grid-cols-4 gap-6 md:gap-8">
          <div className="flex flex-col items-center text-center">
            <span className="material-symbols-outlined text-primary-container text-3xl mb-3">local_shipping</span>
            <h3 className="text-label-accent font-label-accent text-text-primary uppercase mb-1 text-xs">Free Shipping</h3>
            <p className="text-body-md font-body-md text-text-secondary text-xs">On orders over ৳1500</p>
          </div>
          <div className="flex flex-col items-center text-center">
            <span className="material-symbols-outlined text-primary-container text-3xl mb-3">verified</span>
            <h3 className="text-label-accent font-label-accent text-text-primary uppercase mb-1 text-xs">100% Authentic</h3>
            <p className="text-body-md font-body-md text-text-secondary text-xs">Sourced ethically</p>
          </div>
          <div className="flex flex-col items-center text-center">
            <span className="material-symbols-outlined text-primary-container text-3xl mb-3">workspace_premium</span>
            <h3 className="text-label-accent font-label-accent text-text-primary uppercase mb-1 text-xs">Premium Quality</h3>
            <p className="text-body-md font-body-md text-text-secondary text-xs">Crafted with excellence</p>
          </div>
          <div className="flex flex-col items-center text-center">
            <span className="material-symbols-outlined text-primary-container text-3xl mb-3">support_agent</span>
            <h3 className="text-label-accent font-label-accent text-text-primary uppercase mb-1 text-xs">24/7 Support</h3>
            <p className="text-body-md font-body-md text-text-secondary text-xs">Dedicated assistance</p>
          </div>
        </div>
      </section>

      {/* Category Bento Grid */}
      <section className="py-section-padding max-w-container-max mx-auto px-gutter">
        <div className="text-center mb-10 md:mb-16">
          <h2 className="text-headline-lg font-headline-lg text-text-primary mb-4">{t.sections.categories}</h2>
          <p className="text-body-lg font-body-lg text-text-secondary">{t.sections.categoriesSubtitle}</p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-card-gap md:h-[600px]">
          <Link href="/shop" className="relative group overflow-hidden rounded-DEFAULT md:col-span-2 md:row-span-2 bg-surface-card border border-border-subtle hover:border-primary-container transition-colors duration-500 min-h-[280px]">
            <img className="absolute inset-0 w-full h-full object-cover opacity-60 group-hover:scale-105 transition-transform duration-700" src="https://lh3.googleusercontent.com/aida-public/AB6AXuB6MADiUgHSRO_Id9xXNAgsecIrCIlS1fNSgWMUXHp5mtWpmMu0iJ1rsOCsKthVbx4lUdf7v41RStvIF0ZQQKdcHAZ9n2RRsjSeCfsunmKD5EYX3wg4wtiDbEQpCujHbqBjwDmhQfI_ORMocBKtQwmhSuDX8St4XKUOjhHSr2IPFWVGEEuirz-IkowfX7o_xC8mfH_mafoBE71_yuaFXuOytQdRkHdISMG4l0VmDpV8iAWHPIJb6zn_5EOe9mlkYhbReBhL2E-xzUO4" alt="Artisanal Attar" />
            <div className="absolute inset-0 bg-gradient-to-t from-bg-primary/90 to-transparent" />
            <div className="absolute bottom-0 left-0 p-6 md:p-8 w-full flex justify-between items-end">
              <div>
                <h3 className="text-xl md:text-2xl font-serif font-bold text-text-primary mb-2">Artisanal Attar</h3>
                <p className="text-body-md font-body-md text-text-secondary text-sm">Pure, alcohol-free fragrance oils.</p>
              </div>
              <div className="bg-primary-container/20 text-primary-container group-hover:bg-primary-container group-hover:text-bg-primary p-3 rounded-full transition-all duration-300 flex-shrink-0">
                <span className="material-symbols-outlined">arrow_forward</span>
              </div>
            </div>
          </Link>
          <Link href="/shop" className="relative group overflow-hidden rounded-DEFAULT bg-surface-card border border-border-subtle hover:border-primary-container transition-colors duration-500 min-h-[200px] md:min-h-0">
            <img className="absolute inset-0 w-full h-full object-cover opacity-60 group-hover:scale-105 transition-transform duration-700" src="https://lh3.googleusercontent.com/aida-public/AB6AXuCWQl9pmpfziofAz-LzbNHb7R02zhgGJO8nZjY7x5lswsSAsR7LsQYq3NZeYPNsVlABSsbKKG_wKPf-Aokl0hc3XqlAv7Y6PsAPUiiKVCy3a2RC9FrwmyOQS0hJ95eUhXyEMj_hPLK9JfODYjFKUZqhmC3Yuhu7-GURgIAIJ4CzAcAHxVp_-V4WkqzEcWV5B_f6mVj6jCgqnFWLOPlCV-20MQVDT2zqAfw9XLqThd8yG4I2-lJlSL8C5oFASVmj6l5V_hQjlqTwhM3g" alt="Sunnah Essentials" />
            <div className="absolute inset-0 bg-gradient-to-t from-bg-primary/90 to-transparent" />
            <div className="absolute bottom-0 left-0 p-5 md:p-6 w-full">
              <h3 className="text-lg md:text-xl font-serif font-bold text-text-primary mb-1">Sunnah Essentials</h3>
              <p className="text-body-md font-body-md text-text-secondary text-sm mb-3 md:mb-4">Daily refined habits.</p>
              <span className="text-primary-container text-label-accent font-label-accent uppercase border-b border-primary-container pb-1 text-xs">Shop Now</span>
            </div>
          </Link>
          <Link href="/shop" className="relative group overflow-hidden rounded-DEFAULT bg-surface-card border border-border-subtle hover:border-primary-container transition-colors duration-500 min-h-[200px] md:min-h-0">
            <img className="absolute inset-0 w-full h-full object-cover opacity-60 group-hover:scale-105 transition-transform duration-700" src="https://lh3.googleusercontent.com/aida/ADBb0uhEEleu7KmJZIDy9o-R0e1n7ajgAMkENyQ4eHjdI4eQF3vTywhBkToaiHR9Wri96NN64i7sdHclPPVpRNUdvoSXdF59d4qSzwG1w_XHiLUvh838-UE1Woog14E6V3-19LDckStk_xuTsJvqDFf8BImFbh4GEmcgYt0syVIceAwHl2ugiPShK_VRzf64WhUtYCrvcfSypyUI1y-s1uKaTV92l8YhScZsofow7Y4QZLUxOOnthfZ42XzihYkrDRq3yIq2VB1P14_jsNs" alt="Modest Wear" />
            <div className="absolute inset-0 bg-gradient-to-t from-bg-primary/90 to-transparent" />
            <div className="absolute bottom-0 left-0 p-5 md:p-6 w-full">
              <h3 className="text-lg md:text-xl font-serif font-bold text-text-primary mb-1">Modest Wear</h3>
              <p className="text-body-md font-body-md text-text-secondary text-sm mb-3 md:mb-4">Elegance in simplicity.</p>
              <span className="text-primary-container text-label-accent font-label-accent uppercase border-b border-primary-container pb-1 text-xs">Shop Now</span>
            </div>
          </Link>
        </div>
      </section>
    </>
  );
}
