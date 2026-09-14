import ProductClient from './ProductClient';
import { products } from '@/data/products';
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, query, where } from 'firebase/firestore';

// This is a statically exported site (see firebase.json — `app-web/out` is
// deployed as-is, with no server to render a page on demand). That means
// every real product ID has to be known at BUILD time, or its page 404s
// even though the product exists in Firestore. Fetch the live catalog here
// so a rebuild+deploy after any admin catalog change makes new products
// reachable at /product/[id]. The static mock IDs are kept as a fallback
// so a Firestore hiccup during build doesn't wipe out every product page.
export async function generateStaticParams() {
  const staticIds = products.map((product) => String(product.id));

  try {
    const app = initializeApp({
      projectId: 'sunnah-grandeur',
      apiKey: 'AIzaSyDX3H10keVelz9HppzN_Y0BKqhPWRCqV8U',
      authDomain: 'sunnah-grandeur.firebaseapp.com',
    }, 'build-time-product-params');
    const db = getFirestore(app);
    // Firestore rejects a bare collection scan against a per-document rule
    // (allow read: if resource.data.isActive == true || isAdmin()) — the
    // query has to carry the same filter the rule can verify statically.
    const snapshot = await getDocs(query(collection(db, 'products'), where('isActive', '==', true)));
    const liveIds = snapshot.docs.map((doc) => doc.id);
    const allIds = Array.from(new Set([...staticIds, ...liveIds]));
    return allIds.map((id) => ({ id }));
  } catch (err) {
    console.error('generateStaticParams: could not fetch live products from Firestore, falling back to static mock IDs only.', err);
    return staticIds.map((id) => ({ id }));
  }
}

export default function ProductPage() {
  return <ProductClient />;
}
