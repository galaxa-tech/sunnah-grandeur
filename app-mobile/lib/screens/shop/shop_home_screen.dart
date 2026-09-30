import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/product_model.dart';
import '../../models/store_category_model.dart';
import '../../widgets/net_image.dart';
import '../../widgets/shop/product_card.dart';
import '../../widgets/shop/banner_carousel.dart';
import '../../widgets/shop/cart_feedback.dart';
import '../../theme/app_colors.dart';
import 'shop_product_detail_screen.dart';
import 'shop_cart_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ShopHomeScreen — the Sunnah Grandeur store inside Daily Muslim.
//
// Mirrors sunnahgrandeur.com: branded header, hero/banners, image category
// tiles, a New Arrivals rail and the full catalogue grid. Picking a category
// (or searching) switches to a filtered grid with category chips.
// ─────────────────────────────────────────────────────────────────────────────
class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  bool _searchOpen = false;
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _openDetail(ProductModel p) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ShopProductDetailScreen(product: p)));

  void _openCart() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const ShopCartScreen()));

  void _selectCategory(StoreProvider store, String? id) {
    store.setCategory(id);
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  void _toggleSearch(StoreProvider store) {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      _searchCtrl.clear();
      store.setSearch('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c     = AppColors.of(context);
    final store = context.watch<StoreProvider>();
    final cart  = context.watch<CartProvider>();
    final lang  = context.watch<LanguageProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final hPad  = width > 900 ? 32.0 : 16.0;
    final cols  = width < 600 ? 2 : width < 1000 ? 3 : 4;
    final browsing =
        store.selectedCategoryId == null && store.searchQuery.trim().isEmpty;

    return PopScope(
      // Back from a category/search returns to the store home first.
      canPop: browsing && !_searchOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_searchOpen) {
          _toggleSearch(store);
        } else {
          _selectCategory(store, null);
        }
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(children: [
            _StoreHeader(
              cartCount: cart.itemCount,
              searchOpen: _searchOpen,
              searchCtrl: _searchCtrl,
              onSearchToggle: () => _toggleSearch(store),
              onSearchChanged: store.setSearch,
              onCart: _openCart,
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.gold,
                onRefresh: () async =>
                    Future<void>.delayed(const Duration(milliseconds: 600)),
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Category chips — always available for quick switching.
                    SliverToBoxAdapter(
                      child: _CategoryChips(
                        store: store,
                        allLabel: lang.tr('all'),
                        onSelect: (id) => _selectCategory(store, id),
                      ),
                    ),

                    if (store.isLoading)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(color: c.gold, strokeWidth: 2),
                        ),
                      )
                    else if (store.error != null && store.allProducts.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _Empty(
                          icon: Icons.wifi_off_rounded,
                          text: lang.tr('store_load_failed'),
                        ),
                      )
                    else ...[
                      if (browsing) ..._homeSlivers(c, lang, store, hPad),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 12),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    browsing
                                        ? lang.tr('all_products')
                                        : store.searchQuery.trim().isNotEmpty
                                            ? '“${store.searchQuery.trim()}”'
                                            : store.selectedCategoryName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.notoSerif(
                                        fontSize: 20, fontWeight: FontWeight.w700, color: c.t1),
                                  ),
                                  Text(
                                    '${store.products.length} ${lang.tr('products_lower')}',
                                    style: GoogleFonts.manrope(fontSize: 12, color: c.t2),
                                  ),
                                ],
                              ),
                            ),
                            _SortButton(store: store, lang: lang),
                          ]),
                        ),
                      ),
                      if (store.products.isEmpty)
                        SliverToBoxAdapter(
                          child: _Empty(
                            icon: Icons.inventory_2_outlined,
                            text: lang.tr('no_products_category'),
                            actionLabel: lang.tr('view_all_products'),
                            onAction: () {
                              _searchCtrl.clear();
                              store.setSearch('');
                              _selectCategory(store, null);
                            },
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 32),
                          sliver: SliverLayoutBuilder(builder: (context, cons) {
                            const gap = 12.0;
                            final tileW = (cons.crossAxisExtent - gap * (cols - 1)) / cols;
                            return SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisSpacing: gap,
                                crossAxisSpacing: gap,
                                mainAxisExtent: tileW + 104,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (_, i) {
                                  final p = store.products[i];
                                  return ProductCard(
                                    product: p,
                                    onTap: () => _openDetail(p),
                                    onAddToCart: () => addToCartWithFeedback(context, p),
                                  );
                                },
                                childCount: store.products.length,
                              ),
                            );
                          }),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _homeSlivers(
      AppColors c, LanguageProvider lang, StoreProvider store, double hPad) {
    final newest = [...store.allProducts]..sort((a, b) => b.id.compareTo(a.id));
    final featured = store.allProducts.where((p) => p.isFeatured).toList();
    final rail = (featured.isNotEmpty ? featured : newest).take(10).toList();
    final visibleCats = store.categories
        .where((cat) => store.countForCategory(cat.id) > 0)
        .toList();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 0),
          child: store.banners.isNotEmpty
              ? BannerCarousel(
                  banners: store.banners,
                  onTap: (_) => _selectCategory(store, null),
                )
              : _HeroCard(lang: lang),
        ),
      ),
      SliverToBoxAdapter(
        child: _SectionTitle(title: lang.tr('shop_by_category'), hPad: hPad),
      ),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 104,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final cat = visibleCats[i];
              return _CategoryTile(
                category: cat,
                count: store.countForCategory(cat.id),
                fallbackImage: store.allProducts
                    .where((p) => p.categoryId == cat.id && p.primaryImage.isNotEmpty)
                    .map((p) => p.primaryImage)
                    .firstOrNull,
                onTap: () => _selectCategory(store, cat.id),
              );
            },
            childCount: visibleCats.length,
          ),
        ),
      ),
      if (rail.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionTitle(
            title: lang.tr(featured.isNotEmpty ? 'featured' : 'new_arrivals'),
            hPad: hPad,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160 + 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPad),
              itemCount: rail.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => ProductCard(
                width: 160,
                product: rail[i],
                onTap: () => _openDetail(rail[i]),
                onAddToCart: () => addToCartWithFeedback(context, rail[i]),
              ),
            ),
          ),
        ),
      ],
      SliverToBoxAdapter(child: _TrustStrip(lang: lang, hPad: hPad)),
    ];
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({
    required this.cartCount,
    required this.searchOpen,
    required this.searchCtrl,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onCart,
  });

  final int cartCount;
  final bool searchOpen;
  final TextEditingController searchCtrl;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.bd)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: searchOpen
            ? Row(key: const ValueKey('search'), children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: onSearchChanged,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.manrope(fontSize: 15, color: c.t1),
                    decoration: InputDecoration(
                      hintText: lang.tr('search_products'),
                      hintStyle: GoogleFonts.manrope(fontSize: 14, color: c.t3),
                      prefixIcon: Icon(Icons.search_rounded, color: c.gold, size: 20),
                      filled: true,
                      fillColor: c.surf,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onSearchToggle,
                  icon: Icon(Icons.close_rounded, color: c.t2),
                ),
              ])
            : Row(key: const ValueKey('title'), children: [
                Image.asset('assets/images/logo.png', width: 38, height: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sunnah Grandeur',
                          style: GoogleFonts.cormorantGaramond(
                              fontSize: 21, fontWeight: FontWeight.w700,
                              color: c.gold2, height: 1.05)),
                      Text(lang.tr('official_store').toUpperCase(),
                          style: GoogleFonts.manrope(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: c.t3, letterSpacing: 2)),
                    ],
                  ),
                ),
                _RoundIcon(icon: Icons.search_rounded, onTap: onSearchToggle),
                const SizedBox(width: 8),
                _RoundIcon(
                  icon: Icons.shopping_bag_outlined,
                  onTap: onCart,
                  badge: cartCount,
                ),
              ]),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap, this.badge = 0});
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.surf,
            shape: BoxShape.circle,
            border: Border.all(color: c.bd2),
          ),
          child: Icon(icon, color: c.gold, size: 20),
        ),
        if (badge > 0)
          Positioned(
            top: -3,
            right: -3,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(badge),
              tween: Tween(begin: 1.6, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.gold,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: c.bg, width: 1.5),
                ),
                child: Text('$badge',
                    style: const TextStyle(
                        fontSize: 9.5, fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1200), height: 1)),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Category chips ───────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.store, required this.allLabel, required this.onSelect});
  final StoreProvider store;
  final String allLabel;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cats = store.categories.where((cat) => store.countForCategory(cat.id) > 0).toList();

    Widget chip(String label, bool active, VoidCallback onTap, {IconData? icon}) =>
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? c.gold : c.surf,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: active ? c.gold : c.bd2),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: active ? const Color(0xFF1A1200) : c.gold),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? const Color(0xFF1A1200) : c.t1,
                  )),
            ]),
          ),
        );

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        itemCount: cats.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return chip(allLabel, store.selectedCategoryId == null, () => onSelect(null),
                icon: Icons.storefront_outlined);
          }
          final cat = cats[i - 1];
          return chip(cat.name, store.selectedCategoryId == cat.id, () => onSelect(cat.id),
              icon: categoryIcon(cat.iconKey));
        },
      ),
    );
  }
}

