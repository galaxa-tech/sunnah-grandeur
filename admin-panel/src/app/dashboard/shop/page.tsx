"use client";

import { useState, useEffect } from "react";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { collection, doc, addDoc, setDoc, updateDoc, deleteDoc, serverTimestamp, onSnapshot, query, orderBy } from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { db, functions } from "@/lib/firebase";
import { storedToUsd, usdToStored, formatUsd, DEFAULT_BDT_TO_USD_RATE } from "@/lib/currency";

interface Product {
  id: string;
  name: string;
  category: string;
  categoryId: string;
  price: number;
  originalPrice?: number;
  image?: string;
  description: string;
  type: "perfume" | "other";
  tag?: string;
  isSoldOut?: boolean;
  isActive: boolean;
  stockQuantity?: number;
}

interface Category {
  id: string;
  name: string;
  description: string;
}

interface Banner {
  id: string;
  title: string;
  subtitle: string;
  imageUrl?: string;
  cta: string;
  isActive: boolean;
  sortOrder?: number;
}

export default function ShopManagementPage() {
  const [activeTab, setActiveTab] = useState<'products' | 'categories' | 'banners' | 'orders' | 'inventory'>('products');
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [banners, setBanners] = useState<Banner[]>([]);
  const [ordersList, setOrdersList] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  // Live from settings/app_config.usdToLocalRate — the same field
  // createOrder/app-mobile read, so this display never silently drifts.
  const [usdRate, setUsdRate] = useState(DEFAULT_BDT_TO_USD_RATE);
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Category form state
  const [isCatModalOpen, setIsCatModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [catName, setCatName] = useState("");
  const [catDescription, setCatDescription] = useState("");

  // Banner form state
  const [isBannerModalOpen, setIsBannerModalOpen] = useState(false);
  const [editingBanner, setEditingBanner] = useState<Banner | null>(null);
  const [bannerTitle, setBannerTitle] = useState("");
  const [bannerSubtitle, setBannerSubtitle] = useState("");
  const [bannerImageUrl, setBannerImageUrl] = useState("");
  const [bannerCta, setBannerCta] = useState("Shop now");
  const [bannerIsActive, setBannerIsActive] = useState(true);

  // Form states
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [name, setName] = useState("");
  const [tag, setTag] = useState("");
  const [description, setDescription] = useState("");
  const [categorySelection, setCategorySelection] = useState("");
  const [price, setPrice] = useState("");
  const [originalPrice, setOriginalPrice] = useState("");
  const [image, setImage] = useState("");
  const [stockQuantity, setStockQuantity] = useState("");

  useEffect(() => {
    setLoading(true);

    // Real-time products listener
    const unsubscribeProducts = onSnapshot(collection(db, "products"), (snapshot) => {
      const list: Product[] = [];
      snapshot.forEach((doc) => {
        list.push({ id: doc.id, ...doc.data() } as Product);
      });
      setProducts(list.sort((a, b) => a.name.localeCompare(b.name)));
      setLoading(false);
    }, (error) => {
      console.error("Error listening to products:", error);
      setLoading(false);
    });

    // Real-time categories listener
    const unsubscribeCategories = onSnapshot(collection(db, "categories"), (snapshot) => {
      const list: Category[] = [];
      snapshot.forEach((doc) => {
        list.push({ id: doc.id, ...(doc.data() as any) });
      });
      setCategories(list.sort((a, b) => a.name.localeCompare(b.name)));
    }, (error) => {
      console.error("Error listening to categories:", error);
    });

    // Real-time orders listener
    const unsubscribeOrders = onSnapshot(collection(db, "orders"), (snapshot) => {
      const list: any[] = [];
      snapshot.forEach((doc) => {
        list.push({ id: doc.id, ...doc.data() });
      });
      // Optionally sort by createdAt if needed, assuming latest first
      setOrdersList(list.sort((a, b) => {
        const timeA = a.createdAt?.seconds || 0;
        const timeB = b.createdAt?.seconds || 0;
        return timeB - timeA;
      }));
    }, (error) => {
      console.error("Error listening to orders:", error);
    });

    // Real-time banners listener
    const unsubscribeBanners = onSnapshot(collection(db, "banners"), (snapshot) => {
      const list: Banner[] = [];
      snapshot.forEach((doc) => {
        list.push({ id: doc.id, ...(doc.data() as any) });
      });
      setBanners(list.sort((a, b) => (a.sortOrder ?? 999) - (b.sortOrder ?? 999)));
    }, (error) => {
      console.error("Error listening to banners:", error);
    });

    // Real-time app config listener (tax rate + USD conversion rate)
    const unsubscribeConfig = onSnapshot(doc(db, "settings", "app_config"), (snap) => {
      const rate = snap.data()?.usdToLocalRate;
      if (typeof rate === "number" && rate > 0) setUsdRate(rate);
    }, (error) => {
      console.error("Error listening to app_config:", error);
    });

    return () => {
      unsubscribeProducts();
      unsubscribeCategories();
      unsubscribeBanners();
      unsubscribeOrders();
      unsubscribeConfig();
    };
  }, []);

  // ── Category CRUD ──────────────────────────────────────────────────────────

  const openAddCatModal = () => {
    setEditingCategory(null);
    setCatName("");
    setCatDescription("");
    setIsCatModalOpen(true);
  };

  const openEditCatModal = (cat: Category) => {
    setEditingCategory(cat);
    setCatName(cat.name);
    setCatDescription(cat.description || "");
    setIsCatModalOpen(true);
  };

  const slugify = (s: string) =>
    s.trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

  const handleCatSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const id = editingCategory ? editingCategory.id : slugify(catName);
    if (!id) return;
    if (!editingCategory && categories.some((c) => c.id === id)) {
      alert(`A category with the ID "${id}" already exists. Choose a different name.`);
      return;
    }
    try {
      if (editingCategory) {
        await updateDoc(doc(db, "categories", id), {
          name: catName.trim(),
          description: catDescription.trim(),
          updatedAt: serverTimestamp(),
        });
      } else {
        await setDoc(doc(db, "categories", id), {
          name: catName.trim(),
          description: catDescription.trim(),
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
      }
      setIsCatModalOpen(false);
    } catch (err) {
      console.error("Error saving category:", err);
      alert("Failed to save category.");
    }
  };

  const handleDeleteCategory = async (cat: Category) => {
    const inUse = products.filter((p) => p.categoryId === cat.id).length;
    if (inUse > 0) {
      alert(`Can't delete "${cat.name}" — ${inUse} product(s) still use it. Move them to another category first.`);
      return;
    }
    if (!window.confirm(`Delete category "${cat.name}"?`)) return;
    try {
      await deleteDoc(doc(db, "categories", cat.id));
    } catch (err) {
      console.error("Error deleting category:", err);
    }
  };

  // ── Banner CRUD ─────────────────────────────────────────────────────────────
  // Matches app-mobile/lib/models/store_category_model.dart's StoreBannerModel
  // (title, subtitle, imageUrl, cta, isActive) exactly — this is the admin
  // side of infrastructure that already existed on the mobile app (a live
  // Firestore listener + security rules) but previously had no UI to manage it.

  const openAddBannerModal = () => {
    setEditingBanner(null);
    setBannerTitle("");
    setBannerSubtitle("");
    setBannerImageUrl("");
    setBannerCta("Shop now");
    setBannerIsActive(true);
    setIsBannerModalOpen(true);
  };

  const openEditBannerModal = (banner: Banner) => {
    setEditingBanner(banner);
    setBannerTitle(banner.title);
    setBannerSubtitle(banner.subtitle);
    setBannerImageUrl(banner.imageUrl || "");
    setBannerCta(banner.cta || "Shop now");
    setBannerIsActive(banner.isActive);
    setIsBannerModalOpen(true);
  };

  const handleBannerSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!bannerTitle.trim()) return;
    try {
      const data = {
        title: bannerTitle.trim(),
        subtitle: bannerSubtitle.trim(),
        imageUrl: bannerImageUrl.trim() || null,
        cta: bannerCta.trim() || "Shop now",
        isActive: bannerIsActive,
        updatedAt: serverTimestamp(),
      };
      if (editingBanner) {
        await updateDoc(doc(db, "banners", editingBanner.id), data);
      } else {
        await addDoc(collection(db, "banners"), {
          ...data,
          sortOrder: banners.length,
          createdAt: serverTimestamp(),
        });
      }
      setIsBannerModalOpen(false);
    } catch (err) {
      console.error("Error saving banner:", err);
      alert("Failed to save banner.");
    }
  };

  const handleDeleteBanner = async (banner: Banner) => {
    if (!window.confirm(`Delete banner "${banner.title}"?`)) return;
    try {
      await deleteDoc(doc(db, "banners", banner.id));
    } catch (err) {
      console.error("Error deleting banner:", err);
    }
  };

  const handleToggleBannerActive = async (banner: Banner) => {
    try {
      await updateDoc(doc(db, "banners", banner.id), { isActive: !banner.isActive });
    } catch (err) {
      console.error("Error toggling banner:", err);
    }
  };

  const handleUpdateOrderStatus = async (orderId: string, newStatus: string) => {
    try {
      // Firestore rules block direct client writes to /orders — this must go
      // through the admin-only updateOrderStatus Cloud Function.
      const updateOrderStatus = httpsCallable(functions, "updateOrderStatus");
      await updateOrderStatus({ orderId, status: newStatus });
      setOrdersList(ordersList.map(o => o.id === orderId ? { ...o, status: newStatus } : o));
    } catch (e) {
      console.error("Error updating order status:", e);
      alert("Failed to update order status. Check console for details.");
    }
  };

  const openAddModal = () => {
    setEditingProduct(null);
    setName("");
    setTag("");
    setDescription("");
    setCategorySelection(categories[0]?.id || "");
    setPrice("");
    setOriginalPrice("");
    setImage("");
    setStockQuantity("");
    setIsModalOpen(true);
  };

  const openEditModal = (product: Product) => {
    setEditingProduct(product);
    setName(product.name);
    setTag(product.tag || "");
    setDescription(product.description);
    setCategorySelection(product.categoryId || categories[0]?.id || "");
    setPrice(storedToUsd(product.price, usdRate).toFixed(2));
    setOriginalPrice(product.originalPrice ? storedToUsd(product.originalPrice, usdRate).toFixed(2) : "");
    setImage(product.image || "");
    setStockQuantity((product.stockQuantity ?? 0).toString());
    setIsModalOpen(true);
  };

  const handleToggleActive = async (productId: string, currentStatus: boolean) => {
    try {
      const productRef = doc(db, "products", productId);
      await updateDoc(productRef, {
        isActive: !currentStatus,
        updatedAt: serverTimestamp()
      });
      setProducts(products.map(p => p.id === productId ? { ...p, isActive: !currentStatus } : p));
    } catch (e) {
      console.error("Error toggling active state:", e);
    }
  };

  const handleDeleteProduct = async (productId: string) => {
    if (!window.confirm("Are you sure you want to delete this product?")) return;
    try {
      await deleteDoc(doc(db, "products", productId));
      setProducts(products.filter(p => p.id !== productId));
    } catch (e) {
      console.error("Error deleting product:", e);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const selectedCat = categories.find((c) => c.id === categorySelection);
    if (!selectedCat) {
      alert("Choose a category first.");
      return;
    }
    const type: "perfume" | "other" = selectedCat.id === "fragrance" ? "perfume" : "other";

    const storedPrice = Math.round(usdToStored(parseFloat(price) || 0, usdRate) * 100) / 100;
    const storedOriginalPrice = originalPrice
      ? Math.round(usdToStored(parseFloat(originalPrice) || 0, usdRate) * 100) / 100
      : null;

    const productPayload = {
      name,
      tag: tag || null,
      description,
      category: selectedCat.name,
      categoryId: selectedCat.id,
      type,
      price: storedPrice,
      priceInCents: Math.round(storedPrice * 100),
      originalPrice: storedOriginalPrice,
      image: image || "/products/PhotoshopExtension_Image_1.png", // default fallback
      stockQuantity: parseInt(stockQuantity, 10) || 0,
      updatedAt: serverTimestamp()
    };

    try {
      if (editingProduct) {
        // Update existing product — isActive is managed by its own toggle,
        // never overwritten here.
        const productRef = doc(db, "products", editingProduct.id);
        await updateDoc(productRef, productPayload);
      } else {
        // Add new product
        await addDoc(collection(db, "products"), {
          ...productPayload,
          isActive: true,
          createdAt: serverTimestamp()
        });
      }
      setIsModalOpen(false);
    } catch (e) {
      console.error("Error saving product:", e);
    }
  };

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-0 md:ml-64 flex-1 flex flex-col min-h-screen relative bento-pattern overflow-hidden">
        <Header title="Shop Management" />

        {/* Sub Navigation */}
        <div className="px-8 py-2 bg-background/40 backdrop-blur-sm border-b border-outline-variant flex gap-6">
          {[
            { id: "products", label: "PRODUCTS" },
            { id: "categories", label: "CATEGORIES" },
            { id: "banners", label: "BANNERS" },
            { id: "orders", label: "ORDERS" },
            { id: "inventory", label: "INVENTORY" },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`font-label-accent tracking-widest pb-1 text-[10px] uppercase transition-colors ${
                activeTab === tab.id
                  ? "text-primary font-bold border-b-2 border-primary"
                  : "text-on-surface-variant hover:text-primary"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Content Canvas */}
        <div className="p-8 max-w-[1400px] mx-auto w-full relative z-10">
          <div className="bg-surface-card border border-border-subtle rounded-xl overflow-hidden shadow-2xl">
            {activeTab === "products" && (
              <>
                <div className="p-6 border-b border-border-subtle flex justify-between items-center">
                  <h3 className="font-headline-md text-headline-md text-on-background text-xl">Product Catalog</h3>
                  <div className="flex gap-4">
                    <button
                      onClick={() => {}}
                      className="flex items-center gap-2 border border-outline-variant px-4 py-2 rounded font-label-accent text-[10px] text-on-background hover:bg-surface-container-high transition-all opacity-50 cursor-not-allowed"
                      title="Auto-refreshing via real-time sync"
                    >
                      <span className="material-symbols-outlined text-sm">sync</span>
                      LIVE SYNC
                    </button>
                    <button 
                      onClick={openAddModal}
                      className="flex items-center gap-2 bg-primary text-on-primary px-4 py-2 rounded font-label-accent text-[10px] hover:brightness-110 transition-all"
                    >
                      <span className="material-symbols-outlined text-sm">add</span>
                      NEW PRODUCT
                    </button>
                  </div>

                </div>

                <div className="overflow-x-auto">
                  {loading ? (
                    <div className="p-12 text-center text-on-surface-variant flex flex-col items-center justify-center gap-4">
                      <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary"></div>
                      <p className="text-xs font-label-accent uppercase tracking-widest">Loading Catalog...</p>
                    </div>
                  ) : products.length === 0 ? (
                    <div className="p-12 text-center text-on-surface-variant">
                      <p className="text-sm mb-2">No products found in the database catalog.</p>
                      <p className="text-xs text-text-secondary">Click NEW PRODUCT to publish your first item, or verify Firebase authentication permissions.</p>
                    </div>
                  ) : (
                    <table className="w-full text-left border-collapse">
                      <thead>
                        <tr className="bg-surface-container-low border-b border-border-subtle">
                          <th className="px-6 py-4 font-label-accent text-[10px] text-primary uppercase tracking-widest">Image</th>
                          <th className="px-6 py-4 font-label-accent text-[10px] text-primary uppercase tracking-widest">Name</th>
                          <th className="px-6 py-4 font-label-accent text-[10px] text-primary uppercase tracking-widest">Category</th>
                          <th className="px-6 py-4 font-label-accent text-[10px] text-primary uppercase tracking-widest">Price</th>
                          <th className="px-6 py-4 font-label-accent text-[10px] text-primary uppercase tracking-widest">Stock</th>
                          <th className="px-6 py-4 font-label-accent text-[10px] text-primary uppercase tracking-widest">Tag</th>
                          <th className="px-6 py-4 font-label-accent text-[10px] text-primary uppercase tracking-widest text-center">Active</th>
                          <th className="px-6 py-4 font-label-accent text-[10px] text-primary uppercase tracking-widest text-right">Actions</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-border-subtle">
                        {products.map((product) => (
                          <tr key={product.id} className="hover:bg-surface-container transition-colors group">
                            <td className="px-6 py-4">
                              <div className="w-16 h-16 rounded-lg bg-surface-container-high overflow-hidden border border-outline-variant">
                                <img className="w-full h-full object-cover" src={product.image || "/products/PhotoshopExtension_Image_1.png"} alt={product.name} />
                              </div>
                            </td>
                            <td className="px-6 py-4">
                              <p className="font-body-lg text-sm text-on-surface font-semibold">{product.name}</p>
                              <p className="font-body-md text-xs text-on-surface-variant">ID: {product.id}</p>
                            </td>
                            <td className="px-6 py-4">
                              <span className="font-label-accent text-[10px] border border-primary/30 text-primary px-3 py-1 rounded-full">{product.category}</span>
                            </td>
                            <td className="px-6 py-4 font-body-lg text-sm text-on-surface">{formatUsd(product.price, usdRate)}</td>
                            <td className="px-6 py-4">
                              <span className={`font-body-md text-xs ${
                                (product.stockQuantity ?? 0) === 0
                                  ? "text-status-cancelled"
                                  : (product.stockQuantity ?? 0) < 10
                                  ? "text-amber-400"
                                  : "text-on-surface-variant"
                              }`}>
                                {product.stockQuantity ?? 0} units
                              </span>
                            </td>
                            <td className="px-6 py-4">
                              <span className="font-body-md text-xs text-on-surface-variant">{product.tag || "None"}</span>
                            </td>
                            <td className="px-6 py-4 text-center">
                              <label className="relative inline-flex items-center cursor-pointer">
                                <input 
                                  checked={product.isActive} 
                                  onChange={() => handleToggleActive(product.id, product.isActive)}
                                  className="sr-only peer" 
                                  type="checkbox" 
                                />
                                <div className="w-11 h-6 bg-surface-container-highest rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                              </label>
                            </td>
                            <td className="px-6 py-4 text-right">
                              <div className="flex justify-end gap-3 opacity-0 group-hover:opacity-100 transition-opacity">
                                <button 
                                  onClick={() => openEditModal(product)}
                                  className="material-symbols-outlined text-primary hover:text-primary-fixed text-lg"
                                >
                                  edit
                                </button>
                                <button 
                                  onClick={() => handleDeleteProduct(product.id)}
                                  className="material-symbols-outlined text-status-cancelled hover:opacity-80 text-lg"
                                >
                                  delete
                                </button>
                              </div>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </div>
              </>
            )}

            {activeTab === "categories" && (
              <div className="p-8 space-y-6">
                <div className="flex justify-between items-center">
                  <h3 className="font-headline-md text-xl text-on-background">Product Categories ({categories.length})</h3>
                  <button
                    onClick={openAddCatModal}
                    className="flex items-center gap-2 bg-primary text-on-primary px-4 py-2 rounded font-label-accent text-[10px] hover:brightness-110 transition-all"
                  >
                    <span className="material-symbols-outlined text-sm">add</span>
                    NEW CATEGORY
                  </button>
                </div>
                {categories.length === 0 ? (
                  <div className="p-12 text-center text-on-surface-variant bg-surface-container/40 rounded-xl border border-border-subtle">
                    <p className="text-sm">No categories yet.</p>
                    <p className="text-xs text-text-secondary mt-1">Add one so products can be organized and filtered on the storefront.</p>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                    {categories.map((cat) => {
                      const count = products.filter((p) => p.categoryId === cat.id).length;
                      return (
                        <div key={cat.id} className="p-6 bg-surface-container rounded-xl border border-border-subtle hover:border-primary/50 transition-colors group relative">
                          <div className="absolute top-4 right-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button onClick={() => openEditCatModal(cat)} className="material-symbols-outlined text-primary hover:text-primary-fixed text-base">edit</button>
                            <button onClick={() => handleDeleteCategory(cat)} className="material-symbols-outlined text-status-cancelled hover:opacity-80 text-base">delete</button>
                          </div>
                          <h4 className="font-bold text-primary text-base pr-12">{cat.name}</h4>
                          <p className="text-xs text-on-surface-variant mt-1">{cat.description}</p>
                          <span className="inline-block mt-4 text-[10px] font-label-accent text-primary bg-primary/10 px-3 py-1 rounded-full">
                            {count} {count === 1 ? "Item" : "Items"}
                          </span>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            )}

            {activeTab === "banners" && (
              <div className="p-8 space-y-6">
                <div className="flex justify-between items-center">
                  <h3 className="font-headline-md text-xl text-on-background">Promo Banners ({banners.length})</h3>
                  <button
                    onClick={openAddBannerModal}
                    className="flex items-center gap-2 bg-primary text-on-primary px-4 py-2 rounded font-label-accent text-[10px] hover:brightness-110 transition-all"
                  >
                    <span className="material-symbols-outlined text-sm">add</span>
                    NEW BANNER
                  </button>
                </div>
                <p className="text-xs text-text-secondary -mt-2">
                  Active banners appear as a promo carousel on the mobile app&apos;s Home and Shop screens.
                </p>
                {banners.length === 0 ? (
                  <div className="p-12 text-center text-on-surface-variant bg-surface-container/40 rounded-xl border border-border-subtle">
                    <p className="text-sm">No banners yet.</p>
                    <p className="text-xs text-text-secondary mt-1">Add one to feature a promotion or collection on the app.</p>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {banners.map((banner) => (
                      <div key={banner.id} className="bg-surface-container rounded-xl border border-border-subtle overflow-hidden group relative">
                        <div className="h-28 bg-surface-container-high overflow-hidden">
                          {banner.imageUrl ? (
                            <img className="w-full h-full object-cover" src={banner.imageUrl} alt={banner.title} />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center text-on-surface-variant text-xs">No image</div>
                          )}
                        </div>
                        <div className="p-4">
                          <div className="flex justify-between items-start gap-2">
                            <h4 className="font-bold text-primary text-sm">{banner.title}</h4>
                            <div className="flex gap-2 shrink-0">
                              <button onClick={() => openEditBannerModal(banner)} className="material-symbols-outlined text-primary hover:text-primary-fixed text-base">edit</button>
                              <button onClick={() => handleDeleteBanner(banner)} className="material-symbols-outlined text-status-cancelled hover:opacity-80 text-base">delete</button>
                            </div>
                          </div>
                          <p className="text-xs text-on-surface-variant mt-1 line-clamp-2">{banner.subtitle}</p>
                          <div className="flex items-center justify-between mt-3">
                            <span className="text-[10px] font-label-accent text-primary bg-primary/10 px-3 py-1 rounded-full">{banner.cta}</span>
                            <label className="relative inline-flex items-center cursor-pointer">
                              <input
                                checked={banner.isActive}
                                onChange={() => handleToggleBannerActive(banner)}
                                className="sr-only peer"
                                type="checkbox"
                              />
                              <div className="w-9 h-5 bg-surface-container-highest rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-primary"></div>
                            </label>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {activeTab === "orders" && (
              <div className="p-8 space-y-6">
                <div className="flex justify-between items-center">
                  <h3 className="font-headline-md text-xl text-on-background">Store Orders ({ordersList.length})</h3>
                  <button
                    onClick={() => {}}
                    className="flex items-center gap-2 border border-outline-variant px-3 py-1.5 rounded font-label-accent text-[10px] text-on-background hover:bg-surface-container-high transition-all opacity-50 cursor-not-allowed"
                    title="Auto-refreshing via real-time sync"
                  >
                    <span className="material-symbols-outlined text-sm">sync</span>
                    LIVE SYNC
                  </button>
                </div>
                {ordersList.length === 0 ? (
                  <div className="p-12 text-center text-on-surface-variant bg-surface-container/40 rounded-xl border border-border-subtle">
                    <p className="text-sm">No live orders recorded yet.</p>
                    <p className="text-xs text-text-secondary mt-1">Orders placed on the Web Storefront or Mobile App will appear here in real time.</p>
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse text-sm">
                    <thead>
                      <tr className="bg-surface-container-low border-b border-border-subtle text-primary font-label-accent text-[10px]">
                        <th className="px-6 py-4">ORDER ID</th>
                        <th className="px-6 py-4">CUSTOMER</th>
                        <th className="px-6 py-4">ITEMS</th>
                        <th className="px-6 py-4">TOTAL</th>
                        <th className="px-6 py-4">STATUS</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border-subtle">
                      {ordersList.map((order) => (
                        <tr key={order.id} className="hover:bg-surface-container">
                          <td className="px-6 py-4 font-mono font-bold text-primary">
                            {order.trackingCode || `#${order.id.substring(0, 8)}`}
                          </td>
                          <td className="px-6 py-4">
                            <p className="font-semibold text-on-surface">{order.shipping?.name || order.customer?.fullName || order.customerName || "Customer"}</p>
                            <p className="text-xs text-on-surface-variant">{order.shipping?.phone || order.customer?.phone || order.phone}</p>
                            {(order.shipping?.email || order.customer?.email) && (
                              <p className="text-xs text-on-surface-variant">{order.shipping?.email || order.customer?.email}</p>
                            )}
                          </td>
                          <td className="px-6 py-4 text-xs text-on-surface-variant">
                            {order.items ? `${order.items.length} item(s)` : "1 item"}
                          </td>
                          <td className="px-6 py-4 font-semibold text-primary">
                            ${(order.totalInCents != null ? order.totalInCents / 100 : (order.total || order.amount || 0)).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                          </td>
                          <td className="px-6 py-4">
                            <select
                              value={order.status || "Processing"}
                              onChange={(e) => handleUpdateOrderStatus(order.id, e.target.value)}
                              className="bg-[#1A1A1A] border border-outline-variant text-xs text-on-surface rounded px-3 py-1.5 focus:outline-none focus:border-primary cursor-pointer"
                            >
                              <option value="Processing">Processing</option>
                              <option value="Shipped">Shipped</option>
                              <option value="Delivered">Delivered</option>
                              <option value="Cancelled">Cancelled</option>
                            </select>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  </div>
                )}
              </div>
            )}


            {activeTab === "inventory" && (
              <div className="p-8 space-y-6">
                <h3 className="font-headline-md text-xl text-on-background">Inventory Overview</h3>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <div className="p-6 bg-surface-container rounded-xl border border-border-subtle">
                    <p className="text-xs text-on-surface-variant font-label-accent uppercase">Total Stock</p>
                    <p className="text-3xl font-bold text-primary mt-2">
                      {products.reduce((sum, p) => sum + (p.stockQuantity ?? 0), 0).toLocaleString()} Units
                    </p>
                  </div>
                  <div className="p-6 bg-surface-container rounded-xl border border-border-subtle">
                    <p className="text-xs text-on-surface-variant font-label-accent uppercase">Low Stock Alerts</p>
                    <p className="text-3xl font-bold text-amber-400 mt-2">
                      {products.filter((p) => (p.stockQuantity ?? 0) > 0 && (p.stockQuantity ?? 0) < 10).length} Items
                    </p>
                  </div>
                  <div className="p-6 bg-surface-container rounded-xl border border-border-subtle">
                    <p className="text-xs text-on-surface-variant font-label-accent uppercase">Out of Stock</p>
                    <p className="text-3xl font-bold text-emerald-400 mt-2">
                      {products.filter((p) => (p.stockQuantity ?? 0) === 0).length} Items
                    </p>
                  </div>
                </div>
              </div>
            )}

            
            <div className="p-6 bg-surface-container-lowest border-t border-border-subtle flex justify-between items-center">
              <p className="font-body-md text-xs text-on-surface-variant">Showing {products.length} of {products.length} products</p>
            </div>
          </div>
        </div>

        {/* Add/Edit Product Modal */}
        {isModalOpen && (
          <div className="fixed inset-0 z-[100] bg-black/90 backdrop-blur-sm overflow-y-auto flex items-center justify-center py-10">
            <div className="max-w-[800px] w-full mx-6 bg-surface-card border border-border-subtle rounded-2xl shadow-2xl relative my-auto">
              {/* Modal Header */}
              <div className="sticky top-0 z-10 bg-surface-card/95 backdrop-blur-md px-10 py-6 border-b border-border-subtle flex justify-between items-center">
                <div>
                  <h2 className="font-headline-lg text-2xl text-primary">{editingProduct ? "Edit Product" : "Add New Product"}</h2>
                  <p className="font-body-md text-xs text-on-surface-variant">Configure product details in the database catalog.</p>
                </div>
                <button 
                  onClick={() => setIsModalOpen(false)}
                  className="w-10 h-10 rounded-full border border-outline-variant flex items-center justify-center text-on-surface-variant hover:text-primary hover:border-primary transition-all"
                >
                  <span className="material-symbols-outlined text-xl">close</span>
                </button>
              </div>
              
              <form onSubmit={handleSubmit}>
                <div className="p-10 space-y-6 max-h-[60vh] overflow-y-auto">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <label className="block font-label-accent text-[10px] text-primary tracking-widest uppercase">Product Name</label>
                      <input 
                        value={name} 
                        onChange={(e) => setName(e.target.value)}
                        className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary transition-all" 
                        placeholder="e.g. Royal Amber Musk" 
                        required 
                        type="text" 
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="block font-label-accent text-[10px] text-primary tracking-widest uppercase">Tagline / Badge</label>
                      <input 
                        value={tag} 
                        onChange={(e) => setTag(e.target.value)}
                        className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary transition-all" 
                        placeholder="e.g. New, Bestseller, Premium" 
                        type="text" 
                      />
                    </div>
                    <div className="col-span-full space-y-2">
                      <label className="block font-label-accent text-[10px] text-primary tracking-widest uppercase">Detailed Description</label>
                      <textarea 
                        value={description} 
                        onChange={(e) => setDescription(e.target.value)}
                        className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary transition-all" 
                        placeholder="Describe notes, craft, and sizes..." 
                        rows={3}
                        required
                      ></textarea>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-sm">
                    <div className="space-y-2">
                      <label className="block font-label-accent text-[10px] text-primary tracking-widest uppercase">Category</label>
                      <select
                        value={categorySelection}
                        onChange={(e) => setCategorySelection(e.target.value)}
                        className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 focus:outline-none focus:border-primary transition-all appearance-none cursor-pointer"
                        required
                        disabled={categories.length === 0}
                      >
                        {categories.length === 0 && <option value="">No categories yet — add one first</option>}
                        {categories.map((cat) => (
                          <option key={cat.id} value={cat.id}>{cat.name}</option>
                        ))}
                      </select>
                    </div>
                    <div className="space-y-2">
                      <label className="block font-label-accent text-[10px] text-primary tracking-widest uppercase">Price (USD)</label>
                      <input
                        value={price}
                        onChange={(e) => setPrice(e.target.value)}
                        className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 focus:outline-none focus:border-primary transition-all"
                        placeholder="25.00"
                        required
                        step="0.01"
                        type="number"
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="block font-label-accent text-[10px] text-primary tracking-widest uppercase">Original Price (USD, optional)</label>
                      <input
                        value={originalPrice}
                        onChange={(e) => setOriginalPrice(e.target.value)}
                        className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 focus:outline-none focus:border-primary transition-all"
                        placeholder="Before discount"
                        step="0.01"
                        type="number"
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <label className="block font-label-accent text-[10px] text-primary tracking-widest uppercase">Image URL / Path</label>
                    <input
                      value={image}
                      onChange={(e) => setImage(e.target.value)}
                      className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary transition-all"
                      placeholder="e.g. /products/p 1.png"
                      type="text"
                    />
                  </div>

                  <div className="space-y-2">
                    <label className="block font-label-accent text-[10px] text-primary tracking-widest uppercase">Stock Quantity</label>
                    <input
                      value={stockQuantity}
                      onChange={(e) => setStockQuantity(e.target.value)}
                      className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 focus:outline-none focus:border-primary transition-all"
                      placeholder="0"
                      required
                      min={0}
                      type="number"
                    />
                    <p className="text-[10px] text-on-surface-variant">Used for checkout stock checks and the Inventory tab.</p>
                  </div>
                </div>
                
                {/* Modal Footer */}
                <div className="px-10 py-8 border-t border-border-subtle flex justify-end gap-6 bg-surface-container-lowest rounded-b-2xl">
                  <button 
                    type="button"
                    onClick={() => setIsModalOpen(false)}
                    className="px-8 py-3 rounded font-label-accent text-[10px] tracking-widest text-on-surface-variant hover:text-on-surface transition-all"
                  >
                    DISCARD
                  </button>
                  <button 
                    type="submit"
                    className="bg-primary px-12 py-3 rounded font-label-accent text-[10px] tracking-widest text-on-primary shadow-lg shadow-primary/20 hover:brightness-110 transition-all"
                  >
                    {editingProduct ? "SAVE CHANGES" : "PUBLISH PRODUCT"}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Add/Edit Category Modal */}
        {isCatModalOpen && (
          <div className="fixed inset-0 z-[100] bg-black/90 backdrop-blur-sm overflow-y-auto flex items-center justify-center p-4">
            <div className="max-w-[500px] w-full bg-surface-card border border-border-subtle rounded-2xl shadow-2xl">
              <div className="px-8 py-6 border-b border-border-subtle flex justify-between items-center">
                <h2 className="font-headline-lg text-xl text-primary">{editingCategory ? "Edit Category" : "New Category"}</h2>
                <button
                  onClick={() => setIsCatModalOpen(false)}
                  className="text-on-surface-variant hover:text-primary transition-colors"
                >
                  <span className="material-symbols-outlined">close</span>
                </button>
              </div>
              <form onSubmit={handleCatSubmit} className="p-8 space-y-5">
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Name</label>
                  <input
                    value={catName}
                    onChange={(e) => setCatName(e.target.value)}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                    placeholder="e.g. Ramadan & Eid"
                    required
                  />
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Description</label>
                  <textarea
                    value={catDescription}
                    onChange={(e) => setCatDescription(e.target.value)}
                    rows={2}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary resize-none"
                    placeholder="Short description shown to shoppers"
                  />
                </div>
                {editingCategory && (
                  <p className="text-[10px] text-on-surface-variant">ID: {editingCategory.id} (fixed — products reference this)</p>
                )}
                <div className="pt-2 flex justify-end gap-4">
                  <button type="button" onClick={() => setIsCatModalOpen(false)} className="text-on-surface-variant text-xs">CANCEL</button>
                  <button type="submit" className="bg-primary text-on-primary px-6 py-2 rounded text-xs">
                    {editingCategory ? "SAVE CHANGES" : "ADD CATEGORY"}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Add/Edit Banner Modal */}
        {isBannerModalOpen && (
          <div className="fixed inset-0 z-[100] bg-black/90 backdrop-blur-sm overflow-y-auto flex items-center justify-center p-4">
            <div className="max-w-[500px] w-full bg-surface-card border border-border-subtle rounded-2xl shadow-2xl">
              <div className="px-8 py-6 border-b border-border-subtle flex justify-between items-center">
                <h2 className="font-headline-lg text-xl text-primary">{editingBanner ? "Edit Banner" : "New Banner"}</h2>
                <button
                  onClick={() => setIsBannerModalOpen(false)}
                  className="text-on-surface-variant hover:text-primary transition-colors"
                >
                  <span className="material-symbols-outlined">close</span>
                </button>
              </div>
              <form onSubmit={handleBannerSubmit} className="p-8 space-y-5">
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Title</label>
                  <input
                    value={bannerTitle}
                    onChange={(e) => setBannerTitle(e.target.value)}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                    placeholder="e.g. Ramadan Collection"
                    required
                  />
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Subtitle</label>
                  <textarea
                    value={bannerSubtitle}
                    onChange={(e) => setBannerSubtitle(e.target.value)}
                    rows={2}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary resize-none"
                    placeholder="Short line shown under the title"
                  />
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Image URL</label>
                  <input
                    value={bannerImageUrl}
                    onChange={(e) => setBannerImageUrl(e.target.value)}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                    placeholder="https://..."
                  />
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Button Label</label>
                  <input
                    value={bannerCta}
                    onChange={(e) => setBannerCta(e.target.value)}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                    placeholder="Shop now"
                  />
                </div>
                <label className="flex items-center gap-3 cursor-pointer w-fit">
                  <input
                    type="checkbox"
                    checked={bannerIsActive}
                    onChange={(e) => setBannerIsActive(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-surface-container-highest rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary relative"></div>
                  <span className="text-xs text-on-surface-variant">Active (visible on the app)</span>
                </label>
                <div className="pt-2 flex justify-end gap-4">
                  <button type="button" onClick={() => setIsBannerModalOpen(false)} className="text-on-surface-variant text-xs">CANCEL</button>
                  <button type="submit" className="bg-primary text-on-primary px-6 py-2 rounded text-xs">
                    {editingBanner ? "SAVE CHANGES" : "ADD BANNER"}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Background Watermark Pattern */}
        <div className="fixed inset-0 pointer-events-none opacity-[0.03] z-0 flex items-center justify-center overflow-hidden">
          <svg fill="none" height="800" viewBox="0 0 200 200" width="800" xmlns="http://www.w3.org/2000/svg">
            <path d="M100 0L129.389 70.6107L200 100L129.389 129.389L100 200L70.6107 129.389L0 100L70.6107 70.6107L100 0Z" fill="#C9A84C"></path>
          </svg>
        </div>
      </main>
    </div>
  );
}
