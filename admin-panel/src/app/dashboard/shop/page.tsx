"use client";

import { useState, useEffect } from "react";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { collection, getDocs, doc, addDoc, updateDoc, deleteDoc, serverTimestamp, onSnapshot, query, orderBy } from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { db, functions } from "@/lib/firebase";

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
}

export default function ShopManagementPage() {
  const [activeTab, setActiveTab] = useState<'products' | 'categories' | 'orders' | 'inventory'>('products');
  const [products, setProducts] = useState<Product[]>([]);
  const [ordersList, setOrdersList] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [seeding, setSeeding] = useState(false);

  // Form states
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [name, setName] = useState("");
  const [tag, setTag] = useState("");
  const [description, setDescription] = useState("");
  const [categorySelection, setCategorySelection] = useState("");
  const [price, setPrice] = useState("");
  const [originalPrice, setOriginalPrice] = useState("");
  const [image, setImage] = useState("");

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

    return () => {
      unsubscribeProducts();
      unsubscribeOrders();
    };
  }, []);

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

  const handleSeedDatabase = async () => {
    if (!window.confirm("Seed initial luxury catalog into Firestore?")) return;
    setSeeding(true);
    const seeds = [
      {
        name: "Oud Al-Majd Parfum",
        category: "Fragrance",
        categoryId: "fragrance",
        type: "perfume",
        price: 1850,
        originalPrice: 2200,
        description: "Extrait de Parfum featuring rich Cambodian agarwood, dark rose, and golden amber notes.",
        tag: "Bestseller",
        isActive: true,
        image: "https://lh3.googleusercontent.com/aida/ADBb0uhEEleu7KmJZIDy9o-R0e1n7ajgAMkENyQ4eHjdI4eQF3vTywhBkToaiHR9Wri96NN64i7sdHclPPVpRNUdvoSXdF59d4qSzwG1w_XHiLUvh838-UE1Woog14E6V3-19LDckStk_xuTsJvqDFf8BImFbh4GEmcgYt0syVIceAwHl2ugiPShK_VRzf64WhUtYCrvcfSypyUI1y-s1uKaTV92l8YhScZsofow7Y4QZLUxOOnthfZ42XzihYkrDRq3yIq2VB1P14_jsNs"
      },
      {
        name: "Misbaha - Black Onyx",
        category: "Salah & Worship",
        categoryId: "salah",
        type: "other",
        price: 1200,
        originalPrice: 1500,
        description: "Hand-strung 99-bead natural black onyx tasbih with sterling silver tassel.",
        tag: "Premium",
        isActive: true,
        image: "https://lh3.googleusercontent.com/aida/ADBb0uhsU8VEnWQ1uBQTs_keaDDehAZQcdpIeUxWBS5oK64jU-SKUjoSVsafpJ_sgbzSLDQZ9fc9foE4Qx90LwDtrZxRPaQ_GptANfkOMTQyowXQrmOxL8rPdbd446pAZLymnr5qbrAfNKYatrYHFQsDluDaWaSNICpEeVukO0ZafXKi4tzDm40sA9Awp18xY6mhzxruAg53cGKkiUy6hXoCDvg-JJg9NHAhaPpT61MOTrp8BP7GyKeGKgys1YS1BLQQ7XqxEhe9FyX2Whw"
      },
      {
        name: "Olive Khimar & Abaya Set",
        category: "Women",
        categoryId: "women",
        type: "other",
        price: 3200,
        originalPrice: 3800,
        description: "Breathable crepe silk modest khimar and matching abaya set.",
        tag: "New",
        isActive: true,
        image: "https://lh3.googleusercontent.com/aida/ADBb0ui2-SjL6bK2Z500i8m-R91_1X4mH0l48XqE1KkZ3Kj5_n9A1n4gZ83w3Z82m0m"
      }
    ];

    try {
      for (const item of seeds) {
        await addDoc(collection(db, "products"), {
          ...item,
          createdAt: serverTimestamp()
        });
      }
      alert("Successfully seeded catalog into Firestore!");
    } catch (e) {
      console.error("Error seeding products:", e);
    } finally {
      setSeeding(false);
    }
  };


  const openAddModal = () => {
    setEditingProduct(null);
    setName("");
    setTag("");
    setDescription("");
    setCategorySelection("Fragrance");
    setPrice("");
    setOriginalPrice("");
    setImage("");
    setIsModalOpen(true);
  };

  const openEditModal = (product: Product) => {
    setEditingProduct(product);
    setName(product.name);
    setTag(product.tag || "");
    setDescription(product.description);
    setCategorySelection(product.category);
    setPrice(product.price.toString());
    setOriginalPrice(product.originalPrice ? product.originalPrice.toString() : "");
    setImage(product.image || "");
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
    
    // Map category selection to schema fields
    let category = "Fragrance";
    let categoryId = "fragrance";
    let type: "perfume" | "other" = "perfume";

    if (categorySelection === "Salah & Worship" || categorySelection === "Tasbih & Beads") {
      category = "Salah & Worship";
      categoryId = "salah";
      type = "other";
    } else if (categorySelection === "Women" || categorySelection === "Premium Apparel") {
      category = "Women";
      categoryId = "women";
      type = "other";
    } else if (categorySelection === "Home Decor" || categorySelection === "Home & Decor") {
      category = "Home & Decor";
      categoryId = "home";
      type = "other";
    }

    const productPayload = {
      name,
      tag: tag || null,
      description,
      category,
      categoryId,
      type,
      price: parseFloat(price) || 0,
      originalPrice: originalPrice ? parseFloat(originalPrice) : null,
      image: image || "/products/PhotoshopExtension_Image_1.png", // default fallback
      isActive: true,
      updatedAt: serverTimestamp()
    };

    try {
      if (editingProduct) {
        // Update existing product
        const productRef = doc(db, "products", editingProduct.id);
        await updateDoc(productRef, productPayload);
      } else {
        // Add new product
        await addDoc(collection(db, "products"), {
          ...productPayload,
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
      <main className="ml-64 flex-1 flex flex-col min-h-screen relative bento-pattern overflow-hidden">
        <Header title="Shop Management" />

        {/* Sub Navigation */}
        <div className="px-8 py-2 bg-background/40 backdrop-blur-sm border-b border-outline-variant flex gap-6">
          {[
            { id: "products", label: "PRODUCTS" },
            { id: "categories", label: "CATEGORIES" },
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
                      onClick={async () => {
                        if (!window.confirm("Are you sure you want to PURGE ALL DUMMY PRODUCTS from Firestore?")) return;
                        try {
                          const snap = await getDocs(collection(db, "products"));
                          for (const d of snap.docs) {
                            await deleteDoc(doc(db, "products", d.id));
                          }
                          alert("All dummy products purged successfully!");
                        } catch (err: any) {
                          alert("Error purging catalog: " + err.message);
                        }
                      }}
                      className="flex items-center gap-2 border border-red-500/40 bg-red-500/10 text-red-400 px-4 py-2 rounded font-label-accent text-[10px] hover:bg-red-500/20 transition-all"
                    >
                      <span className="material-symbols-outlined text-sm">delete_forever</span>
                      PURGE DUMMY DATA
                    </button>
                    <button 
                      onClick={handleSeedDatabase}
                      disabled={seeding}
                      className="flex items-center gap-2 border border-primary/40 bg-primary/10 text-primary px-4 py-2 rounded font-label-accent text-[10px] hover:bg-primary/20 transition-all disabled:opacity-50"
                    >
                      <span className="material-symbols-outlined text-sm">database</span>
                      {seeding ? "SEEDING..." : "SEED CATALOG"}
                    </button>
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
                          <th className="px-6 py-4 font-label-accent text-[10px] text-primary uppercase tracking-widest">Price (BDT)</th>
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
                            <td className="px-6 py-4 font-body-lg text-sm text-on-surface">৳{product.price.toFixed(0)}</td>
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
                <h3 className="font-headline-md text-xl text-on-background">Product Categories</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  {[
                    { name: "Fragrances", count: "12 Items", desc: "Pure non-alcoholic attars and extraits" },
                    { name: "Salah & Worship", count: "8 Items", desc: "Prayer mats, misbaha, and qubba items" },
                    { name: "Women", count: "15 Items", desc: "Modest khimar sets and accessories" },
                    { name: "Home & Decor", count: "6 Items", desc: "Islamic arch wall art and incense burners" },
                  ].map((cat) => (
                    <div key={cat.name} className="p-6 bg-surface-container rounded-xl border border-border-subtle hover:border-primary/50 transition-colors">
                      <h4 className="font-bold text-primary text-base">{cat.name}</h4>
                      <p className="text-xs text-on-surface-variant mt-1">{cat.desc}</p>
                      <span className="inline-block mt-4 text-[10px] font-label-accent text-primary bg-primary/10 px-3 py-1 rounded-full">{cat.count}</span>
                    </div>
                  ))}
                </div>
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
                  <table className="w-full text-left border-collapse text-sm">
                    <thead>
                      <tr className="bg-surface-container-low border-b border-border-subtle text-primary font-label-accent text-[10px]">
                        <th className="px-6 py-4">ORDER ID</th>
                        <th className="px-6 py-4">CUSTOMER</th>
                        <th className="px-6 py-4">ITEMS</th>
                        <th className="px-6 py-4">TOTAL (BDT)</th>
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
                            <p className="font-semibold text-on-surface">{order.customer?.fullName || order.customerName || "Customer"}</p>
                            <p className="text-xs text-on-surface-variant">{order.customer?.phone || order.phone}</p>
                          </td>
                          <td className="px-6 py-4 text-xs text-on-surface-variant">
                            {order.items ? `${order.items.length} item(s)` : "1 item"}
                          </td>
                          <td className="px-6 py-4 font-semibold text-primary">
                            ৳{(order.total || order.amount || 0).toLocaleString()}
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
                )}
              </div>
            )}


            {activeTab === "inventory" && (
              <div className="p-8 space-y-6">
                <h3 className="font-headline-md text-xl text-on-background">Inventory Overview</h3>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <div className="p-6 bg-surface-container rounded-xl border border-border-subtle">
                    <p className="text-xs text-on-surface-variant font-label-accent uppercase">Total Stock</p>
                    <p className="text-3xl font-bold text-primary mt-2">1,450 Units</p>
                  </div>
                  <div className="p-6 bg-surface-container rounded-xl border border-border-subtle">
                    <p className="text-xs text-on-surface-variant font-label-accent uppercase">Low Stock Alerts</p>
                    <p className="text-3xl font-bold text-amber-400 mt-2">3 Items</p>
                  </div>
                  <div className="p-6 bg-surface-container rounded-xl border border-border-subtle">
                    <p className="text-xs text-on-surface-variant font-label-accent uppercase">Out of Stock</p>
                    <p className="text-3xl font-bold text-emerald-400 mt-2">0 Items</p>
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
                      >
                        <option value="Fragrance">Attar & Fragrances</option>
                        <option value="Salah & Worship">Tasbih & Beads</option>
                        <option value="Women">Premium Apparel</option>
                        <option value="Home Decor">Home Decor</option>
                      </select>
                    </div>
                    <div className="space-y-2">
                      <label className="block font-label-accent text-[10px] text-primary tracking-widest uppercase">Price (BDT)</label>
                      <input 
                        value={price} 
                        onChange={(e) => setPrice(e.target.value)}
                        className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 focus:outline-none focus:border-primary transition-all" 
                        placeholder="0.00" 
                        required 
                        type="number" 
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="block font-label-accent text-[10px] text-primary tracking-widest uppercase">Original Price (optional)</label>
                      <input 
                        value={originalPrice} 
                        onChange={(e) => setOriginalPrice(e.target.value)}
                        className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 focus:outline-none focus:border-primary transition-all" 
                        placeholder="Before discount" 
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
