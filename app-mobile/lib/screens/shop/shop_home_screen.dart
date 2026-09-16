// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/product_model.dart';
import '../../models/store_category_model.dart';
import '../../widgets/shop/product_card.dart';
import '../../widgets/shop/banner_carousel.dart';
import '../../theme/app_colors.dart';
import 'shop_product_detail_screen.dart';
import 'shop_cart_screen.dart';

// ─── Subcategories per category (matches website categories.ts) ───────────────
const _kSubcategories = <String, List<String>>{
  'men':        ['Thobes / Jubba', 'Panjabi / Kurtas', 'Tupi / Kufi / Caps', 'Sunnah Grooming'],
  'women':      ['Hijabs', 'Abayas', 'Khimars & Niqabs', 'Modest Fashion'],
  'kids':       ['Kids Islamic Wear', 'Kids Prayer Essentials', 'Islamic Toys', 'Learning & Quran Kits'],
  'salah':      ['Prayer Mats', 'Tasbih', 'Quran Accessories', 'Adhan & Smart Devices'],
  'quran':      ['Quran Collections', 'Tafsir & Hadith', 'Islamic Books', 'Kids Islamic Books'],
  'fragrance':  ['Attar & Oud', 'Bakhoor', 'Beard Care', 'Halal Skincare'],
  'home':       ['Islamic Wall Art', 'Lighting & Lamps', 'Islamic Clocks', 'Decorative Accessories'],
  'ramadan':    ['Ramadan Decor', 'Eid Fashion', 'Gift Boxes', 'Iftar & Suhoor Essentials'],
  'hajj':       ['Ihram Essentials', 'Travel Accessories', 'Dua & Guide Books', 'Hygiene Essentials'],
  'gifts':      ['Gifts for Him', 'Gifts for Her', 'Personalized Gifts', 'Islamic Gift Sets'],
};

// ─────────────────────────────────────────────────────────────────────────────
// ShopHomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  bool _drawerOpen     = false;
  String? _hoveredCat;
  String? _expandedMob;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = context.watch<StoreProvider>();
    final cart  = context.watch<CartProvider>();
    final w     = MediaQuery.of(context).size.width;
    final isWide = w > 900;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ── Page Header ───────────────────────────────────────────
                _PageHeader(
                  store:      store,
                  cartCount:  cart.itemCount,
                  isWide:     isWide,
                  onFilter:   () => setState(() => _drawerOpen = true),
                  onCart:     () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ShopCartScreen())),
                ),

                // ── Main content ──────────────────────────────────────────
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Desktop sidebar
                      if (isWide)
                        _DesktopSidebar(
                          store:      store,
                          hoveredCat: _hoveredCat,
                          onHover:    (id) => setState(() => _hoveredCat = id),
                          onSelect:   (id) {
                            store.setCategory(id);
                            setState(() => _hoveredCat = null);
                          },
                        ),

                      // Product grid
                      Expanded(
                        child: _ProductGrid(
                          store: store,
                          cart:  cart,
                          onProductTap: (p) => _openDetail(p),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mobile drawer overlay
          if (_drawerOpen)
            _MobileDrawer(
              store:       store,
              expandedCat: _expandedMob,
              onExpand:    (id) => setState(() => _expandedMob = _expandedMob == id ? null : id),
              onSelect:    (id) {
                store.setCategory(id);
                setState(() { _drawerOpen = false; _expandedMob = null; });
              },
              onClose:     () => setState(() => _drawerOpen = false),
            ),
        ],
      ),
    );
  }

  void _openDetail(ProductModel p) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ShopProductDetailScreen(product: p)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PageHeader — matches the website's <section> header with title + controls
