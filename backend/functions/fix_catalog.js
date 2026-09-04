"use strict";
const { listCollection, deleteDoc, patchDoc, createDoc, DELETE_FIELD } = require("./_fs_rest");

const TEST_IDS_TO_DELETE = [
  "cMszreoEOKg0YiIs25Tz", // Test Musk Attar
  "prod_live_101",        // Royal Amber Oudh Attar (Live Admin Catalog Item)
  "prod_live_102",        // Emirati Luxury Gold Velvet Sajadah (Live Admin Item)
  "tg6gzrop6Rgm3fQWeLBX", // Live Test Musk Attar
];

// Fix product photos that were pointing at the wrong item (e.g. a prayer mat
// showing a photo of prayer caps). Items with no matching real photo get a
// themed gradient + icon card instead of a mismatched picture.
const IMAGE_FIXES = [
  { id: "QDDYLs3mtlHU7bcdl7wq", image: "/products/p 3.png" },   // Prayer mat -> real prayer mat photo
  { id: "q8pIYnFAgDogD3uhT5TS", image: "/products/p 4.png" },   // Tasbih -> real tasbih photo
  { id: "GrTprnPDxIf6y0myPw78", image: "/products/PhotoshopExtension_Image_2.png" }, // Musk attar -> cream bottle
  { id: "UaLRZlOJBbnkDCnxqvxU", image: "/products/PhotoshopExtension_Image_4.png" }, // Gift box -> amber bottle
];

const GRADIENT_FIXES = [
  {
    id: "DLWb986PGpXoGp89VUkN", // Bakhoor Burner — no matching photo exists
    bgGradient: "linear-gradient(145deg, #2d1f08 0%, #4a3010 50%, #2d1f08 100%)",
    bgIcon: "local_fire_department",
  },
  {
    id: "TnHk8CdFnhASRAzJ5LCf", // Embroidered Thobe — no matching photo exists
    bgGradient: "linear-gradient(145deg, #1a1a1a 0%, #2d2d2d 50%, #1a1a1a 100%)",
    bgIcon: "person",
  },
  {
    id: "gGzvJed0rmBVLqqxIzOm", // Bakhoor incense chips — no matching photo exists
    bgGradient: "linear-gradient(145deg, #1a1206 0%, #2d1f08 50%, #1a1206 100%)",
    bgIcon: "spa",
  },
];

// New products filling out categories that had zero items, using real photos
// where one genuinely matches, and gradient/icon cards where none exists.
const NEW_PRODUCTS = [
  {
    name: "Premium Kufi Cap Set — 5 Colours", category: "Men", categoryId: "men", type: "other",
    price: 450, originalPrice: 600, image: "/products/p 1.png",
    description: "Set of finely woven kufi prayer caps in five classic colourways — tan, navy, black, grey and cream. One size fits most.",
    tag: "New", isActive: true, isFeatured: false, stockQuantity: 100, sku: "MEN-002",
  },
  {
    name: "Olive Khimar & Abaya Set", category: "Women", categoryId: "women", type: "other",
    price: 2400, originalPrice: 2900, image: "/products/p 2.png",
    description: "Two-layer olive green khimar paired with a flowing matching abaya in premium nida fabric. Modest, elegant, breathable.",
    tag: "Bestseller", isActive: true, isFeatured: true, stockQuantity: 60, sku: "WOM-001",
  },
  {
    name: "Islamic Arch Canvas Wall Art", category: "Home & Decor", categoryId: "home", type: "other",
    price: 1950, originalPrice: 2400, image: "/products/p 5.png",
    description: "Framed canvas print of ornate teal-and-gold Islamic arches. 60x80cm — a statement piece for any home.",
    tag: "New", isActive: true, isFeatured: true, stockQuantity: 40, sku: "HOME-002",
  },
  {
    name: "Kids Prayer Mat Set", category: "Kids", categoryId: "kids", type: "other",
    price: 650, originalPrice: null, image: null,
    bgGradient: "linear-gradient(145deg, #1a0a10 0%, #2d1020 50%, #1a0a10 100%)", bgIcon: "mosque",
    description: "A soft, colourful prayer mat sized for children, designed to help them learn the correct prayer positions from an early age.",
    tag: null, isActive: true, isFeatured: false, stockQuantity: 80, sku: "KID-001",
  },
  {
    name: "Arabic Alphabet Learning Puzzle", category: "Kids", categoryId: "kids", type: "other",
    price: 550, originalPrice: null, image: null,
    bgGradient: "linear-gradient(145deg, #0f1a0f 0%, #1a2d1a 50%, #0f1a0f 100%)", bgIcon: "extension",
    description: "Wooden Arabic alphabet puzzle with bright illustrations, built for little hands aged 2 and up.",
    tag: "Bestseller", isActive: true, isFeatured: false, stockQuantity: 120, sku: "KID-002",
  },
  {
    name: "Tajweed Quran — Large Print", category: "Quran & Books", categoryId: "quran", type: "other",
    price: 980, originalPrice: null, image: null,
    bgGradient: "linear-gradient(145deg, #0d1a08 0%, #172210 50%, #0d1a08 100%)", bgIcon: "menu_book",
    description: "Colour-coded Tajweed Quran in a large, easy-to-read 17x24cm format with Uthmani script.",
    tag: null, isActive: true, isFeatured: true, stockQuantity: 150, sku: "QUR-001",
  },
  {
    name: "Ramadan Planner & Dua Journal", category: "Ramadan & Eid", categoryId: "ramadan", type: "other",
    price: 550, originalPrice: null, image: null,
    bgGradient: "linear-gradient(145deg, #1a0a0a 0%, #2d1515 50%, #1a0a0a 100%)", bgIcon: "edit_calendar",
    description: "30-day Ramadan planner with dua logs, a Quran-reading tracker, and simple meal planning pages.",
    tag: "Bestseller", isActive: true, isFeatured: false, stockQuantity: 200, sku: "RAM-001",
  },
  {
    name: "Ihram Travel Set", category: "Hajj & Umrah", categoryId: "hajj", type: "other",
    price: 2200, originalPrice: 2600, image: null,
    bgGradient: "linear-gradient(145deg, #1a1a1a 0%, #2a2a2a 50%, #1a1a1a 100%)", bgIcon: "flight",
    description: "Complete Ihram travel set — two-piece cotton cloth, belt, sandals and a compact dua booklet for Hajj and Umrah.",
    tag: null, isActive: true, isFeatured: true, stockQuantity: 35, sku: "HAJ-001",
  },
];

