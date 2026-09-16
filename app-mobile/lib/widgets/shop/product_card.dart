// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';

/// ProductCard — pixel-for-pixel match of the website ProductCard component.
///
/// Layout: aspect-[3/4] image area + info body.
/// Hover overlay becomes a visible bottom bar on mobile (always shown).
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  final ProductModel    product;
  final VoidCallback?   onTap;
  final VoidCallback?   onAddToCart;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  bool get _isSoldOut => widget.product.stockQuantity == 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bg        = c.bg;
    final surf      = c.surf;
    final border    = c.bd;
    final borderHov = c.gold.withValues(alpha: c.isDark ? 0.45 : 0.35);
    final gold      = c.gold;
    final textPri   = c.t1;
    final textSec   = c.t2;
    final red       = c.red;

    final p = widget.product;
    final savings = p.originalPrice != null ? (p.originalPrice! - p.price) : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color:        surf,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovered && !_isSoldOut ? borderHov : border,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image area ────────────────────────────────────────────
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image / gradient fallback — Hero-tagged so tapping a
                    // card morphs straight into the PDP's main image instead
                    // of a flat cut, matching the tag used there.
                    Hero(tag: 'product-image-${p.id}', child: _buildImageArea(p)),

                    // Left badge (tag)
                    if (p.badge != null)
                      Positioned(
                        top: 10, left: 10,
                        child: _Badge(
                          label:    _isSoldOut ? 'Out of Stock' : p.badge!,
                          gold:     !_isSoldOut,
                          onSurf:   _isSoldOut,
                        ),
                      ),

                    // Right badge (savings)
                    if (p.originalPrice != null && !_isSoldOut && savings > 0)
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: red,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '\$${savings.toInt()} Off',
                            style: GoogleFonts.manrope(
                              fontSize: 9, fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Bottom CTA (slide up on hover; always visible on mobile)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve:    Curves.easeOut,
                      bottom:   _hovered ? 0 : -52,
                      left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end:   Alignment.topCenter,
                            colors: [bg.withValues(alpha: 0.95), Colors.transparent],
                          ),
                        ),
                        child: GestureDetector(
                          onTap: _isSoldOut ? null : widget.onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isSoldOut ? surf : gold,
                              borderRadius: BorderRadius.circular(4),
                              border: _isSoldOut
                                  ? Border.all(color: border)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _isSoldOut
                                  ? 'OUT OF STOCK'
                                  : 'ADD TO CART — \$${p.price.toInt()}',
                              style: GoogleFonts.manrope(
                                fontSize:   10,
                                fontWeight: FontWeight.bold,
                                color: _isSoldOut ? textSec : bg,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info body ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Opacity(
                  opacity: _isSoldOut ? 0.6 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.category.toUpperCase(),
                        style: GoogleFonts.manrope(
                          fontSize: 9, fontWeight: FontWeight.bold,
                          color: gold.withValues(alpha: 0.60),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.name,
                        style: GoogleFonts.notoSerif(
                          fontSize: 12, fontWeight: FontWeight.bold,
                          color: textPri, height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.description,
                        style: GoogleFonts.manrope(
                          fontSize: 11, color: textSec, height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '\$${p.price.toInt()}',
                            style: GoogleFonts.manrope(
                              fontSize: 14, fontWeight: FontWeight.bold,
                              color: gold,
                            ),
                          ),
                          if (p.originalPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '\$${p.originalPrice!.toInt()}',
                              style: GoogleFonts.manrope(
                                fontSize: 11, color: textSec,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: textSec,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildImageArea(ProductModel p) {
    if (p.primaryImage.isNotEmpty) {
      return ColorFiltered(
        colorFilter: _isSoldOut
            ? const ColorFilter.matrix([
                0.33, 0.33, 0.33, 0, 0,
                0.33, 0.33, 0.33, 0, 0,
                0.33, 0.33, 0.33, 0, 0,
                0,    0,    0,    0.4, 0,
              ])
            : const ColorFilter.mode(
                Colors.transparent, BlendMode.multiply),
        child: Image.network(
          p.primaryImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildGradientFallback(p),
        ),
      );
    }
    return _buildGradientFallback(p);
  }

  Widget _buildGradientFallback(ProductModel p) {
    final gold = AppColors.of(context).gold;
    final colors = _categoryGradient(p.categoryId);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.25,
            child: Icon(
              _categoryIcon(p.categoryId),
              size: 56, color: gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p.category.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 9, fontWeight: FontWeight.bold,
              color: gold.withValues(alpha: 0.40),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static List<Color> _categoryGradient(String catId) {
    switch (catId) {
      case 'fragrance': return const [Color(0xFF1a1206), Color(0xFF2d1f08)];
      case 'salah':     return const [Color(0xFF1a0f1a), Color(0xFF2d1a2d)];
      case 'home':      return const [Color(0xFF0a0f1a), Color(0xFF101825)];
      case 'women':     return const [Color(0xFF0f1a0f), Color(0xFF1a2d1a)];
      case 'men':       return const [Color(0xFF1a1a1a), Color(0xFF2d2d2d)];
      case 'kids':      return const [Color(0xFF0a1520), Color(0xFF102035)];
      case 'quran':     return const [Color(0xFF0d150a), Color(0xFF172210)];
      case 'gifts':     return const [Color(0xFF1a0f15), Color(0xFF2d1a25)];
      case 'ramadan':   return const [Color(0xFF1a0a0a), Color(0xFF2d1010)];
      case 'hajj':      return const [Color(0xFF0a1a12), Color(0xFF102a1e)];
      default:          return const [Color(0xFF1a1206), Color(0xFF2d1f08)];
    }
  }

  static IconData _categoryIcon(String catId) {
    switch (catId) {
      case 'fragrance': return Icons.water_drop_outlined;
      case 'salah':     return Icons.mosque_outlined;
      case 'home':      return Icons.home_outlined;
      case 'women':     return Icons.woman_outlined;
      case 'men':       return Icons.person_outlined;
      case 'kids':      return Icons.child_care_outlined;
      case 'quran':     return Icons.menu_book_outlined;
      case 'gifts':     return Icons.card_giftcard_outlined;
      case 'ramadan':   return Icons.star_border_outlined;
      case 'hajj':      return Icons.flight_takeoff_outlined;
      default:          return Icons.shopping_bag_outlined;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.gold = false, this.onSurf = false});
  final String label;
  final bool   gold;
  final bool   onSurf;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:  gold ? c.gold : c.surf,
        border: onSurf ? Border.all(color: c.bd) : null,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 9, fontWeight: FontWeight.bold,
          color: gold ? c.bg : c.t2,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