// ─────────────────────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.store,
    required this.cartCount,
    required this.isWide,
    required this.onFilter,
    required this.onCart,
  });
  final StoreProvider store;
  final int          cartCount;
  final bool         isWide;
  final VoidCallback onFilter;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final catName = store.selectedCategoryName;
    final count   = store.products.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isWide ? 48 : 20, 52, isWide ? 48 : 20, 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.bd)),
      ),
      child: Stack(
        children: [
          // Gold glow
          Positioned(
            left: MediaQuery.of(context).size.width * 0.25,
            top: 0,
            child: Container(
              width: 400, height: 200,
              decoration: BoxDecoration(
                color:        c.gold.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(200),
                boxShadow: [
                  BoxShadow(color: c.gold.withValues(alpha: 0.05), blurRadius: 80, spreadRadius: 40)
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Islamic Lifestyle',
                style: GoogleFonts.manrope(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: c.gold, letterSpacing: 3.2,
                ),
              ),
              const SizedBox(height: 8),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _ShopTitleBlock(catName: catName, count: count, fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        _SortDropdown(store: store),
                        const SizedBox(width: 8),
                        _CartIconBtn(count: cartCount, onTap: onCart),
                      ],
                    ),
                  ],
                )
              else ...[
                // Mobile: the title gets the full row to itself — squeezing
                // it next to Categories/Sort/Cart left no room for even
                // "All Products" to render without truncating mid-word.
                _ShopTitleBlock(catName: catName, count: count, fontSize: 24),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderBtn(
                        icon:  Icons.filter_list_rounded,
                        label: 'Categories',
                        onTap: onFilter,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SortDropdown(store: store),
                    const SizedBox(width: 8),
                    _CartIconBtn(count: cartCount, onTap: onCart),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CartIconBtn extends StatelessWidget {
  const _CartIconBtn({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surf, borderRadius: BorderRadius.circular(6),
              border: Border.all(color: c.bd),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: c.gold, size: 18),
          ),
          if (count > 0)
            Positioned(
              top: -4, right: -4,
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: c.gold, shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('$count',
                    style: GoogleFonts.manrope(
                      fontSize: 9, fontWeight: FontWeight.bold, color: c.bg)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShopTitleBlock extends StatelessWidget {
  const _ShopTitleBlock({required this.catName, required this.count, required this.fontSize});
  final String catName;
  final int count;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          catName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoSerif(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: c.t1, height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count product${count != 1 ? 's' : ''} found',
          style: GoogleFonts.manrope(fontSize: 12, color: c.t2),
        ),
      ],
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.surf, borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.bd),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.t1, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.manrope(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: c.t1, letterSpacing: 1.0,
                )),
          ],
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.store});
  final StoreProvider store;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.surf, borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.bd),
      ),
      child: DropdownButton<StoreSort>(
        value: store.sort,
        dropdownColor: const Color(0xFF141414),
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.t2, size: 16),
        items: const [
          DropdownMenuItem(value: StoreSort.featured,  child: _SortLabel('FEATURED')),
          DropdownMenuItem(value: StoreSort.priceLow,  child: _SortLabel('PRICE: LOW')),
          DropdownMenuItem(value: StoreSort.priceHigh, child: _SortLabel('PRICE: HIGH')),
          DropdownMenuItem(value: StoreSort.newest,    child: _SortLabel('NEWEST')),
        ],
        onChanged: (v) { if (v != null) store.setSort(v); },
      ),
    );
  }
}

