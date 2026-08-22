import {
  collection,
  doc,
  getDocs,
  getDoc,
  QueryDocumentSnapshot,
  DocumentData,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import type { Product } from '@/data/products';

const COLLECTION = 'products';

function toProduct(snap: QueryDocumentSnapshot<DocumentData>): Product {
  const data = snap.data();
  return {
    id:            snap.id,
    name:          data.name          ?? '',
    category:      data.category      ?? '',
    categoryId:    data.categoryId    ?? '',
    price:         data.price         ?? 0,
    description:   data.description   ?? '',
    type:          data.type          ?? 'other',
    originalPrice: data.originalPrice,
    image:         data.image,
    bgGradient:    data.bgGradient,
    bgIcon:        data.bgIcon,
    tag:           data.tag,
    isSoldOut:     data.isSoldOut,
    sizes:         data.sizes,
  };
}

export async function getProducts(): Promise<Product[]> {
  const snap = await getDocs(collection(db, COLLECTION));
  return snap.docs.map(toProduct);
}

export async function getProductById(id: string): Promise<Product | null> {
  const snap = await getDoc(doc(db, COLLECTION, id));
  if (!snap.exists()) return null;

  const data = snap.data();
  return {
    id:            snap.id,
    name:          data.name          ?? '',
    category:      data.category      ?? '',
    categoryId:    data.categoryId    ?? '',
    price:         data.price         ?? 0,
    description:   data.description   ?? '',
    type:          data.type          ?? 'other',
    originalPrice: data.originalPrice,
    image:         data.image,
    bgGradient:    data.bgGradient,
    bgIcon:        data.bgIcon,
    tag:           data.tag,
    isSoldOut:     data.isSoldOut,
    sizes:         data.sizes,
  };
}
