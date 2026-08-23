"use client";
import { useState, useMemo, useEffect } from 'react';
import Link from 'next/link';
import { useLanguageStore } from '@/store/useLanguageStore';
import { translations } from '@/translations';
import { products, Product } from '@/data/products';
import { categories } from '@/data/categories';
import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function ProductCard({ product, t }: { product: Product; t: any }) {
  return (
    <div className="group relative bg-surface-card rounded-DEFAULT border border-border-subtle hover:border-primary-container transition-colors duration-300 overflow-hidden flex flex-col">
      <Link href={`/product/${product.id}`} className="relative aspect-[3/4] overflow-hidden block flex-shrink-0">
        {product.image ? (
          <img
            src={product.image}
            alt={product.name}
            className={`w-full h-full object-cover transition-all duration-500 ${
              product.isSoldOut ? 'opacity-40 grayscale' : 'opacity-80 group-hover:scale-105 group-hover:opacity-100'
            }`}
          />
        ) : (
          <div
            className="w-full h-full flex flex-col items-center justify-center gap-2"
            style={{ background: product.bgGradient ?? 'linear-gradient(145deg,#1a1206,#2d1f08)' }}
          >
            {product.bgIcon && (
              <span
                className="material-symbols-outlined opacity-25 group-hover:opacity-40 transition-opacity"
                style={{ fontSize: '56px', color: '#C9A84C' }}
              >
                {product.bgIcon}
              </span>
            )}
            <span className="text-[9px] text-primary-container/40 uppercase tracking-widest font-bold">
              {product.category}
            </span>
          </div>
        )}

        {product.tag && (
          <span className={`absolute top-2.5 left-2.5 z-10 px-2 py-0.5 text-[9px] font-bold uppercase rounded-full ${
            product.isSoldOut
              ? 'bg-surface-card text-text-secondary border border-border-subtle'
              : 'bg-primary-container text-bg-primary'
          }`}>
            {product.isSoldOut ? t.cart.outOfStock : product.tag}
          </span>
        )}
        {product.originalPrice && !product.isSoldOut && (
          <span className="absolute top-2.5 right-2.5 z-10 bg-red-600 text-white px-1.5 py-0.5 text-[9px] font-bold rounded-full">
            ৳{product.originalPrice - product.price} Off
          </span>
        )}

        <div className="absolute bottom-0 left-0 w-full p-2.5 translate-y-full group-hover:translate-y-0 transition-transform duration-300 bg-gradient-to-t from-bg-primary/95 to-transparent">
          {product.isSoldOut ? (
            <button className="w-full bg-surface-card text-text-secondary py-2 text-[10px] font-bold uppercase rounded-DEFAULT cursor-not-allowed border border-border-subtle">
              {t.cart.outOfStock}
            </button>
          ) : (
            <button className="w-full bg-primary-container text-bg-primary py-2 text-[10px] font-bold uppercase rounded-DEFAULT hover:bg-[#e6c364] transition-colors">
              {t.cart.addToCart} — ৳{product.price}
            </button>
          )}
        </div>
      </Link>

      <div className={`p-3 flex flex-col gap-1 flex-grow ${product.isSoldOut ? 'opacity-60' : ''}`}>
        <span className="text-[9px] text-primary-container/60 uppercase tracking-widest font-bold">{product.category}</span>
        <Link href={`/product/${product.id}`} className="block hover:text-primary-container transition-colors">
          <h4 className="text-text-primary font-bold text-xs leading-snug line-clamp-2">{product.name}</h4>
        </Link>
        <p className="text-text-secondary text-[11px] line-clamp-2 leading-relaxed">{product.description}</p>
        <div className="mt-2 flex items-center gap-2">
          <span className="text-primary-container font-bold text-sm">৳{product.price.toFixed(0)}</span>
          {product.originalPrice && (
            <span className="text-[11px] text-text-secondary line-through">৳{product.originalPrice}</span>
          )}
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
    <div className="min-h-screen bg-bg-primary">

      {/* Page Header */}
      <section className="relative pt-28 pb-8 border-b border-border-subtle">
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-1/2 left-1/4 w-[400px] h-[200px] rounded-full bg-[#C9A84C]/5 blur-[80px]" />
        </div>
        <div className="max-w-container-max mx-auto px-gutter relative z-10">
          <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
            <div>
              <span className="text-primary-container text-label-accent font-label-accent tracking-[0.2em] uppercase text-xs mb-1 block">Islamic Lifestyle</span>
              <h1 className="text-2xl md:text-3xl font-serif font-bold text-text-primary leading-tight">
                {activeCategory ? activeCategory.name : 'All Products'}
              </h1>
              <p className="text-text-secondary text-xs mt-1">
                {filteredProducts.length} product{filteredProducts.length !== 1 ? 's' : ''} found
              </p>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => setIsSidebarOpen(true)}
                className="flex items-center gap-2 lg:hidden bg-surface-card border border-border-subtle px-3 py-2 text-xs font-bold text-text-primary rounded uppercase tracking-wider"
              >
                <span className="material-symbols-outlined text-sm">filter_list</span>
                Categories
              </button>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                className="bg-surface-card border border-border-subtle text-text-primary text-xs font-bold outline-none px-3 py-2 rounded cursor-pointer uppercase tracking-wider"
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

      <div className="max-w-container-max mx-auto px-gutter py-8">
        <div className="flex gap-6">

          {/* ── Desktop Sidebar ── */}
          <aside className="hidden lg:block w-52 flex-shrink-0">
            <div className="sticky top-28">
              <p className="text-[10px] text-text-secondary uppercase tracking-widest font-bold mb-3 px-3">Browse</p>

              {/* All Products */}
              <button
                onClick={() => setActiveFilter(null)}
                className={`w-full flex items-center gap-2 px-3 py-2 rounded text-xs font-bold uppercase tracking-wider transition-colors mb-0.5 ${
                  !activeFilter
                    ? 'bg-primary-container/15 text-primary-container'
                    : 'text-text-secondary hover:text-text-primary hover:bg-surface-card'
                }`}
              >
                <span className="material-symbols-outlined text-sm">storefront</span>
                All Products
                <span className="ml-auto font-normal text-text-secondary">{products.length}</span>
              </button>

              {/* Category list with hover flyout */}
              {categories.map((cat) => {
                const count = products.filter((p) => p.categoryId === cat.id).length;
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
                      className={`w-full flex items-center gap-2 px-3 py-2 rounded text-xs font-bold transition-colors ${
                        isActive
                          ? 'bg-primary-container/15 text-primary-container'
                          : 'text-text-secondary hover:text-text-primary hover:bg-surface-card'
                      }`}
                    >
                      <span
                        className="material-symbols-outlined text-sm flex-shrink-0"
                        style={{ color: isActive ? '#C9A84C' : cat.accentColor + '80' }}
                      >
                        {cat.icon}
                      </span>
                      <span className="truncate">{cat.name}</span>
                      {count > 0 && (
                        <span className="ml-auto font-normal text-text-secondary flex-shrink-0">{count}</span>
                      )}
                    </button>

                    {/* Desktop flyout */}
                    {isHovered && cat.subcategories.length > 0 && (
                      <div
                        className="absolute left-full top-0 z-50 w-52 bg-[#0e0e0e] border border-border-subtle rounded-DEFAULT shadow-2xl p-3"
                        style={{ marginLeft: '2px' }}
                      >
                        <p className="text-[9px] uppercase tracking-widest text-primary-container font-bold mb-2 px-1">
                          {cat.name}
                        </p>
                        <div className="space-y-0.5">
                          {cat.subcategories.map((sub) => (
                            <Link
                              key={sub.name}
                              href={sub.href}
                              className="flex items-center gap-1.5 px-2 py-1.5 text-xs text-text-secondary hover:text-primary-container hover:bg-surface-card rounded transition-colors"
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
            {filteredProducts.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-24 text-center">
                <span className="material-symbols-outlined text-5xl text-border-subtle mb-4">inventory_2</span>
                <p className="text-text-secondary text-sm">No products in this category yet.</p>
                <button
                  onClick={() => setActiveFilter(null)}
                  className="mt-4 text-primary-container text-sm font-bold underline"
                >
                  View all products
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-3">
                {filteredProducts.map((product) => (
                  <ProductCard key={product.id} product={product} t={t} />
                ))}
              </div>
            )}
          </main>
        </div>
      </div>

      {/* Mobile Sidebar Drawer */}
      {isSidebarOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setIsSidebarOpen(false)} />
          <div className="absolute left-0 top-0 h-full w-[280px] bg-bg-primary border-r border-border-subtle overflow-y-auto">
            <div className="flex items-center justify-between p-4 border-b border-border-subtle sticky top-0 bg-bg-primary z-10">
              <span className="text-text-primary font-bold text-sm uppercase tracking-wider">Categories</span>
              <button onClick={() => setIsSidebarOpen(false)} className="text-text-secondary hover:text-text-primary">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            <div className="p-4 space-y-0.5">
              {/* All Products */}
              <button
                onClick={() => { setActiveFilter(null); setIsSidebarOpen(false); }}
                className={`w-full flex items-center gap-2 px-3 py-2.5 rounded text-sm font-bold uppercase tracking-wider transition-colors ${
                  !activeFilter
                    ? 'bg-primary-container/15 text-primary-container'
                    : 'text-text-secondary hover:text-text-primary hover:bg-surface-card'
                }`}
              >
                <span className="material-symbols-outlined text-base">storefront</span>
                All Products
                <span className="ml-auto text-xs font-normal text-text-secondary">{products.length}</span>
              </button>

              {/* Category accordion */}
              {categories.map((cat) => {
                const count = products.filter((p) => p.categoryId === cat.id).length;
                const isActive = activeFilter === cat.id;
                const isOpen = openMobileCat === cat.id;

                return (
                  <div key={cat.id}>
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => { setActiveFilter(cat.id); setIsSidebarOpen(false); }}
                        className={`flex-1 flex items-center gap-2 px-3 py-2.5 rounded-l text-sm font-bold transition-colors ${
                          isActive
                            ? 'bg-primary-container/15 text-primary-container'
                            : 'text-text-secondary hover:text-text-primary hover:bg-surface-card'
                        }`}
                      >
                        <span
                          className="material-symbols-outlined text-base flex-shrink-0"
                          style={{ color: isActive ? '#C9A84C' : cat.accentColor + '80' }}
                        >
                          {cat.icon}
                        </span>
                        <span className="truncate">{cat.name}</span>
                        {count > 0 && (
                          <span className="ml-auto text-xs font-normal text-text-secondary flex-shrink-0">{count}</span>
                        )}
                      </button>
                      <button
                        onClick={() => setOpenMobileCat(isOpen ? null : cat.id)}
                        className="px-2 py-2.5 text-text-secondary hover:text-text-primary transition-colors rounded-r hover:bg-surface-card flex-shrink-0"
                      >
                        <span className={`material-symbols-outlined text-sm transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`}>
                          expand_more
                        </span>
                      </button>
                    </div>

                    {isOpen && cat.subcategories.length > 0 && (
                      <div className="ml-3 pl-3 border-l border-border-subtle mt-0.5 mb-1 space-y-0.5">
                        {cat.subcategories.map((sub) => (
                          <Link
                            key={sub.name}
                            href={sub.href}
                            onClick={() => setIsSidebarOpen(false)}
                            className="flex items-center gap-2 px-3 py-1.5 text-xs text-text-secondary hover:text-primary-container hover:bg-surface-card rounded transition-colors"
                          >
                            <span className="w-1 h-1 rounded-full bg-border-subtle flex-shrink-0" />
                            {sub.name}
                          </Link>
                        ))}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
