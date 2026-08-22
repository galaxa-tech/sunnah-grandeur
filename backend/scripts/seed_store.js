/**
 * seed_store.js
 * Seeds all 30 products + 10 categories from sunnah-grandeur-master/src/data
 * into the live Firestore project.
 *
 * Run from functions/ dir:
 *   node ../scripts/seed_store.js
 */
"use strict";

const admin = require("firebase-admin");

// Use Application Default Credentials (firebase CLI login works)
admin.initializeApp({ projectId: "sunnah-grandeur" });
const db = admin.firestore();

// ── Categories (matches src/data/categories.ts) ───────────────────────────────
const categories = [
  { id: "men",       name: "Men",            icon: "person",       accentColor: "#C9A84C", sortOrder: 1,  isActive: true },
  { id: "women",     name: "Women",          icon: "woman",        accentColor: "#8BC38B", sortOrder: 2,  isActive: true },
  { id: "kids",      name: "Kids",           icon: "child_care",   accentColor: "#6BB5D4", sortOrder: 3,  isActive: true },
  { id: "salah",     name: "Salah & Worship",icon: "mosque",       accentColor: "#C9A84C", sortOrder: 4,  isActive: true },
  { id: "quran",     name: "Quran & Books",  icon: "menu_book",    accentColor: "#8BC38B", sortOrder: 5,  isActive: true },
  { id: "fragrance", name: "Fragrance",      icon: "water_drop",   accentColor: "#C9A84C", sortOrder: 6,  isActive: true },
  { id: "home",      name: "Home & Decor",   icon: "home",         accentColor: "#6BB5D4", sortOrder: 7,  isActive: true },
  { id: "ramadan",   name: "Ramadan & Eid",  icon: "star",         accentColor: "#E87D7D", sortOrder: 8,  isActive: true },
  { id: "hajj",      name: "Hajj & Umrah",   icon: "flight",       accentColor: "#7DD4A8", sortOrder: 9,  isActive: true },
  { id: "gifts",     name: "Gifts",          icon: "card_giftcard",accentColor: "#D4A0C4", sortOrder: 10, isActive: true },
];