IconData categoryIcon(String key) => switch (key) {
      'person'        => Icons.person_outline_rounded,
      'woman'         => Icons.woman_outlined,
      'child_care'    => Icons.child_care_outlined,
      'mosque'        => Icons.mosque_outlined,
      'menu_book'     => Icons.menu_book_outlined,
      'water_drop'    => Icons.water_drop_outlined,
      'home'          => Icons.home_outlined,
      'bedtime'       => Icons.bedtime_outlined,
      'star'          => Icons.star_border_rounded,
      'flight'        => Icons.flight_takeoff_outlined,
      'card_giftcard' => Icons.card_giftcard_outlined,
      _               => Icons.storefront_outlined,
    };

// ── Category tile (image + scrim + name, like the storefront) ───────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.count,
    required this.onTap,
    this.fallbackImage,
  });
  final StoreCategoryModel category;
  final int count;
  final VoidCallback onTap;
  final String? fallbackImage;

  @override
  Widget build(BuildContext context) {
    final image = (category.featuredImage?.isNotEmpty ?? false)
        ? category.featuredImage
        : fallbackImage;
    final accent = category.accentColor;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: ProductImageFallback.gradientFor(category.id),
            ),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Stack(fit: StackFit.expand, children: [
            if (image != null)
              Opacity(opacity: 0.75, child: NetImage(image, fallback: const SizedBox())),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10, left: 10,
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(color: accent.withValues(alpha: 0.7)),
                ),
                child: Icon(categoryIcon(category.iconKey), size: 16, color: accent),
              ),
            ),
            Positioned(
              left: 12, right: 10, bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSerif(
                          fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('$count ${count == 1 ? 'item' : 'items'}',
                      style: GoogleFonts.manrope(
                          fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Hero shown when the admin hasn't configured banners ─────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.lang});
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1206), Color(0xFF3A2A0C), Color(0xFF6B4C18)],
        ),
        border: Border.all(color: c.gold.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(lang.tr('store_hero_tag').toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 9.5, fontWeight: FontWeight.w800,
                      color: const Color(0xFFE6C364), letterSpacing: 2)),
              const SizedBox(height: 6),
              Text(lang.tr('store_hero_title'),
                  style: GoogleFonts.notoSerif(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: Colors.white, height: 1.15)),
              const SizedBox(height: 6),
              Text(lang.tr('store_hero_sub'),
                  style: GoogleFonts.manrope(fontSize: 11.5, color: Colors.white70)),
            ],
          ),
        ),
        Image.asset('assets/images/logo.png', width: 96, height: 96),
      ]),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip({required this.lang, required this.hPad});
  final LanguageProvider lang;
  final double hPad;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget item(IconData icon, String key) => Expanded(
          child: Column(children: [
            Icon(icon, color: c.gold, size: 20),
            const SizedBox(height: 4),
            Text(lang.tr(key),
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 10.5, color: c.t2, height: 1.3)),
          ]),
        );
    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 22, hPad, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.bd),
      ),
      child: Row(children: [
        item(Icons.verified_outlined, 'trust_authentic'),
        item(Icons.payments_outlined, 'trust_cod'),
        item(Icons.local_shipping_outlined, 'trust_shipping'),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.hPad});
  final String title;
  final double hPad;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 12),
      child: Row(children: [
        Container(width: 3, height: 18, color: c.gold),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.notoSerif(
                fontSize: 18, fontWeight: FontWeight.w700, color: c.t1)),
      ]),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.store, required this.lang});
  final StoreProvider store;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final labels = {
      StoreSort.featured:  lang.tr('sort_featured'),
      StoreSort.newest:    lang.tr('sort_newest'),
      StoreSort.priceLow:  lang.tr('sort_price_low'),
      StoreSort.priceHigh: lang.tr('sort_price_high'),
    };
    return PopupMenuButton<StoreSort>(
      initialValue: store.sort,
      onSelected: store.setSort,
      color: c.elev,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => labels.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                child: Text(e.value,
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: e.key == store.sort ? FontWeight.w800 : FontWeight.w500,
                        color: e.key == store.sort ? c.gold : c.t1)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.surf,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: c.bd2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sort_rounded, size: 16, color: c.gold),
          const SizedBox(width: 6),
          Text(labels[store.sort]!,
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: c.t1)),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text, this.actionLabel, this.onAction});
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 46, color: c.t3),
        const SizedBox(height: 12),
        Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 14, color: c.t2)),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: c.gold)),
          ),
        ],
      ]),
    );
  }
}
