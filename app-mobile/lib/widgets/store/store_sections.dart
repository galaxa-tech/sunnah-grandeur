import 'package:flutter/material.dart';
import '../../models/store_category_model.dart';
import '../../providers/store_provider.dart';
import 'store_design.dart';

class StoreHeaderSection extends StatelessWidget {
  const StoreHeaderSection({
    super.key,
    required this.title,
    required this.count,
    required this.sort,
    required this.onSortChanged,
    required this.onOpenCategories,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  final String title;
  final int count;
  final StoreSort sort;
  final ValueChanged<StoreSort> onSortChanged;
  final VoidCallback onOpenCategories;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 18),
      decoration: const BoxDecoration(
        color: sgStoreBg,
        border: Border(bottom: BorderSide(color: sgStoreBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ISLAMIC LIFESTYLE', style: sgLabel()),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: sgSerif(size: 30), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('$count product${count == 1 ? '' : 's'} found', style: sgBody(size: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StoreIconButton(icon: Icons.filter_list_rounded, onTap: onOpenCategories),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: sgStoreSurface,
                    border: Border.all(color: sgStoreBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: TextEditingController(text: searchQuery)
                      ..selection = TextSelection.collapsed(offset: searchQuery.length),
                    onChanged: onSearchChanged,
                    style: sgBody(color: sgStoreText, size: 13),
                    cursorColor: sgStoreGold,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, color: sgStoreMuted, size: 18),
                      hintText: 'Search products',
                      hintStyle: sgBody(size: 12),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.only(top: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: sgStoreSurface,
                  border: Border.all(color: sgStoreBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StoreSort>(
                    value: sort,
                    dropdownColor: sgStoreSurface,
                    icon: const Icon(Icons.expand_more_rounded, color: sgStoreText, size: 18),
                    style: sgBody(color: sgStoreText, size: 11, weight: FontWeight.w900),
                    onChanged: (value) {
                      if (value != null) onSortChanged(value);
                    },
                    items: const [
                      DropdownMenuItem(value: StoreSort.featured, child: Text('FEATURED')),
                      DropdownMenuItem(value: StoreSort.priceLow, child: Text('LOW')),
                      DropdownMenuItem(value: StoreSort.priceHigh, child: Text('HIGH')),
                      DropdownMenuItem(value: StoreSort.newest, child: Text('NEWEST')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StorePromoBanner extends StatelessWidget {
  const StorePromoBanner({super.key, this.banner});
  final StoreBannerModel? banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1206),
        border: Border.all(color: sgStoreBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (banner?.imageUrl != null)
            Image.network(
              banner!.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Container(color: Colors.black.withValues(alpha: 0.42)),
          Positioned(
            right: -20,
            top: 5,
            child: Icon(Icons.mosque_outlined, size: 150, color: sgStoreGold.withValues(alpha: 0.08)),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner?.subtitle.toUpperCase() ?? 'PREMIUM ISLAMIC LIFESTYLE', style: sgLabel(size: 9)),
                const SizedBox(height: 5),
                Text(
                  banner?.title ?? 'Curated Sunnah Essentials',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sgSerif(size: 22),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: sgStoreGold, borderRadius: BorderRadius.circular(4)),
                  child: Text((banner?.cta ?? 'Shop now').toUpperCase(), style: sgBody(color: sgStoreBg, size: 10, weight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryRail extends StatelessWidget {
  const CategoryRail({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.countForCategory,
    required this.onSelected,
  });

  final List<StoreCategoryModel> categories;
  final String? selectedId;
  final int Function(String? id) countForCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
        children: [
          _CategoryTile(
            title: 'All Products',
            icon: Icons.storefront_outlined,
            accent: sgStoreGold,
            active: selectedId == null,
            count: countForCategory(null),
            onTap: () => onSelected(null),
          ),
          ...categories.map((cat) => _CategoryTile(
                title: cat.name,
                icon: storeIcon(cat.iconKey),
                accent: cat.accentColor,
                active: selectedId == cat.id,
                count: countForCategory(cat.id),
                onTap: () => onSelected(cat.id),
              )),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.accent,
    required this.active,
    required this.count,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 128,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? sgStoreGold.withValues(alpha: 0.15) : sgStoreSurface,
          border: Border.all(color: active ? sgStoreGold : sgStoreBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? sgStoreGold : accent.withValues(alpha: 0.72), size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: sgBody(color: active ? sgStoreGold : sgStoreText, size: 11, weight: FontWeight.w900)),
                  Text('$count items', style: sgBody(size: 9.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
