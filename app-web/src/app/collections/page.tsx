"use client";
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useLanguageStore } from '@/store/useLanguageStore';
import { translations } from '@/translations';
import { products, Product } from '@/data/products';
import { collection, getDocs, query, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';

export default function CollectionsPage() {
  const { language } = useLanguageStore();
  const t = translations[language];

  const [dbProducts, setDbProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadProducts() {
      try {
        const q = query(collection(db, 'products'), where('isActive', '==', true));
        const querySnapshot = await getDocs(q);
        const list: Product[] = [];
        querySnapshot.forEach((doc) => {
          list.push({ id: doc.id, ...doc.data() } as Product);
        });
        setDbProducts(list.length > 0 ? list : products);
      } catch (e) {
        console.error('Error fetching Firestore products, fallback:', e);
        setDbProducts(products);
      } finally {
        setLoading(false);
      }
    }
    loadProducts();
  }, []);

  const perfumes = dbProducts.filter((p) => p.type === 'perfume');

  return (
    <div className="pt-32 pb-24 max-w-container-max mx-auto px-gutter">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end mb-12 gap-8">
        <div className="max-w-2xl">
          <h1 className="text-headline-lg font-headline-lg text-text-primary mb-4">{t.collections.title}</h1>
          <p className="text-body-lg font-body-lg text-text-secondary">{t.collections.subtitle}</p>
        </div>
        <div className="flex items-center gap-4 bg-surface-card border border-border-subtle p-2 rounded-DEFAULT w-full md:w-auto">
          <button className="flex items-center gap-2 px-4 py-2 text-label-accent font-label-accent text-text-primary hover:bg-bg-primary rounded-sm transition-colors">
            <span className="material-symbols-outlined text-sm">filter_list</span>
            {t.shop.filters}
          </button>
        </div>
      </div>

      <div className="flex flex-col lg:flex-row gap-12">
        {/* Sidebar Filters (Desktop) */}
        <aside className="hidden lg:block w-64 flex-shrink-0 space-y-10">
          <div>
            <h3 className="text-label-accent font-label-accent text-text-primary uppercase tracking-widest mb-6">{t.collections.category}</h3>
            <div className="space-y-4">
              {['All Perfumes', 'Oud Based', 'Musk Collection', 'Floral Blends', 'Spicy & Woody'].map((cat) => (
                <label key={cat} className="flex items-center gap-3 cursor-pointer group">
                  <input type="checkbox" className="w-4 h-4 rounded-sm border-border-subtle bg-transparent checked:bg-primary-container checked:border-primary-container focus:ring-0 transition-all" />
                  <span className="text-body-md font-body-md text-text-secondary group-hover:text-text-primary transition-colors">{cat}</span>
                </label>
              ))}
            </div>
          </div>
        </aside>

        {/* Product Grid */}
        <div className="flex-grow grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-card-gap">
          {perfumes.map((product) => (
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
                <button className="absolute top-4 right-4 z-10 text-text-secondary hover:text-primary-container transition-colors">
                  <span className="material-symbols-outlined">favorite</span>
                </button>
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
      </div>
    </div>
  );
}
