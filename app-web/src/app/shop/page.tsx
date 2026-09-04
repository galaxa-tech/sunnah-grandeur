"use client";
import { useState, useMemo, useEffect } from 'react';
import Link from 'next/link';
import { useLanguageStore } from '@/store/useLanguageStore';
import { translations } from '@/translations';
import { products, Product } from '@/data/products';
import { categories } from '@/data/categories';
import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useCartStore } from '@/store/useCartStore';
import CartDrawer from '@/components/CartDrawer';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function ProductCard({ product, t, onQuickAdd }: { product: Product; t: any; onQuickAdd: (p: Product) => void }) {
  return (
    <div className="group relative rounded-2xl glass-card glass-card-hover overflow-hidden flex flex-col justify-between h-full">
      {/* Image Area with Ambient Spotlight */}
      <div className="relative aspect-[4/5] bg-[#0A0907] overflow-hidden flex-shrink-0">
        <div className="absolute inset-0 spotlight-gold opacity-40 group-hover:opacity-90 transition-opacity duration-500" />

        {/* Badges */}
        <div className="absolute top-3 left-3 z-10 flex flex-col gap-1">
          {product.tag && (
            <span className={`px-2.5 py-0.5 text-[9px] font-mono font-bold uppercase tracking-widest rounded-full ${
              product.isSoldOut
                ? 'bg-[#1F1F1F] text-text-secondary border border-border-subtle'
                : 'bg-primary text-black shadow-md'
            }`}>
              {product.isSoldOut ? t.cart.outOfStock : product.tag}
            </span>
          )}
        </div>

        {product.originalPrice && product.originalPrice > product.price && !product.isSoldOut && (
          <span className="absolute top-3 right-3 z-10 bg-red-500/90 backdrop-blur-md text-white font-mono px-2 py-0.5 text-[9px] font-bold rounded-full">
            ৳{(product.originalPrice - product.price).toFixed(0)} Off
          </span>
        )}

        <Link href={`/product/${product.id}`} className="w-full h-full flex items-center justify-center p-4 block">
          {product.image ? (
            <img
              src={product.image}
              alt={product.name}
              className={`max-h-full max-w-full object-contain transition-all duration-500 drop-shadow-[0_15px_30px_rgba(0,0,0,0.8)] ${
                product.isSoldOut ? 'opacity-30 grayscale' : 'group-hover:scale-105 opacity-90 group-hover:opacity-100'
              }`}
            />
          ) : (
            <div
              className="w-full h-full flex flex-col items-center justify-center gap-2"
              style={{ background: product.bgGradient ?? 'linear-gradient(145deg,#16120b,#281c09)' }}
            >
              {product.bgIcon && (
                <span
                  className="material-symbols-outlined opacity-30 group-hover:opacity-50 transition-opacity"
                  style={{ fontSize: '48px', color: '#E6C364' }}
                >
                  {product.bgIcon}
                </span>
              )}
            </div>
          )}
        </Link>

        {/* Slide-Up Quick Add Overlay */}
        {!product.isSoldOut && (
          <div className="absolute bottom-0 left-0 w-full p-2.5 translate-y-full group-hover:translate-y-0 transition-transform duration-300 bg-gradient-to-t from-black via-black/80 to-transparent z-20">
            <button
              onClick={() => onQuickAdd(product)}
              className="w-full bg-gradient-to-r from-[#E6C364] to-[#C9A84C] text-black font-cinzel font-bold py-2 px-3 rounded text-[10px] uppercase tracking-widest hover:brightness-110 shadow transition-all"
            >
              {t.cart.addToCart} • ৳{product.price.toFixed(0)}
            </button>
          </div>
        )}
      </div>

      {/* Details Box */}
      <div className={`p-4 flex flex-col justify-between flex-grow bg-[#0D0C0A]/60 ${product.isSoldOut ? 'opacity-60' : ''}`}>
        <div className="space-y-1">
          <span className="text-[9px] font-mono text-primary/80 uppercase tracking-widest font-bold block">
            {product.category}
          </span>
          <Link href={`/product/${product.id}`} className="block hover:text-primary transition-colors">
            <h3 className="font-serif-luxury text-base font-bold text-text-primary line-clamp-1">
              {product.name}
            </h3>
          </Link>
          <p className="text-text-secondary text-[11px] line-clamp-2 leading-relaxed">
            {product.description}
          </p>
        </div>

        <div className="mt-3 pt-2.5 border-t border-border-subtle flex items-center justify-between">
          <div className="flex items-baseline gap-1.5">
            <span className="font-mono text-sm font-bold text-primary">
              ৳{product.price.toFixed(0)}
            </span>
            {product.originalPrice && (
              <span className="font-mono text-[10px] text-text-secondary line-through">
                ৳{product.originalPrice.toFixed(0)}
              </span>
            )}
          </div>

          <Link
            href={`/product/${product.id}`}
            className="text-[10px] font-mono text-text-secondary hover:text-primary uppercase font-bold tracking-wider"
          >
            View
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function ShopPage() {
  const { language } = useLanguageStore();
  const t = translations[language];

  const [dbProducts, setDbProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeFilter, setActiveFilter] = useState<string | null>(null);
  const [sortBy, setSortBy] = useState('featured');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [hoveredCat, setHoveredCat] = useState<string | null>(null);
  const [openMobileCat, setOpenMobileCat] = useState<string | null>(null);
  const [isCartOpen, setIsCartOpen] = useState(false);

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

  const filteredProducts = useMemo(() => {
    let list = activeFilter
      ? dbProducts.filter((p) => p.categoryId === activeFilter)
      : dbProducts;
    if (sortBy === 'priceLow') list = [...list].sort((a, b) => a.price - b.price);
    else if (sortBy === 'priceHigh') list = [...list].sort((a, b) => b.price - a.price);
    else if (sortBy === 'newest') list = [...list].reverse();
    return list;
  }, [dbProducts, activeFilter, sortBy]);

  const activeCategory = categories.find((c) => c.id === activeFilter);

  return (
    <div className="min-h-screen bg-[#070605] islamic-geometric-grid">
      <CartDrawer isOpen={isCartOpen} onClose={() => setIsCartOpen(false)} />

      {/* Page Header Banner */}
      <section className="relative pt-32 pb-10 border-b border-primary/20 bg-[#0A0907]/90 backdrop-blur-xl">
        <div className="max-w-container-max mx-auto px-gutter relative z-10">
          <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
            <div>
              <span className="text-primary font-mono text-[10px] uppercase tracking-[0.3em] font-bold block mb-1">
                Artisanal Islamic Boutique
              </span>
              <h1 className="font-serif-luxury text-3xl sm:text-4xl font-bold text-text-primary leading-tight">
                {activeCategory ? activeCategory.name : 'Exclusive Boutique Catalog'}
              </h1>
              <p className="text-text-secondary text-xs mt-1 font-mono">
                Showing {filteredProducts.length} verified item{filteredProducts.length !== 1 ? 's' : ''} in inventory
              </p>
            </div>
            
            <div className="flex items-center gap-3">
              <button
                onClick={() => setIsSidebarOpen(true)}
                className="flex items-center gap-2 lg:hidden bg-[#14120E] border border-primary/30 px-3.5 py-2 text-xs font-mono font-bold text-primary rounded-lg uppercase tracking-wider"
              >
                <span className="material-symbols-outlined text-sm">filter_list</span>
                Categories
              </button>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                className="bg-[#14120E] border border-primary/30 text-text-primary text-xs font-mono font-bold outline-none px-3.5 py-2 rounded-lg cursor-pointer uppercase tracking-wider hover:border-primary/60 transition-colors"
              >
                <option value="featured">{t.shop.featured}</option>
                <option value="priceLow">{t.shop.priceLow}</option>
                <option value="priceHigh">{t.shop.priceHigh}</option>
                <option value="newest">{t.shop.newest}</option>
              </select>
            </div>
          </div>
        </div>
      </section>

      <div className="max-w-container-max mx-auto px-gutter py-10">
        <div className="flex gap-8">

          {/* ── Desktop Categories Sidebar ── */}
          <aside className="hidden lg:block w-60 flex-shrink-0">
            <div className="sticky top-28 space-y-1 bg-[#0F0E0C]/80 border border-primary/20 rounded-2xl p-4 backdrop-blur-xl">
              <p className="text-[10px] text-primary/80 uppercase tracking-widest font-mono font-bold mb-3 px-3">
                Collections
              </p>

              {/* All Products */}
              <button
                onClick={() => setActiveFilter(null)}
                className={`w-full flex items-center gap-2.5 px-3.5 py-2.5 rounded-xl text-xs font-mono font-bold uppercase tracking-wider transition-all mb-1 ${
                  !activeFilter
                    ? 'bg-primary text-black shadow-md'
                    : 'text-text-secondary hover:text-primary hover:bg-[#16130D]'
                }`}
              >
                <span className="material-symbols-outlined text-base">storefront</span>
                All Artifacts
                <span className="ml-auto font-normal text-[10px]">{dbProducts.length}</span>
              </button>

              {/* Category list */}
              {categories.map((cat) => {
                const count = dbProducts.filter((p) => p.categoryId === cat.id).length;
                const isActive = activeFilter === cat.id;
                const isHovered = hoveredCat === cat.id;

                return (
                  <div
                    key={cat.id}
                    className="relative mb-0.5"
                    onMouseEnter={() => setHoveredCat(cat.id)}
                    onMouseLeave={() => setHoveredCat(null)}
                  >
                    <button
                      onClick={() => setActiveFilter(cat.id)}
                      className={`w-full flex items-center gap-2.5 px-3.5 py-2.5 rounded-xl text-xs font-mono font-bold transition-all ${
                        isActive
                          ? 'bg-primary text-black shadow-md'
                          : 'text-text-secondary hover:text-primary hover:bg-[#16130D]'
                      }`}
                    >
                      <span
                        className="material-symbols-outlined text-base flex-shrink-0"
                        style={{ color: isActive ? '#000000' : '#E6C364' }}
                      >
                        {cat.icon}
                      </span>
                      <span className="truncate">{cat.name}</span>
                      {count > 0 && (
                        <span className="ml-auto font-normal text-[10px] opacity-80">{count}</span>
                      )}
                    </button>

                    {/* Desktop flyout */}
                    {isHovered && cat.subcategories.length > 0 && (
                      <div
                        className="absolute left-full top-0 z-50 w-56 bg-[#0E0D0B] border border-primary/30 rounded-xl shadow-2xl p-3 backdrop-blur-xl"
                        style={{ marginLeft: '6px' }}
                      >
                        <p className="text-[9px] uppercase tracking-widest text-primary font-mono font-bold mb-2 px-1">
                          {cat.name}
                        </p>
                        <div className="space-y-0.5">
                          {cat.subcategories.map((sub) => (
                            <Link
                              key={sub.name}
                              href={sub.href}
                              className="flex items-center gap-2 px-2.5 py-1.5 text-xs text-text-secondary hover:text-primary hover:bg-[#16130D] rounded-lg transition-colors"
                            >
                              <span className="material-symbols-outlined text-xs opacity-40">chevron_right</span>
                              {sub.name}
                            </Link>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </aside>

          {/* ── Product Grid ── */}
          <main className="flex-grow min-w-0">
            {loading ? (
              <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-4">
                {[1, 2, 3, 4].map((i) => (
                  <div key={i} className="h-80 rounded-2xl bg-[#12100C] border border-border-subtle animate-pulse" />
                ))}
              </div>
            ) : filteredProducts.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-20 p-8 text-center rounded-2xl glass-card">
                <span className="material-symbols-outlined text-5xl text-primary/40 mb-3">inventory_2</span>
                <p className="font-serif-luxury text-lg font-bold text-text-primary">No products found in this category.</p>
                <button
                  onClick={() => setActiveFilter(null)}
                  className="mt-4 px-6 py-2 rounded bg-primary/10 border border-primary/30 text-primary text-xs font-mono uppercase font-bold hover:bg-primary hover:text-black transition-all"
                >
                  View All Boutique Products
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-3 gap-5">
                {filteredProducts.map((product) => (
                  <ProductCard 
                    key={product.id} 
                    product={product} 
                    t={t} 
                    onQuickAdd={handleQuickAdd}
                  />
                ))}
              </div>
            )}
          </main>
        </div>
      </div>

      {/* Mobile Sidebar Drawer */}
      {isSidebarOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div className="absolute inset-0 bg-black/75 backdrop-blur-sm" onClick={() => setIsSidebarOpen(false)} />
          <div className="absolute left-0 top-0 h-full w-[280px] bg-[#0A0907] border-r border-primary/20 overflow-y-auto">
            <div className="flex items-center justify-between p-5 border-b border-border-subtle sticky top-0 bg-[#0A0907] z-10">
              <span className="font-cinzel text-sm font-bold text-primary uppercase tracking-wider">Collections</span>
              <button onClick={() => setIsSidebarOpen(false)} className="text-text-secondary hover:text-text-primary">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            <div className="p-4 space-y-1">
              <button
                onClick={() => { setActiveFilter(null); setIsSidebarOpen(false); }}
                className={`w-full flex items-center gap-2.5 px-3.5 py-2.5 rounded-lg text-xs font-mono font-bold uppercase tracking-wider transition-colors ${
                  !activeFilter
                    ? 'bg-primary text-black'
                    : 'text-text-secondary hover:text-primary hover:bg-[#14120E]'
                }`}
              >
                <span className="material-symbols-outlined text-base">storefront</span>
                All Products
                <span className="ml-auto text-[10px] font-normal">{dbProducts.length}</span>
              </button>

              {categories.map((cat) => {
                const count = dbProducts.filter((p) => p.categoryId === cat.id).length;
                const isActive = activeFilter === cat.id;

                return (
                  <button
                    key={cat.id}
                    onClick={() => { setActiveFilter(cat.id); setIsSidebarOpen(false); }}
                    className={`w-full flex items-center gap-2.5 px-3.5 py-2.5 rounded-lg text-xs font-mono font-bold transition-colors ${
                      isActive
                        ? 'bg-primary text-black'
                        : 'text-text-secondary hover:text-primary hover:bg-[#14120E]'
                    }`}
                  >
                    <span
                      className="material-symbols-outlined text-base flex-shrink-0"
                      style={{ color: isActive ? '#000000' : '#E6C364' }}
                    >
                      {cat.icon}
                    </span>
                    <span className="truncate">{cat.name}</span>
                    {count > 0 && (
                      <span className="ml-auto text-[10px] font-normal opacity-80">{count}</span>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
