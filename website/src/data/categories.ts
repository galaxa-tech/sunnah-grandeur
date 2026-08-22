export interface Subcategory {
  name: string;
  href: string;
}

export interface Category {
  id: string;
  name: string;
  icon: string;
  gradient: string;
  accentColor: string;
  subcategories: Subcategory[];
  featuredImage?: string;
}

export const categories: Category[] = [
  {
    id: 'men',
    name: 'Men',
    icon: 'person',
    gradient: 'linear-gradient(135deg, #1a1206 0%, #2d1f08 50%, #1a1206 100%)',
    accentColor: '#C9A84C',
    subcategories: [
      { name: 'Thobes / Jubba', href: '/shop?cat=men' },
      { name: 'Panjabi / Kurtas', href: '/shop?cat=men' },
      { name: 'Tupi / Kufi / Caps', href: '/shop?cat=men' },
      { name: 'Sunnah Grooming', href: '/shop?cat=men' },
    ],
  },
  {
    id: 'women',
    name: 'Women',
    icon: 'woman',
    gradient: 'linear-gradient(135deg, #0f1a0f 0%, #1a2d1a 50%, #0f1a0f 100%)',
    accentColor: '#8BC38B',
    subcategories: [
      { name: 'Hijabs', href: '/shop?cat=women' },
      { name: 'Abayas', href: '/shop?cat=women' },
      { name: 'Khimars & Niqabs', href: '/shop?cat=women' },
      { name: 'Modest Fashion', href: '/shop?cat=women' },
    ],
  },
  {
    id: 'kids',
    name: 'Kids',
    icon: 'child_care',
    gradient: 'linear-gradient(135deg, #0a1520 0%, #102035 50%, #0a1520 100%)',
    accentColor: '#6BB5D4',
    subcategories: [
      { name: 'Kids Islamic Wear', href: '/shop?cat=kids' },
      { name: 'Kids Prayer Essentials', href: '/shop?cat=kids' },
      { name: 'Islamic Toys', href: '/shop?cat=kids' },
      { name: 'Learning & Quran Kits', href: '/shop?cat=kids' },
    ],
  },
  {
    id: 'salah',
    name: 'Salah & Worship',
    icon: 'mosque',
    gradient: 'linear-gradient(135deg, #1a0f1a 0%, #2d1a2d 50%, #1a0f1a 100%)',
    accentColor: '#C9A84C',
    subcategories: [
      { name: 'Prayer Mats', href: '/shop?cat=salah' },
      { name: 'Tasbih', href: '/shop?cat=salah' },
      { name: 'Quran Accessories', href: '/shop?cat=salah' },
      { name: 'Adhan & Smart Devices', href: '/shop?cat=salah' },
    ],
  },
  {
    id: 'quran',
    name: 'Quran & Books',
    icon: 'menu_book',
    gradient: 'linear-gradient(135deg, #0d150a 0%, #172210 50%, #0d150a 100%)',
    accentColor: '#8BC38B',
    subcategories: [
      { name: 'Quran Collections', href: '/shop?cat=quran' },
      { name: 'Tafsir & Hadith', href: '/shop?cat=quran' },
      { name: 'Islamic Books', href: '/shop?cat=quran' },
      { name: 'Kids Islamic Books', href: '/shop?cat=quran' },
    ],
  },
  {
    id: 'fragrance',
    name: 'Fragrance',
    icon: 'water_drop',
    gradient: 'linear-gradient(135deg, #1a1206 0%, #2d1f08 50%, #1a1206 100%)',
    accentColor: '#C9A84C',
    featuredImage: '/products/PhotoshopExtension_Image_3.png',
    subcategories: [
      { name: 'Attar & Oud', href: '/shop?cat=fragrance' },
      { name: 'Bakhoor', href: '/shop?cat=fragrance' },
      { name: 'Beard Care', href: '/shop?cat=fragrance' },
      { name: 'Halal Skincare', href: '/shop?cat=fragrance' },
    ],
  },
  {
    id: 'home',
    name: 'Home & Decor',
    icon: 'home',
    gradient: 'linear-gradient(135deg, #0a0f1a 0%, #101825 50%, #0a0f1a 100%)',
    accentColor: '#6BB5D4',
    subcategories: [
      { name: 'Islamic Wall Art', href: '/shop?cat=home' },
      { name: 'Lighting & Lamps', href: '/shop?cat=home' },
      { name: 'Islamic Clocks', href: '/shop?cat=home' },
      { name: 'Decorative Accessories', href: '/shop?cat=home' },
    ],
  },
  {
    id: 'ramadan',
    name: 'Ramadan & Eid',
    icon: 'crescent_moon',
    gradient: 'linear-gradient(135deg, #1a0a0a 0%, #2d1010 50%, #1a0a0a 100%)',
    accentColor: '#E87D7D',
    subcategories: [
      { name: 'Ramadan Decor', href: '/shop?cat=ramadan' },
      { name: 'Eid Fashion', href: '/shop?cat=ramadan' },
      { name: 'Gift Boxes', href: '/shop?cat=ramadan' },
      { name: 'Iftar & Suhoor Essentials', href: '/shop?cat=ramadan' },
    ],
  },
  {
    id: 'hajj',
    name: 'Hajj & Umrah',
    icon: 'flight',
    gradient: 'linear-gradient(135deg, #0a1a12 0%, #102a1e 50%, #0a1a12 100%)',
    accentColor: '#7DD4A8',
    subcategories: [
      { name: 'Ihram Essentials', href: '/shop?cat=hajj' },
      { name: 'Travel Accessories', href: '/shop?cat=hajj' },
      { name: 'Dua & Guide Books', href: '/shop?cat=hajj' },
      { name: 'Hygiene Essentials', href: '/shop?cat=hajj' },
    ],
  },
  {
    id: 'gifts',
    name: 'Gifts',
    icon: 'card_giftcard',
    gradient: 'linear-gradient(135deg, #1a0f15 0%, #2d1a25 50%, #1a0f15 100%)',
    accentColor: '#D4A0C4',
    subcategories: [
      { name: 'Gifts for Him', href: '/shop?cat=gifts' },
      { name: 'Gifts for Her', href: '/shop?cat=gifts' },
      { name: 'Personalized Gifts', href: '/shop?cat=gifts' },
      { name: 'Islamic Gift Sets', href: '/shop?cat=gifts' },
    ],
  },
  {
    id: 'new',
    name: 'New Arrivals',
    icon: 'new_releases',
    gradient: 'linear-gradient(135deg, #0f1a0a 0%, #182d10 50%, #0f1a0a 100%)',
    accentColor: '#C9A84C',
    subcategories: [
      { name: 'Latest Fashion', href: '/shop?cat=new' },
      { name: 'New Fragrances', href: '/shop?cat=new' },
      { name: 'New Decor', href: '/shop?cat=new' },
      { name: 'Trending Products', href: '/shop?cat=new' },
    ],
  },
  {
    id: 'bestsellers',
    name: 'Best Sellers',
    icon: 'trending_up',
    gradient: 'linear-gradient(135deg, #1a1206 0%, #2d2008 50%, #1a1206 100%)',
    accentColor: '#C9A84C',
    subcategories: [
      { name: 'Best Selling Perfumes', href: '/shop?cat=bestsellers' },
      { name: 'Popular Prayer Mats', href: '/shop?cat=bestsellers' },
      { name: 'Top Islamic Wear', href: '/shop?cat=bestsellers' },
      { name: 'Customer Favorites', href: '/shop?cat=bestsellers' },
    ],
  },
];
