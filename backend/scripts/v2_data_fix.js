/**
 * Daily Muslim 2.0 — one-off, idempotent Firestore data fix.
 *
 *   node backend/scripts/v2_data_fix.js           # dry run (prints changes)
 *   node backend/scripts/v2_data_fix.js --apply   # writes
 *
 * 1. media: items saved under the retired "quran" section (lecture videos,
 *    e.g. Nouman Ali Khan tafsir) move to "video" (Islamic Videos). The
 *    app's Quran section is now text + audio.
 * 2. categories: admin-created docs lacked isActive / sortOrder / icon /
 *    accentColor / featuredImage, so the app filtered them all out and fell
 *    back to hard-coded placeholders. Backfill them to mirror the storefront
 *    (app-web/src/data/categories.ts). featuredImage falls back to the first
 *    product image in that category when the storefront has none.
 *
 * Uses Application Default Credentials (gcloud auth application-default login).
 */
const admin = require('../functions/node_modules/firebase-admin');

admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: 'sunnah-grandeur' });
const db = admin.firestore();
const APPLY = process.argv.includes('--apply');

// Mirrors app-web/src/data/categories.ts (order = storefront order).
const CATEGORY_META = [
  { id: 'men',       icon: 'person',        accentColor: '#C9A84C', featuredImage: '/products/p 1.png' },
  { id: 'women',     icon: 'woman',         accentColor: '#8BC38B', featuredImage: '/products/p2.png' },
  { id: 'kids',      icon: 'child_care',    accentColor: '#6BB5D4' },
  { id: 'salah',     icon: 'mosque',        accentColor: '#C9A84C', featuredImage: '/products/p 3.png' },
  { id: 'quran',     icon: 'menu_book',     accentColor: '#8BC38B' },
  { id: 'fragrance', icon: 'water_drop',    accentColor: '#C9A84C', featuredImage: '/products/PhotoshopExtension_Image_3.png' },
  { id: 'home',      icon: 'home',          accentColor: '#6BB5D4', featuredImage: '/products/p 5.png' },
  { id: 'ramadan',   icon: 'bedtime',       accentColor: '#E87D7D' },
  { id: 'hajj',      icon: 'flight',        accentColor: '#7DD4A8' },
  { id: 'gifts',     icon: 'card_giftcard', accentColor: '#D4A0C4' },
];

async function fixMedia() {
  const snap = await db.collection('media').where('type', '==', 'quran').get();
  for (const d of snap.docs) {
    console.log(`media ${d.id}: quran -> video  (${d.get('title')})`);
    if (APPLY) await d.ref.update({ type: 'video', updatedAt: admin.firestore.FieldValue.serverTimestamp() });
  }
  // Seed docs written without isActive never appear in the app.
  const all = await db.collection('media').get();
  for (const d of all.docs) {
    if (d.get('isActive') === undefined) {
      console.log(`media ${d.id}: isActive -> true`);
      if (APPLY) await d.ref.update({ isActive: true });
    }
  }
}

async function fixCategories() {
  const products = await db.collection('products').where('isActive', '==', true).get();
  const firstImageByCat = {};
  products.forEach((p) => {
    const cat = p.get('categoryId');
    const img = p.get('image') || (p.get('images') || [])[0];
    if (cat && img && !firstImageByCat[cat]) firstImageByCat[cat] = img;
  });

  for (const [i, meta] of CATEGORY_META.entries()) {
    const ref = db.collection('categories').doc(meta.id);
    const doc = await ref.get();
    if (!doc.exists) {
      console.log(`category ${meta.id}: missing, skipped`);
      continue;
    }
    const patch = {};
    if (doc.get('isActive') === undefined) patch.isActive = true;
    if (doc.get('sortOrder') === undefined) patch.sortOrder = i;
    if (!doc.get('icon')) patch.icon = meta.icon;
    if (!doc.get('accentColor')) patch.accentColor = meta.accentColor;
    const image = meta.featuredImage || firstImageByCat[meta.id];
    if (!doc.get('featuredImage') && image) patch.featuredImage = image;
    if (Object.keys(patch).length) {
      console.log(`category ${meta.id}:`, JSON.stringify(patch));
      if (APPLY) await ref.set(patch, { merge: true });
    }
  }
}

(async () => {
  console.log(APPLY ? '== APPLYING ==' : '== DRY RUN (pass --apply to write) ==');
  await fixMedia();
  await fixCategories();
  console.log('done');
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
