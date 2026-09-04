"use client";
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useLanguageStore } from '@/store/useLanguageStore';
import { translations } from '@/translations';
import { Product } from '@/data/products';
import { categories } from '@/data/categories';
import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useCartStore } from '@/store/useCartStore';
import CartDrawer from '@/components/CartDrawer';

const LIVE_TOAST_MESSAGES = [
  { text: "✨ Someone in Dhaka just purchased Royal Amber Oudh", time: "3m ago" },
  { text: "📦 Same-Day Express Gift Packaging Active across BD", time: "Live" },
  { text: "🌿 New Batch: Aged Cambodian Agarwood Extrait Distilled", time: "Fresh" },
  { text: "🕌 Over 1,200+ Ummah members trust Sunnah Grandeur", time: "Verified" }
];

export default function HomePage() {
  const { language } = useLanguageStore();
  const t = translations[language];

  const [dbProducts, setDbProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeCategoryTab, setActiveCategoryTab] = useState<string>('all');
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [toastIndex, setToastIndex] = useState(0);
  const [showToast, setShowToast] = useState(true);

  const { addItem } = useCartStore();

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

  // Cycle live social proof toast
  useEffect(() => {
    const interval = setInterval(() => {
      setShowToast(false);
      setTimeout(() => {
        setToastIndex((prev) => (prev + 1) % LIVE_TOAST_MESSAGES.length);
        setShowToast(true);
      }, 500);
    }, 8000);
    return () => clearInterval(interval);
  }, []);

  const handleQuickAdd = (product: Product) => {
    addItem({
      id: product.id,
      name: product.name,
      price: product.price,
      image: product.image || '/products/PhotoshopExtension_Image_1.png',
      category: product.category,
      quantity: 1,
      size: product.type === 'perfume' ? '50ml Extrait' : 'Standard'
    });
    setIsCartOpen(true);
  };

  const filteredProducts = activeCategoryTab === 'all'
    ? dbProducts
    : dbProducts.filter((p) => {
        if (activeCategoryTab === 'fragrance') return p.categoryId === 'fragrance' || p.type === 'perfume';
        if (activeCategoryTab === 'salah') return p.categoryId === 'salah' || p.category.includes('Worship') || p.category.includes('Salah');
        if (activeCategoryTab === 'women') return p.categoryId === 'women' || p.category.includes('Women') || p.category.includes('Apparel');
        if (activeCategoryTab === 'home') return p.categoryId === 'home' || p.category.includes('Decor');
        return true;
      });

  return (
    <>
      <CartDrawer isOpen={isCartOpen} onClose={() => setIsCartOpen(false)} />

      {/* ── High-Fashion Editorial Hero Section ─────────────────────────────── */}
      <section className="relative min-h-[70vh] md:min-h-[75vh] flex items-center justify-center overflow-hidden bg-[#070605] pt-20 pb-12 islamic-geometric-grid">
        {/* Ambient Volumetric Lighting Glows */}
        <div className="absolute inset-0 pointer-events-none overflow-hidden">
          <div className="absolute top-1/3 left-1/4 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[700px] rounded-full bg-[#E6C364]/10 blur-[150px] animate-pulse" />
          <div className="absolute bottom-1/4 right-1/4 w-[600px] h-[600px] rounded-full bg-[#C9A84C]/8 blur-[130px]" />
          <div className="absolute top-10 right-10 w-40 h-40 rounded-full bg-[#FFE8A3]/10 blur-[60px]" />
        </div>

        {/* Top Gold Horizon Line */}
        <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-[#E6C364]/40 to-transparent" />

        <div className="relative z-10 w-full max-w-container-max mx-auto px-gutter grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-8 items-center">
          
          {/* Left Column — Editorial Copy & Actions */}
          <div className="lg:col-span-7 flex flex-col items-start space-y-6">
            
            {/* Pill Tagline */}
            <div className="inline-flex items-center gap-2.5 px-4 py-1.5 rounded-full bg-[#16130D] border border-primary/30 shadow-[0_0_15px_rgba(201,168,76,0.15)]">
              <span className="w-2 h-2 rounded-full bg-primary animate-ping" />
              <span className="font-mono text-[10px] sm:text-xs text-primary font-bold uppercase tracking-[0.25em]">
                Bespoke Artisanal Collection 2026
              </span>
            </div>

            {/* Main Headline */}
            <h1 className="font-serif-luxury text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-bold text-text-primary tracking-tight leading-[1.08]">
              The Pure Essence of <br />
              <span className="text-gold-gradient italic font-normal">Royal Agarwood & Musk</span>
            </h1>

            {/* Subtext */}
            <p className="text-text-secondary text-sm sm:text-base md:text-lg max-w-xl leading-relaxed font-light">
              Crafted in reverence to tradition. 100% alcohol-free pure extrait de parfum, aged Cambodian agarwood, and museum-grade Islamic lifestyle artifacts.
            </p>

            {/* Call to Actions */}
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-4 pt-2 w-full sm:w-auto">
              <Link
                href="/shop"
                className="group relative inline-flex items-center justify-center gap-3 bg-gradient-to-r from-[#E6C364] via-[#C9A84C] to-[#E6C364] text-black font-cinzel font-bold px-8 py-3.5 rounded-lg text-xs uppercase tracking-widest hover:shadow-[0_0_30px_rgba(201,168,76,0.5)] hover:brightness-110 transition-all duration-300"
              >
                <span>Explore Catalog</span>
                <span className="material-symbols-outlined text-base group-hover:translate-x-1 transition-transform">arrow_forward</span>
              </Link>
              
              <Link
                href="/about"
                className="inline-flex items-center justify-center gap-2 border border-primary/40 bg-[#12100C]/60 backdrop-blur-md text-primary font-cinzel px-8 py-3.5 rounded-lg text-xs uppercase tracking-widest hover:bg-primary/10 hover:border-primary transition-all duration-300"
              >
                <span>Our Heritage</span>
              </Link>
            </div>

            {/* Trust Micro-Badges */}
            <div className="pt-4 flex items-center gap-6 flex-wrap border-t border-primary/15 w-full">
              <div className="flex items-center gap-2 text-text-secondary text-xs">
                <span className="material-symbols-outlined text-primary text-base">verified</span>
                <span className="font-mono text-[11px] uppercase tracking-wider text-text-primary font-semibold">100% Halal Pure</span>
              </div>
              <div className="w-[1px] h-3 bg-border-subtle" />
              <div className="flex items-center gap-2 text-text-secondary text-xs">
                <span className="material-symbols-outlined text-primary text-base">water_drop</span>
                <span className="font-mono text-[11px] uppercase tracking-wider text-text-primary font-semibold">0% Alcohol</span>
              </div>
              <div className="w-[1px] h-3 bg-border-subtle" />
              <div className="flex items-center gap-2 text-text-secondary text-xs">
                <span className="material-symbols-outlined text-primary text-base">local_shipping</span>
                <span className="font-mono text-[11px] uppercase tracking-wider text-text-primary font-semibold">Fast BD Delivery</span>
              </div>
            </div>
          </div>

          {/* Right Column — Spotlight 3D Showcase */}
          <div className="lg:col-span-5 relative flex items-center justify-center">
            
            {/* Ambient Golden Frame Backing */}
            <div className="relative w-full max-w-md aspect-[4/5] rounded-2xl glass-card p-6 flex flex-col items-center justify-center overflow-hidden group">
              
              {/* Radial Center Aura */}
              <div className="absolute inset-0 spotlight-gold pointer-events-none opacity-80 group-hover:opacity-100 transition-opacity duration-700" />
              
              {/* Corner Notches for Islamic Architecture Feel */}
              <div className="absolute top-3 left-3 w-4 h-4 border-t-2 border-l-2 border-primary/50" />
              <div className="absolute top-3 right-3 w-4 h-4 border-t-2 border-r-2 border-primary/50" />
              <div className="absolute bottom-3 left-3 w-4 h-4 border-b-2 border-l-2 border-primary/50" />
              <div className="absolute bottom-3 right-3 w-4 h-4 border-b-2 border-r-2 border-primary/50" />

              {/* Floating Badge Top */}
              <div className="absolute top-6 px-4 py-1 rounded-full bg-[#1A160F] border border-primary/40 text-primary font-mono text-[10px] uppercase tracking-widest font-bold z-20">
                Flagship Extrait • 50 ML
              </div>

              {/* Main Perfume Render */}
              <div className="relative z-10 py-6 transform group-hover:scale-105 transition-transform duration-700 flex items-center justify-center">
                <img
                  src="/products/PhotoshopExtension_Image_3.png"
                  alt="Royal Amber Oudh Parfum"
                  className="max-h-[320px] sm:max-h-[380px] w-auto object-contain drop-shadow-[0_25px_50px_rgba(201,168,76,0.35)]"
                />
              </div>

              {/* Floating Bottom Card */}
              <div className="relative z-20 w-full bg-[#12100C]/90 border border-primary/30 p-3.5 rounded-xl backdrop-blur-xl flex items-center justify-between mt-auto">
                <div>
                  <span className="text-[9px] font-mono text-primary uppercase tracking-widest font-bold block">Signature Release</span>
                  <h4 className="text-sm font-serif-luxury font-bold text-text-primary">Oud Al-Majd Extrait</h4>
                </div>
                <div className="text-right">
                  <span className="text-xs font-mono font-bold text-primary block">৳1,850 BDT</span>
                  <span className="text-[9px] text-emerald-400 font-mono">In Stock • 50ml</span>
                </div>
              </div>

            </div>
          </div>

        </div>

        {/* Bottom Fade */}
        <div className="absolute bottom-0 left-0 w-full h-12 bg-gradient-to-t from-bg-primary to-transparent pointer-events-none" />
      </section>

      {/* ── All Categories Grid Section (Directly after Hero) ──────────────── */}
      <section className="py-16 bg-[#0B0A08]/90 border-y border-primary/15 relative overflow-hidden">
        <div className="max-w-container-max mx-auto px-gutter relative z-10">
          
          {/* Header */}
          <div className="flex flex-col sm:flex-row sm:items-end justify-between mb-10 gap-4">
            <div>
              <span className="text-primary font-mono text-[10px] uppercase tracking-[0.3em] font-bold block mb-1">
                Explore Collections
              </span>
              <h2 className="font-serif-luxury text-3xl sm:text-4xl font-bold text-text-primary">
                Browse All Categories
              </h2>
            </div>
            <Link
              href="/shop"
              className="inline-flex items-center gap-2 text-primary font-mono text-xs uppercase tracking-widest font-bold hover:text-[#FFE8A3] transition-colors"
            >
              <span>View Full Boutique</span>
              <span className="material-symbols-outlined text-sm">arrow_forward</span>
            </Link>
          </div>

          {/* 12 Categories Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3.5">
            {categories.map((cat) => (
              <Link
                key={cat.id}
                href={`/shop?cat=${cat.id}`}
                className="group relative rounded-xl glass-card glass-card-hover flex flex-col items-center text-center justify-end min-h-[160px] overflow-hidden"
              >
                {cat.featuredImage ? (
                  <>
                    <img
                      src={cat.featuredImage}
                      alt={cat.name}
                      className="absolute inset-0 w-full h-full object-cover opacity-60 group-hover:opacity-80 group-hover:scale-105 transition-all duration-500"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black via-black/50 to-transparent" />
                  </>
                ) : (
                  <div className="absolute inset-0" style={{ background: cat.gradient }} />
                )}

                <div className="relative z-10 p-4 w-full flex flex-col items-center">
                  <div className="w-9 h-9 rounded-full bg-black/50 border border-primary/30 backdrop-blur-sm flex items-center justify-center text-primary group-hover:scale-110 group-hover:bg-primary group-hover:text-black transition-all duration-300 mb-2">
                    <span className="material-symbols-outlined text-lg">{cat.icon}</span>
                  </div>

                  <h3 className="font-cinzel text-xs font-bold text-text-primary group-hover:text-primary transition-colors">
                    {cat.name}
                  </h3>
                  <span className="text-[9px] font-mono text-text-secondary/80 mt-0.5 block">
                    {cat.subcategories.length} Styles
                  </span>
                </div>
              </Link>
            ))}
          </div>

        </div>
      </section>

      {/* ── Signature Artifacts & Curated Products Section ─────────────────── */}
      <section className="py-16 max-w-container-max mx-auto px-gutter">
        
        {/* Section Header with Category Filter Tabs */}
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-10 gap-6 border-b border-border-subtle pb-6">
          <div>
            <span className="text-primary font-mono text-xs uppercase tracking-[0.25em] font-bold block mb-2">
              Curated Artisanal Goods
            </span>
            <h2 className="font-serif-luxury text-3xl sm:text-4xl font-bold text-text-primary">
              Signature Creations
            </h2>
          </div>

          {/* Filter Pills */}
          <div className="flex items-center gap-2 overflow-x-auto pb-2 md:pb-0 scrollbar-none">
            {[
              { id: 'all', label: 'All Artifacts' },
              { id: 'fragrance', label: 'Royal Attars' },
              { id: 'salah', label: 'Salah & Tasbih' },
              { id: 'women', label: 'Apparel' },
              { id: 'home', label: 'Home Decor' }
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveCategoryTab(tab.id)}
                className={`px-4 py-2 rounded-full font-mono text-xs uppercase tracking-wider transition-all duration-300 flex-shrink-0 ${
                  activeCategoryTab === tab.id
                    ? 'bg-primary text-black font-bold shadow-[0_0_15px_rgba(201,168,76,0.3)]'
                    : 'bg-[#12100C] text-text-secondary border border-border-subtle hover:border-primary/50 hover:text-text-primary'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        {/* Products Grid */}
        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-96 rounded-xl bg-[#12100C] border border-border-subtle animate-pulse" />
            ))}
          </div>
        ) : filteredProducts.length === 0 ? (
          <div className="text-center py-16 p-8 rounded-2xl glass-card">
            <span className="material-symbols-outlined text-primary text-4xl mb-3">inventory_2</span>
            <h3 className="font-serif-luxury text-xl font-bold text-text-primary mb-1">No items found in this collection</h3>
            <p className="text-xs text-text-secondary mb-4">Please check back soon as our master perfumers distill new batches.</p>
            <button
              onClick={() => setActiveCategoryTab('all')}
              className="px-6 py-2 rounded bg-primary/10 border border-primary/30 text-primary text-xs font-mono uppercase font-bold hover:bg-primary hover:text-black transition-all"
            >
              Reset Filter
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredProducts.map((product) => (
              <div
                key={product.id}
                className="group relative rounded-2xl glass-card glass-card-hover overflow-hidden flex flex-col justify-between"
              >
                {/* Image Container with Ambient Spotlight */}
                <div className="relative aspect-[4/5] bg-[#0A0907] overflow-hidden">
                  <div className="absolute inset-0 spotlight-gold opacity-50 group-hover:opacity-100 transition-opacity duration-500" />
                  
                  {/* Badges */}
                  <div className="absolute top-3.5 left-3.5 z-10 flex flex-col gap-1.5">
                    {product.tag && (
                      <span className="px-3 py-1 text-[9px] font-mono font-bold uppercase tracking-widest rounded-full bg-primary text-black shadow-md">
                        {product.tag}
                      </span>
                    )}
                  </div>

                  {product.originalPrice && product.originalPrice > product.price && (
                    <span className="absolute top-3.5 right-3.5 z-10 bg-red-500/90 backdrop-blur-md text-white font-mono px-2.5 py-0.5 text-[9px] font-bold rounded-full">
                      ৳{(product.originalPrice - product.price).toFixed(0)} OFF
                    </span>
                  )}

                  {/* Product Image */}
                  <Link href={`/product/${product.id}`} className="w-full h-full flex items-center justify-center p-6 block">
                    {product.image ? (
                      <img
                        src={product.image}
                        alt={product.name}
                        className="max-h-full max-w-full object-contain group-hover:scale-108 transition-transform duration-500 drop-shadow-[0_15px_30px_rgba(0,0,0,0.8)]"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-primary/30">
                        <span className="material-symbols-outlined text-6xl">spa</span>
                      </div>
                    )}
                  </Link>

                  {/* Slide-Up Quick Add Button */}
                  <div className="absolute bottom-0 left-0 w-full p-3 translate-y-full group-hover:translate-y-0 transition-transform duration-300 bg-gradient-to-t from-black via-black/80 to-transparent z-20">
                    <button
                      onClick={() => handleQuickAdd(product)}
                      className="w-full bg-gradient-to-r from-[#E6C364] to-[#C9A84C] text-black font-cinzel font-bold py-2.5 px-4 rounded-lg text-xs uppercase tracking-widest hover:brightness-110 shadow-lg transition-all"
                    >
                      Quick Add • ৳{product.price.toLocaleString()}
                    </button>
                  </div>
                </div>

                {/* Product Meta Info */}
                <div className="p-5 flex flex-col justify-between flex-grow bg-[#0D0C0A]/60">
                  <div className="space-y-1.5">
                    <span className="text-[9px] font-mono text-primary/80 uppercase tracking-widest font-bold block">
                      {product.category || "Luxury Islamic Lifestyle"}
                    </span>
                    <Link href={`/product/${product.id}`} className="block hover:text-primary transition-colors">
                      <h3 className="font-serif-luxury text-lg font-bold text-text-primary line-clamp-1">
                        {product.name}
                      </h3>
                    </Link>
                    <p className="text-text-secondary text-xs line-clamp-2 leading-relaxed">
                      {product.description}
                    </p>
                  </div>

                  {/* Price & Action */}
                  <div className="mt-4 pt-3 border-t border-border-subtle flex items-center justify-between">
                    <div>
                      <span className="font-mono text-base font-bold text-primary">
                        ৳{product.price.toLocaleString()}
                      </span>
                      {product.originalPrice && (
                        <span className="font-mono text-xs text-text-secondary line-through ml-2">
                          ৳{product.originalPrice.toLocaleString()}
                        </span>
                      )}
                    </div>

                    <Link
                      href={`/product/${product.id}`}
                      className="text-[11px] font-mono text-text-secondary hover:text-primary flex items-center gap-1 uppercase tracking-wider font-bold transition-colors"
                    >
                      <span>Details</span>
                      <span className="material-symbols-outlined text-sm">arrow_forward</span>
                    </Link>
                  </div>
                </div>

              </div>
            ))}
          </div>
        )}

        <div className="mt-12 text-center">
          <Link
            href="/shop"
            className="inline-flex items-center gap-2 border border-primary/50 text-primary hover:bg-primary hover:text-black font-cinzel font-bold px-8 py-3.5 rounded-lg text-xs uppercase tracking-widest transition-all duration-300"
          >
            <span>View Complete Boutique Catalog</span>
            <span className="material-symbols-outlined text-base">arrow_forward</span>
          </Link>
        </div>
      </section>

      {/* ── 4 Pillars of Excellence ─────────────────────────────── */}
      <section className="border-y border-border-subtle bg-[#0B0A08] py-12">
        <div className="max-w-container-max mx-auto px-gutter grid grid-cols-2 md:grid-cols-4 gap-8">
          {[
            { icon: "local_shipping", title: "Express Dispatch", desc: "Reliable doorstep delivery in BD" },
            { icon: "verified", title: "100% Halal Verified", desc: "Pure formulations without alcohol" },
            { icon: "workspace_premium", title: "Artisanal Distillation", desc: "Aged agarwood & natural oils" },
            { icon: "support_agent", title: "Dedicated Concierge", desc: "Personal styling & assistance" }
          ].map((item, idx) => (
            <div key={idx} className="flex flex-col items-center text-center space-y-2 group">
              <div className="w-12 h-12 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center text-primary group-hover:scale-110 group-hover:bg-primary group-hover:text-black transition-all duration-300">
                <span className="material-symbols-outlined text-2xl">{item.icon}</span>
              </div>
              <h4 className="font-cinzel text-xs font-bold text-text-primary tracking-wider uppercase">{item.title}</h4>
              <p className="text-[11px] text-text-secondary">{item.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── Live Brand Social Proof Toast (Bottom-Left) ────────────────── */}
      {showToast && (
        <div className="fixed bottom-6 left-6 z-40 max-w-sm bg-[#12100C]/95 border border-primary/40 rounded-xl p-3.5 shadow-2xl backdrop-blur-xl animate-fadeIn hidden sm:flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-primary/20 border border-primary/30 flex items-center justify-center text-primary flex-shrink-0">
            <span className="material-symbols-outlined text-lg">auto_awesome</span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs text-text-primary font-medium line-clamp-1">
              {LIVE_TOAST_MESSAGES[toastIndex].text}
            </p>
            <span className="text-[9px] font-mono text-primary uppercase font-bold tracking-wider">
              {LIVE_TOAST_MESSAGES[toastIndex].time}
            </span>
          </div>
        </div>
      )}
    </>
  );
}
