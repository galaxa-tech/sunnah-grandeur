import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../net_image.dart';

/// Product tile used in grids and rails.
///
/// Always-visible round "add" button (touch devices have no hover) that
/// morphs into a ✓ for a moment after tapping — immediate, tactile feedback
/// that pairs with the cart badge bump in the bottom navigation.
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.width,
  });

  final ProductModel  product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final double?       width;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _justAdded = false;

  bool get _soldOut => widget.product.stockQuantity == 0;

  Future<void> _add() async {
    if (_soldOut || widget.onAddToCart == null || _justAdded) return;
    HapticFeedback.mediumImpact();
    widget.onAddToCart!();
    setState(() => _justAdded = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _justAdded = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = widget.product;
    final savingsPct = (p.originalPrice != null && p.originalPrice! > p.price)
        ? (((p.originalPrice! - p.price) / p.originalPrice!) * 100).round()
        : 0;

    return SizedBox(
      width: widget.width,
      child: Material(
        color: c.surf,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.bd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(fit: StackFit.expand, children: [
                    Hero(tag: 'product-image-${p.id}', child: _image(c, p)),
                    if (p.badge != null || _soldOut)
                      Positioned(
                        top: 8, left: 8,
                        child: _Chip(
                          label: _soldOut ? 'Sold out' : p.badge!,
                          filled: !_soldOut,
                        ),
                      ),
                    if (savingsPct > 0 && !_soldOut)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.red,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text('-$savingsPct%',
                              style: GoogleFonts.manrope(
                                  fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    if (!_soldOut && widget.onAddToCart != null)
                      Positioned(
                        right: 8, bottom: 8,
                        child: _AddButton(added: _justAdded, onTap: _add),
                      ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Opacity(
                    opacity: _soldOut ? 0.55 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: c.gold.withValues(alpha: 0.75), letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 34,
                          child: Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSerif(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: c.t1, height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text(p.priceDisplay,
                              style: GoogleFonts.manrope(
                                  fontSize: 15, fontWeight: FontWeight.w800, color: c.gold)),
                          if (p.originalPriceDisplay != null && savingsPct > 0) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(p.originalPriceDisplay!,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11, color: c.t3,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: c.t3,
                                  )),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _image(AppColors c, ProductModel p) {
    final fallback = ProductImageFallback(categoryId: p.categoryId);
    final img = p.primaryImage.isEmpty
        ? fallback
        : NetImage(p.primaryImage, fallback: fallback);
    if (!_soldOut) return img;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0,    0,    0,    0.5, 0,
      ]),
      child: img,
    );
  }
}

/// Branded placeholder for a product with no photo: category-tinted
/// gradient with the Sunnah Grandeur mark, instead of a generic icon.
class ProductImageFallback extends StatelessWidget {
  const ProductImageFallback({super.key, required this.categoryId});
  final String categoryId;

  static List<Color> gradientFor(String catId) => switch (catId) {
        'fragrance' => const [Color(0xFF2d1f08), Color(0xFF4a3310)],
        'salah'     => const [Color(0xFF2d1a2d), Color(0xFF442844)],
        'home'      => const [Color(0xFF101825), Color(0xFF1c2a40)],
        'women'     => const [Color(0xFF1a2d1a), Color(0xFF28442a)],
        'men'       => const [Color(0xFF2a2418), Color(0xFF3d3423)],
        'kids'      => const [Color(0xFF102035), Color(0xFF1a3352)],
        'quran'     => const [Color(0xFF172210), Color(0xFF26381b)],
        'gifts'     => const [Color(0xFF2d1a25), Color(0xFF45283a)],
        'ramadan'   => const [Color(0xFF2d1010), Color(0xFF451a1a)],
        'hajj'      => const [Color(0xFF102a1e), Color(0xFF1a4230)],
        _           => const [Color(0xFF2d1f08), Color(0xFF4a3310)],
      };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientFor(categoryId),
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.55,
          child: Image.asset('assets/images/logo.png', width: 64, height: 64),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.added, required this.onTap});
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      label: 'Add to cart',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: added ? c.green : c.gold,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              added ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
              key: ValueKey(added),
              size: 19,
              color: added ? Colors.white : const Color(0xFF1A1200),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.filled = true});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? c.gold : Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 9, fontWeight: FontWeight.w800,
          color: filled ? const Color(0xFF1A1200) : Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
