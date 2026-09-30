"use client";
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useLanguageStore } from '@/store/useLanguageStore';
import { translations } from '@/translations';
import { products, Product } from '@/data/products';
import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { formatUsd } from '@/lib/currency';
import { useCurrency } from '@/context/CurrencyContext';
import { useCartStore } from '@/store/useCartStore';
import CartDrawer from '@/components/CartDrawer';

export default function CollectionsPage() {
  const { language } = useLanguageStore();
  const t = translations[language];
  const { usdRate } = useCurrency();
  const { addItem } = useCartStore();

  const [dbProducts, setDbProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [isCartOpen, setIsCartOpen] = useState(false);

  useEffect(() => {
    const q = query(collection(db, 'products'), where('isActive', '==', true));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list: Product[] = [];
      snapshot.forEach((doc) => {
        list.push({ id: doc.id, ...doc.data() } as Product);
      });
      setDbProducts(list.length > 0 ? list : products);
      setLoading(false);
    }, (error) => {
      console.error('Error listening to Firestore products, fallback:', error);
      setDbProducts(products);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  const SCENT_FILTERS = ['Oud Based', 'Musk Collection', 'Floral Blends', 'Spicy & Woody'] as const;
  const [activeScents, setActiveScents] = useState<string[]>([]);
  const SCENT_KEYWORDS: Record<string, string[]> = {
    'Oud Based': ['oud', 'agarwood'],
    'Musk Collection': ['musk'],
    'Floral Blends': ['floral', 'rose', 'jasmine'],
    'Spicy & Woody': ['spice', 'spicy', 'wood', 'amber', 'sandalwood'],
  };

  const toggleScent = (cat: string) => {
    setActiveScents((prev) => prev.includes(cat) ? prev.filter((c) => c !== cat) : [...prev, cat]);
  };

  const allPerfumes = dbProducts.filter((p) => p.type === 'perfume');
  const perfumes = activeScents.length === 0
    ? allPerfumes
    : allPerfumes.filter((p) => {
        const haystack = `${p.name} ${p.description}`.toLowerCase();
        return activeScents.some((cat) => SCENT_KEYWORDS[cat].some((kw) => haystack.includes(kw)));
      });

  const handleAddToCart = (e: React.MouseEvent, product: Product) => {
    e.preventDefault();
    e.stopPropagation();
    addItem({
      id: product.id,
      name: product.name,
      price: product.price,
      image: product.image || '/products/PhotoshopExtension_Image_1.png',
      category: product.category,
      quantity: 1,
      size: '50ml Extrait',
    });
    setIsCartOpen(true);
  };

  const FilterList = () => (
    <div className="space-y-4">
      <label className="flex items-center gap-3 cursor-pointer group">
        <input
          type="checkbox"
          checked={activeScents.length === 0}
          onChange={() => setActiveScents([])}
          className="w-4 h-4 rounded-sm border-border-subtle bg-transparent checked:bg-primary-container checked:border-primary-container focus:ring-0 transition-all"
        />
        <span className="text-body-md font-body-md text-text-secondary group-hover:text-text-primary transition-colors">All Perfumes</span>
      </label>
      {SCENT_FILTERS.map((cat) => (
        <label key={cat} className="flex items-center gap-3 cursor-pointer group">
          <input
            type="checkbox"
            checked={activeScents.includes(cat)}
            onChange={() => toggleScent(cat)}
            className="w-4 h-4 rounded-sm border-border-subtle bg-transparent checked:bg-primary-container checked:border-primary-container focus:ring-0 transition-all"
          />
          <span className="text-body-md font-body-md text-text-secondary group-hover:text-text-primary transition-colors">{cat}</span>
        </label>
      ))}
    </div>
  );

  return (
    <div className="pt-32 pb-24 max-w-container-max mx-auto px-gutter">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end mb-12 gap-8">
        <div className="max-w-2xl">
          <h1 className="text-headline-lg font-headline-lg text-text-primary mb-4">{t.collections.title}</h1>
          <p className="text-body-lg font-body-lg text-text-secondary">{t.collections.subtitle}</p>
        </div>
        <div className="flex items-center gap-4 bg-surface-card border border-border-subtle p-2 rounded-DEFAULT w-full md:w-auto lg:hidden">
          <button
            onClick={() => setIsFilterOpen(true)}
            className="flex items-center gap-2 px-4 py-2 text-label-accent font-label-accent text-text-primary hover:bg-bg-primary rounded-sm transition-colors"
          >
            <span className="material-symbols-outlined text-sm">filter_list</span>
            {t.shop.filters}
            {activeScents.length > 0 && (
              <span className="ml-1 bg-primary-container text-bg-primary text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center">{activeScents.length}</span>
            )}
          </button>
        </div>
      </div>

      {/* Mobile Filter Drawer */}
      {isFilterOpen && (
        <div className="fixed inset-0 z-[100] lg:hidden">
          <div className="absolute inset-0 bg-black/70" onClick={() => setIsFilterOpen(false)} />
          <div className="absolute right-0 top-0 bottom-0 w-full max-w-xs bg-surface-card border-l border-border-subtle p-6 overflow-y-auto">
            <div className="flex items-center justify-between mb-8">
              <h3 className="text-label-accent font-label-accent text-text-primary uppercase tracking-widest">{t.collections.category}</h3>
              <button onClick={() => setIsFilterOpen(false)} aria-label="Close filters" className="w-9 h-9 flex items-center justify-center text-text-secondary hover:text-primary-container">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            <FilterList />
            <button
              onClick={() => setIsFilterOpen(false)}
              className="mt-8 w-full bg-primary-container text-bg-primary py-3 text-label-accent font-label-accent uppercase rounded-DEFAULT"
            >
              Show {perfumes.length} Results
            </button>
          </div>
        </div>
      )}

      <div className="flex flex-col lg:flex-row gap-12">
        {/* Sidebar Filters (Desktop) */}
        <aside className="hidden lg:block w-64 flex-shrink-0 space-y-10">
          <div>
            <h3 className="text-label-accent font-label-accent text-text-primary uppercase tracking-widest mb-6">{t.collections.category}</h3>
            <FilterList />
          </div>
        </aside>

        {/* Product Grid */}
        {loading ? (
          <div className="flex-grow grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-card-gap">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="rounded-DEFAULT border border-border-subtle overflow-hidden flex flex-col h-full">
                <div className="aspect-[4/5] bg-surface-card animate-pulse" />
                <div className="p-6 space-y-3">
                  <div className="h-4 w-3/4 bg-surface-card rounded animate-pulse" />
                  <div className="h-3 w-full bg-surface-card rounded animate-pulse" />
                  <div className="h-4 w-1/3 bg-surface-card rounded animate-pulse" />
                </div>
              </div>
            ))}
          </div>
        ) : (
        <div className="flex-grow grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-card-gap">
          {perfumes.map((product) => (
            <div key={product.id} className="group relative bg-surface-card rounded-DEFAULT border border-border-subtle hover:border-primary-container transition-colors duration-300 overflow-hidden flex flex-col h-full">
              <Link href={`/product/${product.id}`} className="relative aspect-[4/5] bg-bg-primary overflow-hidden block">
                {product.tag && (
                  <span className={`absolute top-4 left-4 z-10 px-3 py-1 text-[10px] font-label-accent uppercase rounded-full ${
                    product.isSoldOut ? 'bg-border-subtle text-text-secondary border border-border-subtle' : 'bg-primary-container text-bg-primary'
                  }`}>
                    {product.isSoldOut ? t.cart.outOfStock : product.tag}
                  </span>
                )}
                {product.originalPrice && !product.isSoldOut && (
                  <span className="absolute top-4 right-4 z-10 bg-red-600 text-white px-2 py-1 text-[10px] font-bold rounded-full">
                    {formatUsd(product.originalPrice - product.price, usdRate)} Off
                  </span>
                )}
                <img
                  className={`w-full h-full object-cover transition-all duration-500 ${
                    product.isSoldOut ? 'opacity-40 grayscale' : 'opacity-80 group-hover:scale-105 group-hover:opacity-100'
                  }`}
                  src={product.image || '/logo.png'}
                  alt={product.name}
                />
                <div className="absolute bottom-0 left-0 w-full p-4 translate-y-full group-hover:translate-y-0 transition-transform duration-300 bg-gradient-to-t from-bg-primary to-transparent">
                  {product.isSoldOut ? (
                    <button disabled className="w-full bg-border-subtle text-text-secondary py-3 text-label-accent font-label-accent uppercase rounded-DEFAULT cursor-not-allowed">{t.cart.outOfStock}</button>
                  ) : (
                    <button
                      onClick={(e) => handleAddToCart(e, product)}
                      className="w-full bg-primary-container text-bg-primary py-3 text-label-accent font-label-accent uppercase rounded-DEFAULT hover:bg-primary-fixed transition-colors"
                    >
                      {t.cart.addToCart} — {formatUsd(product.price, usdRate)}
                    </button>
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
                  <span className="text-body-lg font-body-lg text-primary-container">{formatUsd(product.price, usdRate)}</span>
                  {product.originalPrice && (
                    <span className="text-sm text-text-secondary line-through">{formatUsd(product.originalPrice, usdRate)}</span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
        )}
      </div>
      <CartDrawer isOpen={isCartOpen} onClose={() => setIsCartOpen(false)} />
    </div>
  );
}
