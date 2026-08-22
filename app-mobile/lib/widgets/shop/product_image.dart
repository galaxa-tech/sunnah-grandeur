import 'package:flutter/material.dart';

/// Smart image loader for product images.
///
/// Priority:
///   1. Asset path  (mapped from /products/Filename.png → assets/images/Filename.png)
///   2. Full URL    (https://...)
///   3. Gradient + icon fallback
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.bgGradient,
    this.bgIcon,
    this.isSoldOut = false,
  });

  final String imagePath;
  final BoxFit fit;
  final String? bgGradient;
  final IconData? bgIcon;
  final bool isSoldOut;

  static const _gold = Color(0xFFC9A84C);

  /// Map a website-style /products/... path to an assets/images/... path.
  static String? _assetPath(String raw) {
    if (raw.startsWith('/products/')) {
      final filename = raw.substring('/products/'.length);
      return 'assets/images/$filename';
    }
    if (raw.startsWith('assets/')) return raw;
    return null;
  }

  static bool _isNetworkUrl(String raw) =>
      raw.startsWith('http://') || raw.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    Widget img;

    if (imagePath.isNotEmpty) {
      final asset = _assetPath(imagePath);
      if (asset != null) {
        img = Image.asset(
          asset,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      } else if (_isNetworkUrl(imagePath)) {
        img = Image.network(
          imagePath,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      } else {
        img = _fallback();
      }
    } else {
      img = _fallback();
    }

    if (isSoldOut) {
      img = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0,    0,    0,    0.4, 0,
        ]),
        child: img,
      );
    }

    return img;
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: bgGradient != null
            ? _parseGradient(bgGradient!)
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a1206), Color(0xFF2d1f08)],
              ),
      ),
      child: Center(
        child: bgIcon != null
            ? Icon(bgIcon, color: _gold.withValues(alpha: 0.25), size: 56)
            : const Icon(Icons.spa_outlined, color: Color(0x40C9A84C), size: 40),
      ),
    );
  }

  static LinearGradient _parseGradient(String css) {
    // Parse common gradient patterns used in the website
    // e.g. "linear-gradient(145deg, #1a1206 0%, #2d1f08 100%)"
    try {
      final colorRe = RegExp(r'#([0-9a-fA-F]{6})');
      final matches = colorRe.allMatches(css).toList();
      if (matches.length >= 2) {
        final c1 = Color(int.parse('FF${matches[0].group(1)!}', radix: 16));
        final c2 = Color(int.parse('FF${matches[1].group(1)!}', radix: 16));
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        );
      }
    } catch (_) {}
    return const LinearGradient(
      colors: [Color(0xFF1a1206), Color(0xFF2d1f08)],
    );
  }
}
