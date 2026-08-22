import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'store_design.dart';

class StoreProductCard extends StatelessWidget {
  const StoreProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onAddToCart,
    required this.onToggleFavorite,
  });

  final ProductModel product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleFavorite;

  bool get _soldOut => product.stockQuantity <= 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: sgStoreSurface,
        border: Border.all(color: sgStoreBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ProductImage(product: product, soldOut: _soldOut),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _Tag(
                      label: _soldOut ? 'Out of Stock' : product.badge,
                      muted: _soldOut,
                    ),
                  ),
                  if (product.originalPriceInCents != null && !_soldOut)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: _Discount(product: product),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: GestureDetector(
                      onTap: onToggleFavorite,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: sgStoreBg.withValues(alpha: 0.82),
                          border: Border.all(color: sgStoreBorder),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavorite ? sgStoreGold : sgStoreText,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: GestureDetector(
                        onTap: _soldOut ? null : onAddToCart,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          margin: const EdgeInsets.only(right: 38),
                          decoration: BoxDecoration(
                            color: _soldOut ? sgStoreSurface : sgStoreGold,
                            border: Border.all(color: _soldOut ? sgStoreBorder : sgStoreGold),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _soldOut ? 'OUT OF STOCK' : 'ADD - ${product.priceDisplay}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sgBody(
                              color: _soldOut ? sgStoreMuted : sgStoreBg,
                              size: 9,
                              weight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sgLabel(color: sgStoreGold.withValues(alpha: 0.65), size: 8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: sgBody(color: sgStoreText, size: 12, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: sgBody(size: 10.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(product.priceDisplay, style: sgBody(color: sgStoreGold, size: 14, weight: FontWeight.w900)),
                      if (product.originalPriceDisplay != null) ...[
                        const SizedBox(width: 7),
                        Text(
                          product.originalPriceDisplay!,
                          style: sgBody(size: 11).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.soldOut});
  final ProductModel product;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    if (product.primaryImage.isEmpty) {
      return Container(
        color: const Color(0xFF1A1206),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(storeIcon(product.categoryId), color: sgStoreGold.withValues(alpha: 0.32), size: 54),
            const SizedBox(height: 8),
            Text(
              product.category.toUpperCase(),
              style: sgLabel(color: sgStoreGold.withValues(alpha: 0.4), size: 8),
            ),
          ],
        ),
      );
    }
    return ColorFiltered(
      colorFilter: soldOut
          ? const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 0.45, 0,
            ])
          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: Image.network(
        product.primaryImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1206)),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.muted});
  final String? label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (label == null || label!.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: muted ? sgStoreSurface : sgStoreGold,
        border: Border.all(color: muted ? sgStoreBorder : sgStoreGold),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label!.toUpperCase(),
        style: sgBody(color: muted ? sgStoreMuted : sgStoreBg, size: 8, weight: FontWeight.w900),
      ),
    );
  }
}

class _Discount extends StatelessWidget {
  const _Discount({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final off = ((product.originalPriceInCents! - product.priceInCents) / 100).round();
    if (off <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text('\$$off Off', style: sgBody(color: Colors.white, size: 8, weight: FontWeight.w900)),
    );
  }
}
