import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/store/store_design.dart';
import '../../widgets/store/store_product_card.dart';
import '../../widgets/store/store_sections.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'product_detail_screen.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: sgStoreBg,
      drawer: _CategoryDrawer(store: store),
      body: SafeArea(
        child: Builder(
          builder: (scaffoldContext) => Column(
            children: [
              _StoreNav(cartCount: cart.itemCount),
              Expanded(
                child: RefreshIndicator(
                  color: sgStoreGold,
                  backgroundColor: sgStoreSurface,
                  onRefresh: () async {},
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: StoreHeaderSection(
                          title: store.selectedCategoryName,
                          count: store.products.length,
                          sort: store.sort,
                          searchQuery: store.searchQuery,
                          onSearchChanged: store.setSearch,
                          onSortChanged: store.setSort,
                          onOpenCategories: () => Scaffold.of(scaffoldContext).openDrawer(),
                        ),
                      ),
                      SliverToBoxAdapter(child: StorePromoBanner(banner: store.banners.isEmpty ? null : store.banners.first)),
                      SliverToBoxAdapter(
                        child: CategoryRail(
                          categories: store.categories,
                          selectedId: store.selectedCategoryId,
                          countForCategory: store.countForCategory,
                          onSelected: store.setCategory,
                        ),
                      ),
                      if (store.featuredProducts.isNotEmpty && store.selectedCategoryId == null && store.searchQuery.isEmpty)
                        SliverToBoxAdapter(child: _FeaturedStrip(products: store.featuredProducts)),
                      if (store.isLoading)
                        const SliverPadding(
                          padding: EdgeInsets.all(18),
                          sliver: _ProductSkeletonGrid(),
                        )
                      else if (store.products.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyStore(onViewAll: () => store.setCategory(null)),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = store.products[index];
                                return StoreProductCard(
                                  product: product,
                                  isFavorite: store.isFavorite(product.id),
                                  onTap: () => _openProduct(context, product),
                                  onAddToCart: () => _addToCart(context, product),
                                  onToggleFavorite: () => store.toggleFavorite(product),
                                );
                              },
                              childCount: store.products.length,
                            ),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _openProduct(BuildContext context, ProductModel product) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
  }

  static void _addToCart(BuildContext context, ProductModel product) {
    if (product.stockQuantity <= 0) return;
    context.read<CartProvider>().addToCart(product, 'Standard', 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart', style: sgBody(color: sgStoreText, size: 12)),
        backgroundColor: sgStoreSurface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: sgStoreBorder),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _StoreNav extends StatelessWidget {
  const _StoreNav({required this.cartCount});
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: sgStoreBg,
        border: Border(bottom: BorderSide(color: sgStoreBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Sunnah Grandeur',
              style: sgBody(color: sgStoreGold, size: 16, weight: FontWeight.w900).copyWith(letterSpacing: 1),
            ),
          ),
          StoreIconButton(
            icon: Icons.receipt_long_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
          ),
          const SizedBox(width: 10),
          StoreIconButton(
            icon: Icons.shopping_bag_outlined,
            badge: cartCount,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ],
      ),
    );
  }
}

class _CategoryDrawer extends StatelessWidget {
  const _CategoryDrawer({required this.store});
  final StoreProvider store;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: sgStoreBg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Text('CATEGORIES', style: sgBody(color: sgStoreText, size: 14, weight: FontWeight.w900).copyWith(letterSpacing: 1))),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: sgStoreMuted),
                  ),
                ],
              ),
            ),
            const Divider(color: sgStoreBorder, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DrawerItem(
                    title: 'All Products',
                    icon: Icons.storefront_outlined,
                    active: store.selectedCategoryId == null,
                    count: store.countForCategory(null),
                    color: sgStoreGold,
                    onTap: () {
                      store.setCategory(null);
                      Navigator.pop(context);
                    },
                  ),
                  ...store.categories.map((cat) => _DrawerItem(
                        title: cat.name,
                        icon: storeIcon(cat.iconKey),
                        active: store.selectedCategoryId == cat.id,
                        count: store.countForCategory(cat.id),
                        color: cat.accentColor,
                        onTap: () {
                          store.setCategory(cat.id);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.active,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool active;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active ? sgStoreGold.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? sgStoreGold : color.withValues(alpha: 0.65), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: sgBody(color: active ? sgStoreGold : sgStoreMuted, size: 13, weight: FontWeight.w900)),
            ),
            Text('$count', style: sgBody(size: 12)),
          ],
        ),
      ),
    );
  }
}

class _FeaturedStrip extends StatelessWidget {
  const _FeaturedStrip({required this.products});
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          child: Text('FEATURED PRODUCTS', style: sgLabel(color: sgStoreMuted, size: 10)),
        ),
        SizedBox(
          height: 92,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sgStoreSurface,
                    border: Border.all(color: sgStoreBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 62,
                        height: 76,
                        decoration: BoxDecoration(
                          color: sgStoreBg,
                          borderRadius: BorderRadius.circular(4),
                          image: p.primaryImage.isEmpty
                              ? null
                              : DecorationImage(image: NetworkImage(p.primaryImage), fit: BoxFit.cover),
                        ),
                        child: p.primaryImage.isEmpty ? Icon(storeIcon(p.categoryId), color: sgStoreGold.withValues(alpha: 0.4)) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.category.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: sgLabel(size: 8)),
                            const SizedBox(height: 4),
                            Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: sgBody(color: sgStoreText, size: 12, weight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(p.priceDisplay, style: sgBody(color: sgStoreGold, size: 13, weight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyStore extends StatelessWidget {
  const _EmptyStore({required this.onViewAll});
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, color: sgStoreBorder, size: 62),
            const SizedBox(height: 16),
            Text('No products in this category yet.', style: sgBody(size: 14)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onViewAll,
              child: Text('View all products', style: sgBody(color: sgStoreGold, size: 13, weight: FontWeight.w900).copyWith(decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSkeletonGrid extends StatelessWidget {
  const _ProductSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (_, __) => Container(
          decoration: BoxDecoration(
            color: sgStoreSurface,
            border: Border.all(color: sgStoreBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Expanded(child: Container(color: Colors.white.withValues(alpha: 0.03))),
              Container(height: 96, padding: const EdgeInsets.all(10), child: Column(children: [
                Container(height: 8, color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 8),
                Container(height: 10, color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: 8),
                Container(height: 8, color: Colors.white.withValues(alpha: 0.05)),
              ])),
            ],
          ),
        ),
        childCount: 6,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.54,
      ),
    );
  }
}
