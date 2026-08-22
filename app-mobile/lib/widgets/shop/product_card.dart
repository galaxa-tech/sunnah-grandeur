// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';

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

  static const _bg          = Color(0xFF0A0A0A);
  static const _surf        = Color(0xFF141414);
  static const _border      = Color(0xFF1F1F1F);
  static const _borderHov   = Color(0xFF3D3020);
  static const _gold        = Color(0xFFC9A84C);
  static const _textPri     = Color(0xFFFFFFFF);
  static const _textSec     = Color(0xFFA0A0A0);
  static const _red         = Color(0xFFDC2626);

  bool get _isSoldOut => widget.product.stockQuantity == 0;

  @override
  Widget build(BuildContext context) {
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
            color:        _surf,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovered && !_isSoldOut ? _borderHov : _border,
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
                    // Image / gradient fallback
                    _buildImageArea(p),

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
                            color: _red,
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
                            colors: [_bg.withOpacity(0.95), Colors.transparent],
                          ),
                        ),
                        child: GestureDetector(
                          onTap: _isSoldOut ? null : widget.onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isSoldOut ? _surf : _gold,
                              borderRadius: BorderRadius.circular(4),
                              border: _isSoldOut
                                  ? Border.all(color: _border)
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
                                color: _isSoldOut ? _textSec : _bg,
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
                          color: _gold.withOpacity(0.60),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.name,
                        style: GoogleFonts.notoSerif(
                          fontSize: 12, fontWeight: FontWeight.bold,
                          color: _textPri, height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.description,
                        style: GoogleFonts.manrope(
                          fontSize: 11, color: _textSec, height: 1.5,
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
                              color: _gold,
                            ),
                          ),
                          if (p.originalPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '\$${p.originalPrice!.toInt()}',
                              style: GoogleFonts.manrope(
                                fontSize: 11, color: _textSec,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: _textSec,
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
              size: 56, color: _gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p.category.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 9, fontWeight: FontWeight.bold,
              color: _gold.withOpacity(0.40),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:  gold ? const Color(0xFFC9A84C) : const Color(0xFF141414),
        border: onSurf ? Border.all(color: const Color(0xFF1F1F1F)) : null,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 9, fontWeight: FontWeight.bold,
          color: gold ? const Color(0xFF0A0A0A) : const Color(0xFFA0A0A0),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