class _SortLabel extends StatelessWidget {
  const _SortLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text,
      style: GoogleFonts.manrope(
        fontSize: 11, fontWeight: FontWeight.bold,
        color: AppColors.of(context).t1, letterSpacing: 1.0,
      )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _DesktopSidebar — sticky left sidebar with categories + flyout subcategories
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.store,
    required this.hoveredCat,
    required this.onHover,
    required this.onSelect,
  });
  final StoreProvider        store;
  final String?              hoveredCat;
  final void Function(String?) onHover;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    return SizedBox(
      width: 208,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(lang.tr('browse'),
                style: GoogleFonts.manrope(
                  fontSize: 10, color: c.t2,
                  fontWeight: FontWeight.bold, letterSpacing: 2.0,
                )),
            ),
            const SizedBox(height: 12),

            // All Products
            _SidebarItem(
              icon:     Icons.storefront_outlined,
              label:    'All Products',
              count:    store.countForCategory(null),
              isActive: store.selectedCategoryId == null,
              onTap:    () => onSelect(null),
            ),

            // Categories
            ...store.categories.map((cat) {
              final isActive  = store.selectedCategoryId == cat.id;
              final isHovered = hoveredCat == cat.id;
              final subs      = _kSubcategories[cat.id] ?? [];

              return MouseRegion(
                onEnter: (_) => onHover(cat.id),
                onExit:  (_) => onHover(null),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _SidebarItem(
                      icon:     _iconForCat(cat),
                      label:    cat.name,
                      count:    store.countForCategory(cat.id),
                      isActive: isActive,
                      accentColor: cat.accentColor,
                      onTap:   () => onSelect(cat.id),
                    ),
                    // Flyout
                    if (isHovered && subs.isNotEmpty)
                      Positioned(
                        left: 208, top: 0,
                        child: Container(
                          width: 210,
                          margin: const EdgeInsets.only(left: 2),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:        const Color(0xFF0e0e0e),
                            border:       Border.all(color: c.bd),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow:    const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 24, offset: Offset(4, 4))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat.name.toUpperCase(),
                                style: GoogleFonts.manrope(
                                  fontSize: 9, fontWeight: FontWeight.bold,
                                  color: c.gold, letterSpacing: 1.5,
                                )),
                              const SizedBox(height: 8),
                              ...subs.map((s) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(children: [
                                  Icon(Icons.chevron_right_rounded,
                                      size: 12, color: c.t2),
                                  const SizedBox(width: 4),
                                  Text(s,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12, color: c.t2)),
                                ]),
                              )),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _iconForCat(StoreCategoryModel cat) {
    switch (cat.iconKey) {
      case 'person':         return Icons.person_outlined;
      case 'woman':          return Icons.woman_outlined;
      case 'child_care':     return Icons.child_care_outlined;
      case 'mosque':         return Icons.mosque_outlined;
      case 'menu_book':      return Icons.menu_book_outlined;
      case 'water_drop':     return Icons.water_drop_outlined;
      case 'home':           return Icons.home_outlined;
      case 'star':           return Icons.star_border_outlined;
      case 'flight':         return Icons.flight_takeoff_outlined;
      case 'card_giftcard':  return Icons.card_giftcard_outlined;
      case 'new_releases':   return Icons.new_releases_outlined;
      case 'trending_up':    return Icons.trending_up_rounded;
      default:               return Icons.storefront_outlined;
    }
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
    this.accentColor,
  });
  final IconData   icon;
  final String     label;
  final int        count;
  final bool       isActive;
  final VoidCallback onTap;
  final Color?     accentColor;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:  const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:        isActive ? c.gold.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon,
              size:  14,
              color: isActive ? c.gold : (accentColor?.withValues(alpha: 0.50) ?? c.t2)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                style: GoogleFonts.manrope(
                  fontSize: 12, fontWeight: FontWeight.bold,
                  color: isActive ? c.gold : c.t2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0)
              Text('$count',
                style: GoogleFonts.manrope(fontSize: 11, color: c.t2)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProductGrid
// ─────────────────────────────────────────────────────────────────────────────
class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.store,
    required this.cart,
    required this.onProductTap,
  });
  final StoreProvider          store;
  final CartProvider           cart;
  final void Function(ProductModel) onProductTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final products = store.products;
    final w        = MediaQuery.of(context).size.width;
    final lang     = context.watch<LanguageProvider>();

    if (store.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(c.gold),
          strokeWidth: 2,
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 52, color: c.bd),
            const SizedBox(height: 16),
            Text(lang.tr('no_products_category'),
              style: GoogleFonts.manrope(fontSize: 14, color: c.t2)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => store.setCategory(null),
              child: Text(lang.tr('view_all_products'),
                style: GoogleFonts.manrope(
                  fontSize: 14, fontWeight: FontWeight.bold,
                  color: c.gold,
                  decoration: TextDecoration.underline,
                  decorationColor: c.gold,
                )),
            ),
          ],
        ),
      );
    }

    // cols: 2 mobile, 3 sm, 4 xl — matching website grid-cols-2 sm:grid-cols-3 xl:grid-cols-4
    final cols = w < 600 ? 2 : w < 1200 ? 3 : 4;
    final hPad = w > 900 ? 24.0 : 16.0;

    return CustomScrollView(
      slivers: [
        if (store.banners.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
              child: BannerCarousel(
                banners: store.banners,
                onTap: (_) => store.setCategory(null),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:   cols,
              mainAxisSpacing:  12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.58, // matches 3/4 image + ~3 rows info
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final p = products[i];
                return ProductCard(
                  product: p,
                  onTap: () => onProductTap(p),
                  onAddToCart: () => _addToCart(context, p),
                );
              },
              childCount: products.length,
            ),
          ),
        ),
      ],
    );
  }

  void _addToCart(BuildContext context, ProductModel p) {
    if (p.stockQuantity == 0) return;
    final c = AppColors.of(context);
    HapticFeedback.lightImpact();
    cart.addToCart(p, 'Standard', 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: c.surf,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(children: [
          Icon(Icons.check_circle_outline_rounded, color: c.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text('${p.name} added to cart',
              style: GoogleFonts.manrope(color: c.t1, fontSize: 13)),
          ),
        ]),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MobileDrawer — full-screen left drawer matching website mobile sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({
    required this.store,
    required this.expandedCat,
    required this.onExpand,
    required this.onSelect,
    required this.onClose,
  });
  final StoreProvider        store;
  final String?              expandedCat;
  final void Function(String) onExpand;
  final void Function(String?) onSelect;
  final VoidCallback         onClose;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.60),
          ),
        ),
        // Drawer panel
        Positioned(
          left: 0, top: 0, bottom: 0,
          child: Container(
            width: 280,
            color: c.bg,
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: c.bd))),
                    child: Row(
                      children: [
                        Text(lang.tr('categories_caps'),
                          style: GoogleFonts.manrope(
                            fontSize: 13, fontWeight: FontWeight.bold,
                            color: c.t1, letterSpacing: 1.5,
                          )),
                        const Spacer(),
                        GestureDetector(
                          onTap: onClose,
                          child: Icon(Icons.close_rounded,
                              color: c.t2, size: 22),
                        ),
                      ],
                    ),
                  ),

                  // List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _MobItem(
                          icon: Icons.storefront_outlined,
                          label: 'All Products',
                          count: store.countForCategory(null),
                          isActive: store.selectedCategoryId == null,
                          onTap: () => onSelect(null),
                        ),
                        ...store.categories.map((cat) {
                          final isActive  = store.selectedCategoryId == cat.id;
                          final isOpen    = expandedCat == cat.id;
                          final subs      = _kSubcategories[cat.id] ?? [];

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _MobItem(
                                      icon: Icons.storefront_outlined,
                                      label: cat.name,
                                      count: store.countForCategory(cat.id),
                                      isActive: isActive,
                                      accentColor: cat.accentColor,
                                      onTap: () => onSelect(cat.id),
                                    ),
                                  ),
                                  if (subs.isNotEmpty)
                                    GestureDetector(
                                      onTap: () => onExpand(cat.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: AnimatedRotation(
                                          turns: isOpen ? 0.5 : 0,
                                          duration: const Duration(milliseconds: 200),
                                          child: Icon(
                                            Icons.expand_more_rounded,
                                            size: 18, color: c.t2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (isOpen && subs.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(left: 16),
                                  padding: const EdgeInsets.only(left: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: c.bd))),
                                  child: Column(
                                    children: subs.map((s) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(children: [
                                        Container(
                                          width: 4, height: 4,
                                          decoration: BoxDecoration(
                                            color: c.bd,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(s,
                                          style: GoogleFonts.manrope(
                                            fontSize: 12, color: c.t2)),
                                      ]),
                                    )).toList(),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobItem extends StatelessWidget {
  const _MobItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
    this.accentColor,
  });
  final IconData   icon;
  final String     label;
  final int        count;
  final bool       isActive;
  final VoidCallback onTap;
  final Color?     accentColor;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin:  const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color:        isActive ? c.gold.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon,
              size: 16,
              color: isActive ? c.gold : (accentColor?.withValues(alpha: 0.5) ?? c.t2)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: isActive ? c.gold : c.t2,
                )),
            ),
            if (count > 0)
              Text('$count',
                style: GoogleFonts.manrope(fontSize: 11, color: c.t2)),
          ],
        ),
      ),
    );
  }
}
