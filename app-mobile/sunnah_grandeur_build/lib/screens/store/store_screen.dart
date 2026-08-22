import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/product_card.dart';
import '../../providers/store_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/language_provider.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'order_history_screen.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c     = AppColors.of(context);
    final lang  = context.watch<LanguageProvider>();
    final store = context.watch<StoreProvider>();
    final cart  = context.watch<CartProvider>();

    final categories = [
      lang.tr('cat_all'),
      lang.tr('cat_books'),
      lang.tr('cat_clothing'),
      lang.tr('cat_prayer'),
      lang.tr('cat_home'),
      lang.tr('cat_jewellery'),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lang.tr('store'), style: AppTextStyles.brand(c)),
                Text(lang.tr('islamic_lifestyle'), style: AppTextStyles.brandTag(c)),
              ]),
              Row(children: [
                _IconBtn(icon: Icons.search_rounded, c: c),
                const SizedBox(width: 7),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                  child: _IconBtn(icon: Icons.receipt_long_outlined, c: c),
                ),
                const SizedBox(width: 7),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: Stack(children: [
                    _IconBtn(icon: Icons.shopping_cart_outlined, c: c),
                    if (cart.itemCount > 0)
                      Positioned(
                        top: 5, right: 6,
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: c.red, shape: BoxShape.circle,
                            border: Border.all(color: c.bg, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text('${cart.itemCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ]),
                ),
              ]),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                // Hero banner
                _HeroBanner(c: c, lang: lang),

                // Category chips
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final isSelected = store.selectedCategory == _rawCategories[i];
                      return GestureDetector(
                        onTap: () => store.setCategory(_rawCategories[i]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? c.gold
                                : (c.isDark ? c.surf : Colors.white),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: isSelected ? c.gold3 : c.bd2),
                          ),
                          child: Text(cat,
                              style: AppTextStyles.pill(c, size: 10,
                                  color: isSelected ? Colors.white : c.t3)),
                        ),
                      );
                    },
                  ),
                ),

                EyeRow(label: lang.tr('featured_products')),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: store.isLoading
                    ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: store.products.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final p = store.products[index];
                          return ProductCard(
                            name: p.name,
                            price: p.priceDisplay,
                            imagePath: p.primaryImage.isNotEmpty ? p.primaryImage : null,
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: p))),
                          );
                        },
                      ),
                ),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// Raw category keys for StoreProvider (unchanged API)
const _rawCategories = ['All', 'Books', 'Clothing', 'Prayer', 'Home', 'Jewellery'];

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.c, required this.lang});
  final AppColors c;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3D2A08), Color(0xFF6B4C18), Color(0xFF8B6824)],
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: 24, top: 0, bottom: 0,
          child: Center(child: Icon(Icons.inventory_2_outlined,
              color: Colors.white.withOpacity(0.08), size: 90)),
        ),
        Positioned(
          left: 18, top: 0, bottom: 0,
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lang.tr('ramadan_exclusive'),
              style: AppTextStyles.cinzelSm(c,
                  color: const Color(0xFFE2C07A), size: 8)
                  .copyWith(letterSpacing: 0.24 * 8)),
            const SizedBox(height: 4),
            Text(lang.tr('free_shipping'),
              style: AppTextStyles.heading(c, color: Colors.white, fontSize: 18)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFC8A55A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(lang.tr('shop_now'),
                style: AppTextStyles.button(c, color: Colors.white)
                    .copyWith(fontSize: 11)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.c});
  final IconData icon;
  final AppColors c;
  @override
  Widget build(BuildContext context) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.bd2)),
    child: Icon(icon, color: c.gold, size: 18),
  );
}
