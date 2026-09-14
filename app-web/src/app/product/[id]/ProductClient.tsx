"use client";
import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useLanguageStore } from '@/store/useLanguageStore';
import { useCartStore } from '@/store/useCartStore';
import { useAuth } from '@/context/AuthContext';
import { translations } from '@/translations';
import { products, Product } from '@/data/products';
import { doc, getDoc, collection, query, where, orderBy, onSnapshot, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { formatUsd } from '@/lib/currency';

interface Review {
  id: string;
  rating: number;
  comment: string;
  authorName: string;
  createdAt?: { toDate: () => Date };
}

export default function ProductClient() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;
  const { language } = useLanguageStore();
  const { addItem } = useCartStore();
  const { user } = useAuth();
  const t = translations[language];

  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  const [quantity, setQuantity] = useState(1);
  const [giftWrap, setGiftWrap] = useState(false);
  const [activeThumb, setActiveThumb] = useState(0);
  const [activeTab, setActiveTab] = useState<'description' | 'specs' | 'reviews'>('description');
  const [addedNotification, setAddedNotification] = useState(false);
  const [reviews, setReviews] = useState<Review[]>([]);
  const [showReviewForm, setShowReviewForm] = useState(false);
  const [reviewRating, setReviewRating] = useState(5);
  const [reviewComment, setReviewComment] = useState('');
  const [submittingReview, setSubmittingReview] = useState(false);

  useEffect(() => {
    async function loadProduct() {
      try {
        const docRef = doc(db, 'products', id);
        const docSnap = await getDoc(docRef);
        if (docSnap.exists() && docSnap.data().isActive) {
          setProduct({ id: docSnap.id, ...docSnap.data() } as Product);
        } else {
          // Not in Firestore (or inactive) — fall back to the static catalog
          // for this exact id only. Never substitute a different product.
          setProduct(products.find(p => p.id === id) ?? null);
        }
      } catch (e) {
        console.error('Error fetching Firestore product:', e);
        setProduct(products.find(p => p.id === id) ?? null);
      } finally {
        setLoading(false);
      }
    }
    loadProduct();
  }, [id]);

  useEffect(() => {
    const q = query(collection(db, 'reviews'), where('productId', '==', id), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setReviews(snapshot.docs.map((d) => ({ id: d.id, ...d.data() } as Review)));
    }, (error) => console.error('Error loading reviews:', error));
    return () => unsubscribe();
  }, [id]);

  const handleSubmitReview = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !reviewComment.trim()) return;
    setSubmittingReview(true);
    try {
      await addDoc(collection(db, 'reviews'), {
        productId: id,
        rating: reviewRating,
        comment: reviewComment.trim(),
        authorName: user.displayName || 'Verified Buyer',
        userId: user.uid,
        createdAt: serverTimestamp(),
      });
      setReviewComment('');
      setReviewRating(5);
      setShowReviewForm(false);
    } catch (err) {
      console.error('Error submitting review:', err);
    } finally {
      setSubmittingReview(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-bg-primary flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary-container"></div>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="min-h-screen bg-bg-primary flex flex-col items-center justify-center gap-4 text-center px-4">
        <p className="text-text-primary text-lg font-semibold">Product not found</p>
        <p className="text-text-secondary text-sm">This product may have been removed or is no longer available.</p>
        <Link href="/shop" className="text-primary-container font-bold hover:underline text-xs uppercase tracking-widest">
          ➔ Browse Products
        </Link>
      </div>
    );
  }

  const discount = product.originalPrice
    ? Math.round(((product.originalPrice - product.price) / product.originalPrice) * 100)
    : 0;
  const savings = product.originalPrice ? product.originalPrice - product.price : 0;
  const thumbs = [product.image, product.image, product.image];

  return (
    <div className="min-h-screen bg-bg-primary pt-[88px] pb-16">
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
              {product.image ? (
                <img
                  src={product.image}
                  alt={product.name}
                  className={`w-full h-full object-cover transition-transform duration-500 hover:scale-105 ${
                    product.isSoldOut ? 'grayscale opacity-50' : ''
                  }`}
                />
              ) : (
                <div
                  className="w-full h-full flex flex-col items-center justify-center gap-2"
                  style={{ background: product.bgGradient ?? 'linear-gradient(145deg,#16120b,#281c09)' }}
                >
                  <span className="material-symbols-outlined text-primary-container text-6xl opacity-70">{product.bgIcon || 'spa'}</span>
                  <span className="text-xs font-mono uppercase tracking-widest text-text-secondary">Photo coming soon</span>
                </div>
              )}
            </div>
            {product.image && (
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
              </div>
            )}
          </div>

          {/* CENTER: Product Details */}
          <div className="space-y-5">
            <Link href="/about" className="text-sm text-primary-container hover:underline">
              Visit the Sunnah Grandeur Store
            </Link>

            <h1 className="text-2xl md:text-3xl font-serif font-bold text-text-primary leading-snug">
              {product.name}
            </h1>

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
                  {formatUsd(product.price)}
                </span>
              </div>
              {product.originalPrice && !product.isSoldOut && (
                <p className="text-sm text-text-secondary">
                  List Price:{' '}
                  <span className="line-through">{formatUsd(product.originalPrice)}</span>
                  <span className="text-green-400 ml-2">
                    You save {formatUsd(savings)} ({discount}%)
                  </span>
                </p>
              )}
            </div>

            <hr className="border-border-subtle" />

            <p className="text-base text-text-secondary leading-relaxed">{product.description}</p>

            {/* Delivery & Support */}
            <div>
              <h3 className="text-sm font-semibold text-text-primary uppercase tracking-widest mb-1">
                {t.pdp.deliverySupport}
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
                <span className="text-text-primary">Type: </span>Alcohol-Free · Halal Certified
              </p>
            </div>
          </div>

          {/* RIGHT: Buy Box */}
          <div className="lg:sticky lg:top-24 self-start space-y-4">
            <div className="bg-surface-card rounded-lg border border-border-subtle p-5 space-y-4">

              <div>
                <p className="text-xs text-text-secondary mb-0.5">{t.pdp.buyNew}</p>
                <p className="text-2xl font-bold text-text-primary">{formatUsd(product.price)}</p>
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
                      Delivering across the USA —{' '}
                      <span className="text-primary-container cursor-pointer hover:underline">Update location</span>
                    </p>
                  </div>
                </div>
              )}

              {product.isSoldOut ? (
                <p className="text-red-400 font-semibold text-sm">{t.pdp.unavailable}</p>
              ) : (
                <p className="text-green-400 font-semibold text-sm">{t.pdp.inStock}</p>
              )}

              {!product.isSoldOut && (
                <div className="flex items-center gap-3">
                  <label className="text-xs text-text-secondary">{t.pdp.quantity}:</label>
                  <select
                    value={quantity}
                    onChange={e => setQuantity(Number(e.target.value))}
                    className="bg-surface-card border border-primary/30 text-text-primary text-sm font-mono font-bold outline-none min-w-[72px] px-3.5 py-2 rounded-lg cursor-pointer hover:border-primary/60 transition-colors"
                  >
                    {[1, 2, 3, 4, 5].map(n => <option key={n} value={n}>{n}</option>)}
                  </select>
                </div>
              )}

              {product.isSoldOut ? (
                <button
                  disabled
                  className="w-full bg-border-subtle text-text-secondary py-3 rounded text-sm font-semibold uppercase tracking-wider cursor-not-allowed"
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
                    {t.pdp.buyNow}
                  </button>

                  {addedNotification && (
                    <div className="bg-emerald-950/80 border border-emerald-500/40 text-emerald-300 text-xs p-2.5 rounded text-center animate-in fade-in flex items-center justify-center gap-1.5">
                      <span className="material-symbols-outlined text-sm">check_circle</span>
                      Added {quantity} {quantity === 1 ? 'item' : 'items'} to your cart!
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
              { id: 'description', label: t.pdp.description },
              { id: 'specs', label: t.pdp.specifications },
              { id: 'reviews', label: t.pdp.reviews },
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
                <div className="flex items-center justify-between flex-wrap gap-3">
                  <p className="text-text-primary text-sm font-semibold">
                    {reviews.length === 0
                      ? t.pdp.noReviews
                      : `${reviews.length} review${reviews.length === 1 ? '' : 's'}`}
                  </p>
                  {user && !user.isAnonymous ? (
                    <button
                      onClick={() => setShowReviewForm((v) => !v)}
                      className="text-xs font-mono font-bold uppercase tracking-widest text-primary-container border border-primary-container/40 rounded-lg px-4 py-2 hover:bg-primary-container/10 transition-colors"
                    >
                      {showReviewForm ? 'Cancel' : 'Write a Review'}
                    </button>
                  ) : (
                    <p className="text-xs text-text-secondary">
                      <Link href="/account" className="text-primary-container hover:underline">Sign in</Link> to write a review.
                    </p>
                  )}
                </div>

                {showReviewForm && user && (
                  <form onSubmit={handleSubmitReview} className="p-4 rounded-lg border border-border-subtle bg-surface-card space-y-3">
                    <div className="flex items-center gap-1">
                      {[1, 2, 3, 4, 5].map((n) => (
                        <button
                          type="button"
                          key={n}
                          onClick={() => setReviewRating(n)}
                          className="text-2xl leading-none"
                          aria-label={`${n} star${n === 1 ? '' : 's'}`}
                        >
                          <span
                            className="material-symbols-outlined text-2xl"
                            style={{ fontVariationSettings: n <= reviewRating ? "'FILL' 1" : "'FILL' 0", color: '#E6C364' }}
                          >
                            star
                          </span>
                        </button>
                      ))}
                    </div>
                    <textarea
                      value={reviewComment}
                      onChange={(e) => setReviewComment(e.target.value)}
                      required
                      rows={3}
                      placeholder="Share your experience with this product..."
                      className="w-full bg-bg-primary border border-border-subtle rounded px-3 py-2.5 text-sm text-text-primary focus:border-primary-container focus:outline-none resize-none"
                    />
                    <button
                      type="submit"
                      disabled={submittingReview}
                      className="bg-primary-container text-bg-primary text-xs font-bold uppercase tracking-widest px-5 py-2.5 rounded hover:bg-[#e6c364] transition-colors disabled:opacity-50"
                    >
                      {submittingReview ? 'Submitting...' : 'Submit Review'}
                    </button>
                  </form>
                )}

                {reviews.length > 0 && (
                  <div className="space-y-4">
                    {reviews.map((review) => (
                      <div key={review.id} className="p-4 rounded-lg border border-border-subtle">
                        <div className="flex items-center gap-2 mb-1.5">
                          <div className="flex">
                            {[1, 2, 3, 4, 5].map((n) => (
                              <span
                                key={n}
                                className="material-symbols-outlined text-sm"
                                style={{ fontVariationSettings: n <= review.rating ? "'FILL' 1" : "'FILL' 0", color: '#E6C364' }}
                              >
                                star
                              </span>
                            ))}
                          </div>
                          <span className="text-xs font-semibold text-text-primary">{review.authorName}</span>
                        </div>
                        <p className="text-sm text-text-secondary leading-relaxed">{review.comment}</p>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}