function priceCents(price) {
  return Math.round(price * 100);
}

function buildFullDoc(p) {
  const doc = {
    name: p.name,
    category: p.category,
    categoryId: p.categoryId,
    type: p.type,
    description: p.description,
    price: p.price,
    priceInCents: priceCents(p.price),
    isActive: p.isActive,
    isFeatured: !!p.isFeatured,
    stockQuantity: p.stockQuantity,
    sku: p.sku,
  };
  if (p.tag) doc.tag = p.tag;
  if (p.originalPrice) {
    doc.originalPrice = p.originalPrice;
    doc.originalPriceInCents = priceCents(p.originalPrice);
  }
  if (p.image) {
    doc.image = p.image;
    doc.images = [p.image];
  }
  if (p.bgGradient) doc.bgGradient = p.bgGradient;
  if (p.bgIcon) doc.bgIcon = p.bgIcon;
  return doc;
}

async function main() {
  console.log("Loading current products...");
  const before = await listCollection("products");
  console.log(`Found ${before.length} products live.\n`);

  console.log("Deleting test/dummy products...");
  for (const id of TEST_IDS_TO_DELETE) {
    const exists = before.some((d) => d.name.endsWith("/" + id));
    if (!exists) { console.log(`  - skip ${id} (not found)`); continue; }
    await deleteDoc("products", id);
    console.log(`  - deleted ${id}`);
  }

  console.log("\nFixing mismatched product photos...");
  for (const fix of IMAGE_FIXES) {
    await patchDoc("products", fix.id, { image: fix.image, images: [fix.image] });
    console.log(`  - ${fix.id} -> ${fix.image}`);
  }

  console.log("\nSwitching photo-less items to themed gradient cards...");
  for (const fix of GRADIENT_FIXES) {
    await patchDoc("products", fix.id, {
      image: DELETE_FIELD,
      images: DELETE_FIELD,
      bgGradient: fix.bgGradient,
      bgIcon: fix.bgIcon,
    });
    console.log(`  - ${fix.id} -> gradient/${fix.bgIcon}`);
  }

  console.log("\nAdding new products to fill empty categories...");
  for (const p of NEW_PRODUCTS) {
    const doc = buildFullDoc(p);
    const created = await createDoc("products", doc);
    const id = created.name.split("/").pop();
    console.log(`  - [${id}] ${p.name} (${p.category}) - ৳${p.price}`);
  }

  console.log("\nDone. Final catalog:");
  const after = await listCollection("products");
  console.log(`Total products: ${after.length}`);
}

main().catch((e) => { console.error("FAILED:", e.message); process.exit(1); });
