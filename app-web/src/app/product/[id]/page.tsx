import ProductClient from './ProductClient';
import { products } from '@/data/products';

export async function generateStaticParams() {
  return products.map((product) => ({
    id: String(product.id),
  }));
}

export default function ProductPage() {
  return <ProductClient />;
}
