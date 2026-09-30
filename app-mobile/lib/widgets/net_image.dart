import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Public origin of the storefront — product/category images saved by the
/// admin panel as site-relative paths (`/products/x.png`) live here.
const kStorefrontOrigin = 'https://sunnahgrandeur.com';

/// Turns any stored image reference into a loadable absolute URL:
///   • absolute http(s) URLs are returned unchanged
///   • `//cdn…` protocol-relative URLs get https
///   • site-relative paths (`/products/p 1.png`) resolve against the
///     storefront, URL-encoded (file names contain spaces)
String resolveImageUrl(String raw) {
  final url = raw.trim();
  if (url.isEmpty) return url;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('//')) return 'https:$url';
  final path = url.startsWith('/') ? url : '/$url';
  return Uri.encodeFull('$kStorefrontOrigin$path');
}

/// Network image used everywhere in the app.
///
/// - Resolves relative storefront paths (see [resolveImageUrl]).
/// - On web, falls back to a plain <img> element when the host doesn't send
///   CORS headers (YouTube thumbnails, storefront images), which CanvasKit
///   otherwise refuses to draw.
/// - Shows a soft shimmer while loading and a branded fallback on error.
class NetImage extends StatelessWidget {
  const NetImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallback,
    this.alignment = Alignment.center,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallback;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveImageUrl(url);
    if (resolved.isEmpty) return _fallback(context);
    return Image.network(
      resolved,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _Shimmer(),
      errorBuilder: (context, _, __) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    if (fallback != null) return fallback!;
    final c = AppColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.gold.withValues(alpha: 0.18), c.surf],
        ),
      ),
      alignment: Alignment.center,
      child: Opacity(
        opacity: 0.45,
        child: Image.asset('assets/images/logo.png', width: 40, height: 40),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer();

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _ctrl.value * 3, 0),
            end: Alignment(-0.5 + _ctrl.value * 3, 0),
            colors: [c.surf, c.elev, c.surf],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
