"use client";
import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useLanguageStore } from '@/store/useLanguageStore';
import { useCartStore } from '@/store/useCartStore';
import { translations } from '@/translations';
import { products, Product } from '@/data/products';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';

export default function ProductPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;
  const { language } = useLanguageStore();
  const { addItem } = useCartStore();
  const t = translations[language];

  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  const [quantity, setQuantity] = useState(1);
  const [giftWrap, setGiftWrap] = useState(false);
  const [activeThumb, setActiveThumb] = useState(0);
  const [activeTab, setActiveTab] = useState<'description' | 'specs' | 'reviews'>('description');
  const [addedNotification, setAddedNotification] = useState(false);

  useEffect(() => {
    async function loadProduct() {
      try {
        const docRef = doc(db, 'products', id);
        const docSnap = await getDoc(docRef);
        if (docSnap.exists() && docSnap.data().isActive) {
          setProduct({ id: docSnap.id, ...docSnap.data() } as Product);
        } else {
          const staticProd = products.find(p => p.id === id);
          setProduct(staticProd || products[0]);
        }
      } catch (e) {
        console.error('Error fetching Firestore product:', e);
        const staticProd = products.find(p => p.id === id);
        setProduct(staticProd || products[0]);
      } finally {
        setLoading(false);
      }
    }
    loadProduct();
  }, [id]);

  if (!product) {
    return (
      <div className="min-h-screen bg-[#070707] flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary-container"></div>
      </div>
    );
  }

  const discount = product.originalPrice
    ? Math.round(((product.originalPrice - product.price) / product.originalPrice) * 100)
    : 0;
  const savings = product.originalPrice ? product.originalPrice - product.price : 0;
  const thumbs = [product.image, product.image, product.image];

  return (
    <div className="min-h-screen bg-[#070707] pt-[88px] pb-16">
      <div className="max-w-[1400px] mx-auto px-4 sm:px-6 lg:px-8">

        {/* Breadcrumb */}
        <nav className="py-3 flex items-center gap-1 text-xs text-text-secondary flex-wrap">
          <Link href="/" className="hover:text-primary-container transition-colors">{t.nav.home}</Link>
          <span className="material-symbols-outlined text-[14px]">chevron_right</span>
          <Link href="/shop" className="hover:text-primary-container transition-colors">{t.nav.shop}</Link>
          <span className="material-symbols-outlined text-[14px]">chevron_right</span>
          <Link href="/collections" className="hover:text-primary-container transition-colors">{product.category}</Link>
          <span className="material-symbols-outlined text-[14px]">chevron_right</span>
          <span className="text-primary-container truncate max-w-[200px]">{product.name}</span>
        </nav>

        {/* Main 3-column grid */}
        <div className="grid grid-cols-1 lg:grid-cols-[420px_1fr_300px] gap-8 mt-2">

          {/* LEFT: Image Gallery */}
          <div className="space-y-3">
            <div className="aspect-square bg-surface-card rounded-lg border border-border-subtle overflow-hidden">
              <img
                src={product.image}
                alt={product.name}
                className={`w-full h-full object-cover transition-transform duration-500 hover:scale-105 ${
                  product.isSoldOut ? 'grayscale opacity-50' : ''
                }`}
              />
            </div>
            <div className="flex gap-2">
              {thumbs.map((src, i) => (
                <button
                  key={i}
                  onClick={() => setActiveThumb(i)}
                  className={`w-16 h-16 rounded border-2 overflow-hidden flex-shrink-0 transition-colors ${
                    activeThumb === i
                      ? 'border-primary-container'
                      : 'border-border-subtle hover:border-primary-container/50'
                  }`}
                >
                  <img src={src} alt="" className="w-full h-full object-cover" />
                </button>
              ))}
              <button className="w-16 h-16 rounded border border-border-subtle hover:border-primary-container/50 flex items-center justify-center flex-shrink-0 bg-surface-card transition-colors">
                <span className="text-text-secondary text-[10px] font-medium text-center leading-tight">360°<br />View</span>
              </button>
            </div>
          </div>

          {/* CENTER: Product Details */}
          <div className="space-y-5">
            <Link href="/about" className="text-sm text-primary-container hover:underline">
              Visit the Sunnah Grandeur Store
            </Link>

            <h1 className="text-2xl md:text-3xl font-serif font-bold text-text-primary leading-snug">
              {product.name}
            </h1>

            {/* Rating + badges */}
            <div className="flex items-center gap-3 flex-wrap">
              <div className="flex items-center gap-0.5">
                {[1, 2, 3, 4].map(s => (
                  <span
                    key={s}
                    className="material-symbols-outlined text-primary-container text-xl leading-none"
                    style={{ fontVariationSettings: "'FILL' 1" }}
                  >star</span>
                ))}
                <span
                  className="material-symbols-outlined text-primary-container text-xl leading-none"
                  style={{ fontVariationSettings: "'FILL' 0" }}
                >star_half</span>
              </div>
              <span className="text-primary-container text-sm cursor-pointer hover:underline">4.3</span>
              <span className="text-text-secondary text-sm">(167,855)</span>
              {!product.isSoldOut && (
                <span className="bg-[#1b4332] text-[#52b788] text-xs font-bold px-2 py-0.5 rounded">
                  Customers&apos; Choice
                </span>
              )}
            </div>

            {!product.isSoldOut && (
              <p className="text-sm text-text-secondary">
                <span className="font-semibold text-text-primary">2K+</span> bought in the past month
              </p>
            )}

            <hr className="border-border-subtle" />

            {/* Price */}
            <div className="space-y-1">
              {!product.isSoldOut && product.tag && (
                <span className="inline-block bg-red-700 text-white text-xs font-bold px-2.5 py-0.5 rounded">
                  Limited time deal
                </span>
              )}
              <div className="flex items-baseline gap-3 flex-wrap">
                {discount > 0 && !product.isSoldOut && (
                  <span className="text-red-400 text-xl font-bold">-{discount}%</span>
                )}
                <span className="text-3xl font-bold text-text-primary">
                  ৳{product.price.toLocaleString()}
                </span>
              </div>
              {product.originalPrice && !product.isSoldOut && (
                <p className="text-sm text-text-secondary">
                  List Price:{' '}
                  <span className="line-through">৳{product.originalPrice.toLocaleString()}</span>
                  <span className="text-green-400 ml-2">
                    You save ৳{savings.toLocaleString()} ({discount}%)
                  </span>
                </p>
              )}
            </div>

            <hr className="border-border-subtle" />

            <p className="text-base text-on-surface-variant leading-relaxed">{product.description}</p>

            {/* Delivery & Support */}
            <div>
              <h3 className="text-sm font-semibold text-text-primary uppercase tracking-widest mb-1">
                Delivery &amp; Support
              </h3>
              <p className="text-xs text-text-secondary mb-3">Select to learn more</p>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {[
                  { icon: 'local_shipping', title: 'Free Delivery', sub: 'Available' },
                  { icon: 'inventory_2', title: 'Ships from', sub: 'Sunnah Grandeur' },
                  { icon: 'assignment_return', title: '30-day Easy', sub: 'Returns' },
                  { icon: 'support_agent', title: 'Customer', sub: 'Support' },
                ].map(item => (
                  <div
                    key={item.icon}
                    className="flex flex-col items-center text-center gap-1.5 p-3 rounded border border-border-subtle hover:border-primary-container/50 cursor-pointer transition-colors bg-surface-card"
                  >
                    <span className="material-symbols-outlined text-primary-container text-2xl">{item.icon}</span>
                    <span className="text-xs text-text-primary font-medium leading-tight">{item.title}</span>
                    <span className="text-xs text-text-secondary leading-tight">{item.sub}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Product meta */}
            <div className="space-y-1 text-sm border-t border-border-subtle pt-4">
              <p className="text-text-secondary">
                <span className="text-text-primary">Category: </span>{product.category}
              </p>
              <p className="text-text-secondary">
                <span className="text-text-primary">Volume: </span>50 ML
              </p>
              <p className="text-text-secondary">
                <span className="text-text-primary">Type: </span>Alcohol-Free · Halal Certified
              </p>
            </div>
          </div>

          {/* RIGHT: Buy Box */}
          <div className="lg:sticky lg:top-24 self-start space-y-4">
            <div className="bg-surface-card rounded-lg border border-border-subtle p-5 space-y-4">

              <div>
                <p className="text-xs text-text-secondary mb-0.5">Buy New</p>
                <p className="text-2xl font-bold text-text-primary">৳{product.price.toLocaleString()}</p>
              </div>

              {!product.isSoldOut && (
                <div className="flex items-start gap-2 text-sm">
                  <span className="material-symbols-outlined text-green-400 text-base mt-0.5 flex-shrink-0">
                    local_shipping
                  </span>
                  <div>
                    <p>
                      <span className="text-green-400 font-semibold">FREE</span>
                      <span className="text-text-secondary"> scheduled delivery</span>
                    </p>
                    <p className="text-text-secondary text-xs mt-0.5">
                      Delivering to Dhaka —{' '}
                      <span className="text-primary-container cursor-pointer hover:underline">Update location</span>
                    </p>
                  </div>
                </div>
              )}

              {product.isSoldOut ? (
                <p className="text-red-400 font-semibold text-sm">Currently Unavailable</p>
              ) : (
                <p className="text-green-400 font-semibold text-sm">In Stock</p>
              )}

              {!product.isSoldOut && (
                <div className="flex items-center gap-3">
                  <label className="text-xs text-text-secondary">Quantity:</label>
                  <select
                    value={quantity}
                    onChange={e => setQuantity(Number(e.target.value))}
                    className="bg-[#1a1a1a] border border-border-subtle text-text-primary rounded px-3 py-1.5 text-sm focus:border-primary-container focus:outline-none cursor-pointer"
                  >
                    {[1, 2, 3, 4, 5].map(n => <option key={n} value={n}>{n}</option>)}
                  </select>
                </div>
              )}

              {product.isSoldOut ? (
                <button
                  disabled
                  className="w-full bg-[#1f1f1f] text-text-secondary py-3 rounded text-sm font-semibold uppercase tracking-wider cursor-not-allowed"
                >
                  {t.cart.outOfStock}
                </button>
              ) : (
                <div className="space-y-2">
                  <button
                    onClick={() => {
                      addItem({
                        id: product.id,
                        name: product.name,
                        price: product.price,
                        image: product.image,
                        category: product.category,
                        quantity,
                        giftWrap,
                      });
                      setAddedNotification(true);
                      setTimeout(() => setAddedNotification(false), 3000);
                    }}
                    className="w-full bg-primary-container text-bg-primary py-3 rounded text-sm font-semibold hover:bg-[#e6c364] transition-colors hover:shadow-[0_0_15px_rgba(201,168,76,0.4)] flex items-center justify-center gap-2"
                  >
                    <span className="material-symbols-outlined text-base">shopping_bag</span>
                    {t.cart.addToCart}
                  </button>
                  <button
                    onClick={() => {
                      addItem({
                        id: product.id,
                        name: product.name,
                        price: product.price,
                        image: product.image,
                        category: product.category,
                        quantity,
                        giftWrap,
                      });
                      router.push('/cart');
                    }}
                    className="w-full bg-[#f0a500] text-[#0d0900] py-3 rounded text-sm font-semibold hover:bg-[#e09400] transition-colors"
                  >
                    Buy Now
                  </button>

                  {addedNotification && (
                    <div className="bg-emerald-950/80 border border-emerald-500/40 text-emerald-300 text-xs p-2.5 rounded text-center animate-in fade-in flex items-center justify-center gap-1.5">
                      <span className="material-symbols-outlined text-sm">check_circle</span>
                      Added {quantity} item(s) to your cart!
                    </div>
                  )}
                </div>
              )}

              <hr className="border-border-subtle" />

              <div className="space-y-2 text-xs">
                {[
                  { label: 'Shipper / Seller', value: 'Sunnah Grandeur', link: true },
                  { label: 'Returns', value: '30-day refund / replacement', link: false },
                  { label: 'Payment', value: 'Secure transaction', link: false },
                ].map(row => (
                  <div key={row.label} className="flex gap-3">
                    <span className="text-text-secondary w-[88px] flex-shrink-0">{row.label}</span>
                    <span className={row.link ? 'text-primary-container hover:underline cursor-pointer' : 'text-text-primary'}>
                      {row.value}
                    </span>
                  </div>
                ))}
              </div>

              {!product.isSoldOut && (
                <>
                  <hr className="border-border-subtle" />
                  <label className="flex items-start gap-2 cursor-pointer group">
                    <input
                      type="checkbox"
                      checked={giftWrap}
                      onChange={e => setGiftWrap(e.target.checked)}
                      className="mt-0.5 accent-amber-500 cursor-pointer"
                    />
                    <span className="text-xs text-text-secondary group-hover:text-text-primary transition-colors">
                      Add premium gift wrapping for{' '}
                      <span className="text-primary-container">৳50</span>
                    </span>
                  </label>
                </>
              )}
            </div>

            {/* Trust badges */}
            <div className="grid grid-cols-3 gap-2 text-center">
              {[
                { icon: 'verified', label: '100%\nHalal' },
                { icon: 'water_drop', label: '0%\nAlcohol' },
                { icon: 'workspace_premium', label: 'Premium\nQuality' },
              ].map(b => (
                <div key={b.icon} className="flex flex-col items-center gap-1 p-2">
                  <span
                    className="material-symbols-outlined text-primary-container text-xl"
                    style={{ fontVariationSettings: "'FILL' 1" }}
                  >{b.icon}</span>
                  <span className="text-[10px] text-text-secondary whitespace-pre-line leading-snug">{b.label}</span>
                </div>
              ))}
            </div>
          </div>

        </div>

        {/* Tabbed Product Overview & Reviews Section */}
        <div className="mt-16 bg-surface-card rounded-xl border border-border-subtle p-6 sm:p-8">
          <div className="flex border-b border-border-subtle gap-8">
            {[
              { id: 'description', label: 'Description' },
              { id: 'specs', label: 'Specifications' },
              { id: 'reviews', label: 'Reviews (167)' },
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`pb-4 text-sm font-semibold uppercase tracking-wider relative transition-colors ${
                  activeTab === tab.id ? 'text-primary-container' : 'text-text-secondary hover:text-text-primary'
                }`}
              >
                {tab.label}
                {activeTab === tab.id && (
                  <span className="absolute bottom-0 left-0 w-full h-[2px] bg-primary-container"></span>
                )}
              </button>
            ))}
          </div>

          <div className="py-6 text-sm text-text-secondary leading-relaxed">
            {activeTab === 'description' && (
              <div className="space-y-4">
                <p>{product.description}</p>
                <p>
                  Handcrafted with the finest ingredients and designed to elevate your daily spiritual routines. Each item in the Sunnah Grandeur collection represents purity, authenticity, and unmatched elegance.
                </p>
              </div>
            )}

            {activeTab === 'specs' && (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 max-w-2xl">
                <div className="p-3 bg-surface rounded border border-border-subtle flex justify-between">
                  <span className="text-text-secondary">Category</span>
                  <span className="font-semibold text-text-primary">{product.category}</span>
                </div>
                <div className="p-3 bg-surface rounded border border-border-subtle flex justify-between">
                  <span className="text-text-secondary">Origin</span>
                  <span className="font-semibold text-text-primary">Artisanal Workshop</span>
                </div>
                <div className="p-3 bg-surface rounded border border-border-subtle flex justify-between">
                  <span className="text-text-secondary">Certification</span>
                  <span className="font-semibold text-primary-container">Halal Certified</span>
                </div>
                <div className="p-3 bg-surface rounded border border-border-subtle flex justify-between">
                  <span className="text-text-secondary">Alcohol Content</span>
                  <span className="font-semibold text-text-primary">0% (Pure Oil / Natural)</span>
                </div>
              </div>
            )}

            {activeTab === 'reviews' && (
              <div className="space-y-6">
                {[
                  { name: 'Tariq A.', rating: 5, date: '2 days ago', text: 'SubhanAllah, the fragrance quality is outstanding. Lasted all day through prayer times.' },
                  { name: 'Khadija R.', rating: 5, date: '1 week ago', text: 'Beautiful craftsmanship and fast delivery in Dhaka. Extremely satisfied!' }
                ].map((rev, idx) => (
                  <div key={idx} className="border-b border-border-subtle pb-4 space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="font-semibold text-text-primary">{rev.name}</span>
                      <span className="text-xs text-text-secondary">{rev.date}</span>
                    </div>
                    <div className="flex text-primary-container text-xs">
                      {Array.from({ length: rev.rating }).map((_, i) => (
                        <span key={i} className="material-symbols-outlined text-sm" style={{ fontVariationSettings: "'FILL' 1" }}>star</span>
                      ))}
                    </div>
                    <p className="text-xs text-text-secondary">{rev.text}</p>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}