// ── Products (matches src/data/products.ts — 30 items) ───────────────────────
const products = [
  // Fragrance
  { id:"1",  name:"Jo Malone Wood Sage & Sea Salt",    category:"Fragrance",      categoryId:"fragrance", priceInCents:69200,  originalPriceInCents:79700,  images:["/products/PhotoshopExtension_Image_1.png"], description:"Fresh contemporary fragrance with notes of ambrette, sea salt and sage.", isFeatured:true,  badge:"New",       isActive:true, stockQuantity:50,  sku:"FR-001" },
  { id:"2",  name:"Black Opium",                        category:"Fragrance",      categoryId:"fragrance", priceInCents:89900,  originalPriceInCents:99000,  images:["/products/PhotoshopExtension_Image_2.png"], description:"Addictive blend of coffee, white flowers and vanilla.", isFeatured:true,  badge:null,        isActive:true, stockQuantity:30,  sku:"FR-002" },
  { id:"3",  name:"Acqua di Gio",                       category:"Fragrance",      categoryId:"fragrance", priceInCents:23800,  originalPriceInCents:30200,  images:["/products/PhotoshopExtension_Image_3.png"], description:"An aromatic aquatic fragrance with notes of bergamot and rosemary.", isFeatured:true,  badge:null,        isActive:true, stockQuantity:80,  sku:"FR-003" },
  { id:"4",  name:"La Vie Est Belle",                   category:"Fragrance",      categoryId:"fragrance", priceInCents:45400,  originalPriceInCents:51600,  images:["/products/PhotoshopExtension_Image_4.png"], description:"A floral and gourmand fragrance celebrating the beauty of life.", isFeatured:false, badge:null,        isActive:true, stockQuantity:60,  sku:"FR-004" },
  { id:"5",  name:"Sauvage",                            category:"Fragrance",      categoryId:"fragrance", priceInCents:16500,  originalPriceInCents:20900,  images:["/products/PhotoshopExtension_Image_5.png"], description:"Fresh raw aromatic fragrance inspired by open wild landscapes.", isFeatured:false, badge:null,        isActive:true, stockQuantity:90,  sku:"FR-005" },
  { id:"6",  name:"Oud Maracuia",                       category:"Fragrance",      categoryId:"fragrance", priceInCents:85400,  originalPriceInCents:92900,  images:["/products/PhotoshopExtension_Image_6.png"], description:"Exotic oud blend with tropical passion fruit notes.", isFeatured:true,  badge:"Sold Out",  isActive:true, stockQuantity:0,   sku:"FR-006" },
  // Salah & Worship
  { id:"7",  name:"Premium Prayer Mat Collection",      category:"Salah & Worship",categoryId:"salah",     priceInCents:58000,  originalPriceInCents:72000,  images:["/products/p 3.png"],                        description:"Thick padded prayer mats with traditional mihrab design. Available in 5 colours.", isFeatured:true,  badge:"Bestseller",isActive:true, stockQuantity:120, sku:"SA-007" },
  { id:"8",  name:"Wooden Tasbih 99-Bead",             category:"Salah & Worship",categoryId:"salah",     priceInCents:38000,  originalPriceInCents:null,   images:["/products/p 2.png"],                        description:"Hand-crafted 99-bead tasbih from olive wood with bronze accent pieces.", isFeatured:false, badge:null,        isActive:true, stockQuantity:200, sku:"SA-008" },
  { id:"9",  name:"Luxury Sajjadah",                   category:"Salah & Worship",categoryId:"salah",     priceInCents:165000, originalPriceInCents:190000, images:[],                                           description:"Hand-tufted Turkish prayer mat with Kaaba motif. Extra thick 10mm padding.", bgGradient:"linear-gradient(145deg, #1a0f1a 0%, #2d182d 50%, #1a0f1a 100%)", bgIcon:"mosque",    isFeatured:true,  badge:"Premium",   isActive:true, stockQuantity:15,  sku:"SA-009" },
  { id:"10", name:"Adhan Smart Clock",                  category:"Salah & Worship",categoryId:"salah",     priceInCents:210000, originalPriceInCents:240000, images:[],                                           description:"Auto location-based adhan clock with 7 qira'at options and LED display.", bgGradient:"linear-gradient(145deg, #0a0f1a 0%, #101828 50%, #0a0f1a 100%)", bgIcon:"alarm",    isFeatured:false, badge:"New",        isActive:true, stockQuantity:25,  sku:"SA-010" },
  // Home & Decor
  { id:"11", name:"Islamic Arch Wall Art",              category:"Home & Decor",   categoryId:"home",      priceInCents:125000, originalPriceInCents:150000, images:["/products/p 1.png"],                        description:"Framed canvas art of ornate Islamic arches in teal and gold. 60×80 cm.", isFeatured:true,  badge:"New",       isActive:true, stockQuantity:40,  sku:"HD-011" },
  { id:"12", name:"Crescent Moon Lamp",                 category:"Home & Decor",   categoryId:"home",      priceInCents:86000,  originalPriceInCents:null,   images:[],                                           description:"Warm LED crescent moon lamp with 3 brightness levels. USB rechargeable.", bgGradient:"linear-gradient(145deg, #0d1520 0%, #102030 50%, #0d1520 100%)", bgIcon:"light_mode", isFeatured:false, badge:null,       isActive:true, stockQuantity:70,  sku:"HD-012" },
  // Women
  { id:"13", name:"Olive Khimar Set",                   category:"Women",          categoryId:"women",     priceInCents:75000,  originalPriceInCents:90000,  images:["/products/p 4.png"],                        description:"Two-layer olive green khimar in premium nida fabric. Flowing, modest, elegant.", isFeatured:true,  badge:"New",       isActive:true, stockQuantity:60,  sku:"WO-013" },
  { id:"14", name:"Embroidered Abaya",                  category:"Women",          categoryId:"women",     priceInCents:320000, originalPriceInCents:380000, images:[],                                           description:"Flowing crepe abaya with hand-embroidered floral motifs on cuffs and hem.", bgGradient:"linear-gradient(145deg, #0a0a0a 0%, #1a1a2d 50%, #0a0a0a 100%)", bgIcon:"woman",   isFeatured:false, badge:null,        isActive:true, stockQuantity:20,  sku:"WO-014" },
  { id:"15", name:"Premium Jersey Hijab",               category:"Women",          categoryId:"women",     priceInCents:32000,  originalPriceInCents:null,   images:[],                                           description:"Soft jersey hijab with no-slip inner grip. Available in 12 colours.", bgGradient:"linear-gradient(145deg, #150a1a 0%, #251030 50%, #150a1a 100%)", bgIcon:"sentiment_very_satisfied", isFeatured:false, badge:"Bestseller", isActive:true, stockQuantity:200, sku:"WO-015" },
  // Men
  { id:"16", name:"Kufi Prayer Cap Set",                category:"Men",            categoryId:"men",       priceInCents:45000,  originalPriceInCents:55000,  images:["/products/p 5.png"],                        description:"Set of 3 premium woven kufis — tan, navy, and grey. One size fits most.", isFeatured:true,  badge:null,        isActive:true, stockQuantity:100, sku:"ME-016" },
  { id:"17", name:"Classic White Thobe",                category:"Men",            categoryId:"men",       priceInCents:185000, originalPriceInCents:220000, images:[],                                           description:"Premium cotton thobe with subtle embroidery at the collar. Machine washable.", bgGradient:"linear-gradient(145deg, #1a1a1a 0%, #2d2d2d 50%, #1a1a1a 100%)", bgIcon:"person",  isFeatured:false, badge:"New",        isActive:true, stockQuantity:35,  sku:"ME-017" },
  { id:"18", name:"Sunnah Grooming Kit",                category:"Men",            categoryId:"men",       priceInCents:58000,  originalPriceInCents:null,   images:[],                                           description:"Complete kit: beard oil, miswak, kohl, and scissors in a premium gift box.", bgGradient:"linear-gradient(145deg, #0f150a 0%, #1e2812 50%, #0f150a 100%)", bgIcon:"content_cut", isFeatured:false, badge:null,      isActive:true, stockQuantity:80,  sku:"ME-018" },
  // Kids
  { id:"19", name:"Kids Prayer Mat Set",                category:"Kids",           categoryId:"kids",      priceInCents:42000,  originalPriceInCents:50000,  images:[],                                           description:"Fun prayer mat designed to teach children the correct prayer positions.", bgGradient:"linear-gradient(145deg, #1a0a10 0%, #2d1020 50%, #1a0a10 100%)", bgIcon:"mosque",  isFeatured:true,  badge:null,        isActive:true, stockQuantity:90,  sku:"KI-019" },
  { id:"20", name:"Arabic Learning Puzzle",             category:"Kids",           categoryId:"kids",      priceInCents:35000,  originalPriceInCents:null,   images:[],                                           description:"Wooden Arabic alphabet puzzle with colourful illustrations for ages 2+.", bgGradient:"linear-gradient(145deg, #0f1a0f 0%, #1a2d1a 50%, #0f1a0f 100%)", bgIcon:"toys",    isFeatured:false, badge:"Bestseller", isActive:true, stockQuantity:150, sku:"KI-020" },
  { id:"21", name:"Kids Embroidered Thobe",             category:"Kids",           categoryId:"kids",      priceInCents:68000,  originalPriceInCents:null,   images:[],                                           description:"Soft cotton thobe for boys aged 3–12. Machine washable with gold trim.", bgGradient:"linear-gradient(145deg, #0a1520 0%, #102035 50%, #0a1520 100%)", bgIcon:"child_care", isFeatured:false, badge:null,      isActive:true, stockQuantity:45,  sku:"KI-021" },
  // Quran & Books
  { id:"22", name:"Tajweed Quran — Large Print",        category:"Quran & Books",  categoryId:"quran",     priceInCents:78000,  originalPriceInCents:null,   images:[],                                           description:"Colour-coded tajweed Quran in large 17×24 cm format. Uthmani script.", bgGradient:"linear-gradient(145deg, #0d1a08 0%, #172210 50%, #0d1a08 100%)", bgIcon:"menu_book", isFeatured:true,  badge:null,       isActive:true, stockQuantity:200, sku:"QU-022" },
  { id:"23", name:"Seerah of the Prophet ﷺ",          category:"Quran & Books",  categoryId:"quran",     priceInCents:56000,  originalPriceInCents:65000,  images:[],                                           description:"Comprehensive seerah covering the life of the Prophet from birth to passing.", bgGradient:"linear-gradient(145deg, #100d1a 0%, #1e1830 50%, #100d1a 100%)", bgIcon:"history_edu", isFeatured:false, badge:"New",     isActive:true, stockQuantity:80,  sku:"QU-023" },
  // Gifts
  { id:"24", name:"Eid Gift Box — His",                 category:"Gifts",          categoryId:"gifts",     priceInCents:220000, originalPriceInCents:null,   images:[],                                           description:"Curated box: attar, miswak, tasbih, and premium dates. Beautifully wrapped.", bgGradient:"linear-gradient(145deg, #1a0f15 0%, #2d1a25 50%, #1a0f15 100%)", bgIcon:"card_giftcard", isFeatured:true, badge:"Bestseller", isActive:true, stockQuantity:50,  sku:"GI-024" },
  { id:"25", name:"Eid Gift Box — Hers",                category:"Gifts",          categoryId:"gifts",     priceInCents:195000, originalPriceInCents:230000, images:[],                                           description:"Premium box: floral attar, hijab pins, tasbih, and halal sweets.", bgGradient:"linear-gradient(145deg, #1a0a12 0%, #2d1020 50%, #1a0a12 100%)", bgIcon:"redeem",  isFeatured:false, badge:null,        isActive:true, stockQuantity:30,  sku:"GI-025" },
  // Ramadan & Eid
  { id:"26", name:"Ramadan Planner 2025",               category:"Ramadan & Eid",  categoryId:"ramadan",   priceInCents:34000,  originalPriceInCents:null,   images:[],                                           description:"30-day planner with dua logs, Quran tracker, and meal planners.", bgGradient:"linear-gradient(145deg, #1a0a0a 0%, #2d1515 50%, #1a0a0a 100%)", bgIcon:"edit_calendar", isFeatured:true, badge:"Bestseller", isActive:true, stockQuantity:300, sku:"RA-026" },
  { id:"27", name:"Luxury Date Box",                    category:"Ramadan & Eid",  categoryId:"ramadan",   priceInCents:89000,  originalPriceInCents:105000, images:[],                                           description:"Premium Medjool dates in a hand-crafted wooden box. Perfect Ramadan gift.", bgGradient:"linear-gradient(145deg, #2a1a06 0%, #3d2a08 50%, #2a1a06 100%)", bgIcon:"favorite", isFeatured:false, badge:null,       isActive:true, stockQuantity:75,  sku:"RA-027" },
  // Hajj & Umrah
  { id:"28", name:"Ihram Travel Set",                   category:"Hajj & Umrah",   categoryId:"hajj",      priceInCents:120000, originalPriceInCents:140000, images:[],                                           description:"Complete ihram set: two-piece cotton cloth, belt, sandals, and dua booklet.", bgGradient:"linear-gradient(145deg, #1a1a1a 0%, #2a2a2a 50%, #1a1a1a 100%)", bgIcon:"flight",  isFeatured:true,  badge:null,        isActive:true, stockQuantity:40,  sku:"HJ-028" },
  // Bakhoor
  { id:"29", name:"Royal Bakhoor Incense Set",          category:"Fragrance",      categoryId:"fragrance", priceInCents:95000,  originalPriceInCents:null,   images:[],                                           description:"Traditional Arabic bakhoor chips with a brass mabkhara burner.", bgGradient:"linear-gradient(145deg, #2d1f08 0%, #4a3010 50%, #2d1f08 100%)", bgIcon:"spa",     isFeatured:false, badge:"Premium",   isActive:true, stockQuantity:60,  sku:"FR-029" },
  // Quran Speaker
  { id:"30", name:"Quran Bluetooth Speaker",            category:"Salah & Worship",categoryId:"salah",     priceInCents:185000, originalPriceInCents:210000, images:[],                                           description:"Portable Quran speaker with 30 reciter voices, prayer times, and 12hr battery.", bgGradient:"linear-gradient(145deg, #0a1520 0%, #0d2030 50%, #0a1520 100%)", bgIcon:"speaker", isFeatured:false, badge:"New",       isActive:true, stockQuantity:35,  sku:"SA-030" },
];

async function seed() {
  console.log("🌱 Seeding Sunnah Grandeur Firestore...\n");

  // ── Categories ─────────────────────────────────────────────────────────────
  console.log("📁 Seeding categories...");
  for (const cat of categories) {
    const { id, ...data } = cat;
    await db.collection("categories").doc(id).set(data, { merge: true });
    console.log(`  ✓ ${cat.name}`);
  }

  // ── Products ───────────────────────────────────────────────────────────────
  console.log("\n📦 Seeding products...");
  for (const product of products) {
    const { id, ...data } = product;
    // Remove undefined/null optional fields cleanly
    const clean = Object.fromEntries(
      Object.entries(data).filter(([, v]) => v !== null && v !== undefined)
    );
    await db.collection("products").doc(id).set(clean, { merge: true });
    console.log(`  ✓ [${id}] ${product.name} — $${(product.priceInCents/100).toFixed(0)}`);
  }

  console.log("\n✅ Seeding complete! Total products:", products.length);
  process.exit(0);
}

seed().catch(err => {
  console.error("❌ Seed failed:", err.message || err);
  process.exit(1);
});
