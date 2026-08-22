// Local shop product model (dummy data from HTML design)
class ShopProduct {
  const ShopProduct({
    required this.name,
    required this.price,
    required this.stars,
    required this.reviews,
    this.imageUrl,
    this.category = 'Perfumes',
  });
  final String name;
  final String price;
  final int stars;
  final int reviews;
  final String? imageUrl;
  final String category;
}

const List<ShopProduct> kShopProducts = [
  ShopProduct(name: 'Oud Al-Firdaws',      price: '\$285.00', stars: 5, reviews: 48,  category: 'Perfumes'),
  ShopProduct(name: 'Desert Rose Noir',    price: '\$195.00', stars: 4, reviews: 32,  category: 'Perfumes'),
  ShopProduct(name: 'Amber Musk Royale',   price: '\$310.00', stars: 5, reviews: 112, category: 'Perfumes'),
  ShopProduct(name: "Sultan's Blend",      price: '\$420.00', stars: 5, reviews: 21,  category: 'Perfumes'),
  ShopProduct(name: 'Medina Moonlight',    price: '\$165.00', stars: 4, reviews: 89,  category: 'Perfumes'),
  ShopProduct(name: 'Dark Oud Reserve',    price: '\$550.00', stars: 5, reviews: 12,  category: 'Fragrance Oils'),
  ShopProduct(name: 'Thara Al-Oud',        price: '\$340.00', stars: 5, reviews: 67,  category: 'Fragrance Oils'),
  ShopProduct(name: 'Saffron Royale',      price: '\$220.00', stars: 4, reviews: 44,  category: 'Perfumes'),
  ShopProduct(name: 'Pearl Tasbih Set',    price: '\$95.00',  stars: 5, reviews: 203, category: 'Prayer Beads'),
  ShopProduct(name: 'Obsidian Prayer Mat', price: '\$185.00', stars: 5, reviews: 76,  category: 'Prayer Mats'),
  ShopProduct(name: 'The Ihram Robe',      price: '\$275.00', stars: 4, reviews: 38,  category: 'Modest Wear'),
  ShopProduct(name: 'Gold Dusted Attar',   price: '\$450.00', stars: 5, reviews: 19,  category: 'Fragrance Oils'),
];
