const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json"); // Provide fallback for local run

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

const products = [
  {
    title: "Oud Al Amir",
    description: "Premium high-concentration oud with floral and woody notes.",
    price: 45.0,
    category: "Perfumes",
    imagePath: "https://images.unsplash.com/photo-1541643600914-78b084683601?q=80&w=800",
    rating: 4.8,
    reviews: 124,
    sku: "PF-OUD-001",
    variations: ["30ml", "50ml", "100ml"],
    stock: 50
  },
  {
    title: "Premium Prayer Mat",
    description: "Extra thick orthopedic prayer mat for maximum comfort.",
    price: 35.0,
    category: "Lifestyle",
    imagePath: "https://images.unsplash.com/photo-1596700732599-566b6c07172f?q=80&w=800",
    rating: 4.9,
    reviews: 82,
    sku: "LS-MAT-002",
    variations: ["Navy", "Emerald", "Black"],
    stock: 120
  },
  {
    title: "Ajwa Dates 1kg",
    description: "Authentic Ajwa dates from Madinah Al-Munawwarah.",
    price: 40.0,
    category: "Health & Food",
    imagePath: "https://images.unsplash.com/photo-1523293836414-f04e712e10bc?q=80&w=800",
    rating: 5.0,
    reviews: 215,
    sku: "HF-AJW-003",
    variations: ["Regular", "Jumbo"],
    stock: 200
  }
];

const masjids = [
  {
    name: "Masjid Al-Noor",
    address: "123 Madison Ave, New York",
    latitude: 40.7128,
    longitude: -74.0060,
    details: "Jumu'ah: 1:15 PM · Asr: 3:50 PM · 500 capacity",
    isOpen: true
  },
  {
    name: "Islamic Cultural Center",
    address: "1711 3rd Ave, New York",
    latitude: 40.7831,
    longitude: -73.9472,
    details: "Jumu'ah: 1:30 PM · Large prayer hall",
    isOpen: true
  }
];

const media = [
  {
    title: "Surah Al-Baqarah — Sheikh Mishary",
    description: "Full recitation of Surah Al-Baqarah for protection and peace.",
    author: "Mishary Al-Afasy",
    duration: "2:32:14",
    views: "1.2M",
    category: "Tilawah",
    type: "quran",
    thumbnail: "https://i.ytimg.com/vi/Vv_Rlp5vM7Y/maxresdefault.jpg",
    youtubeId: "Vv_Rlp5vM7Y",
    publishedAt: new Date().toISOString()
  },
  {
    title: "Ruqyah for Evil Eye & Protection",
    description: "Authentic Ruqyah according to the Sunnah.",
    author: "Sheikh Sudais",
    duration: "42:10",
    views: "850K",
    category: "Protection",
    type: "ruqyah",
    thumbnail: "https://i.ytimg.com/vi/2XnLp_1L6tQ/maxresdefault.jpg",
    youtubeId: "2XnLp_1L6tQ",
    publishedAt: new Date().toISOString()
  }
];

const hadiths = [
  {
    title: "On Kindness",
    content: "Kindness is a mark of faith, and whoever is not kind has no faith.",
    source: "Sahih Muslim",
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    title: "On Patience",
    content: "The real patience is at the first stroke of a calamity.",
    source: "Sahih Bukhari",
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  }
];

const youtubeSources = [
  { id: "PL8rD2QjW7YfB6L7P-T7X", type: "video", category: "Lectures" },
  { id: "PLm0X6_K8D1nK7L7P-X8Y", type: "quran", category: "Tilawah" }
];

async function seed() {
  console.log("Starting Firestore Seeding...");

  // Seed Products
  for (const p of products) {
    await db.collection("products").add(p);
    console.log(`Added product: ${p.title}`);
  }

  // Seed Media
  for (const m of media) {
    await db.collection("media").add(m);
    console.log(`Added media: ${m.title}`);
  }

  // Seed Hadiths
  for (const h of hadiths) {
    await db.collection("hadith_posts").add(h);
    console.log(`Added hadith: ${h.title}`);
  }

  // Seed Masjids
  for (const m of masjids) {
    await db.collection("masjids").add(m);
    console.log(`Added masjid: ${m.name}`);
  }

  // Seed YouTube Sync Config
  await db.collection("config").doc("youtube_sources").set({
    sources: youtubeSources
  });
  console.log("Added YouTube Sync configuration.");

  console.log("Seeding complete!");
}

seed().catch(console.error);
