import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/store_category_model.dart';
import '../../theme/app_colors.dart';


/// Auto-advancing promo banner carousel — the admin-managed
/// `StoreProvider.banners` feed finally has somewhere to render. Matches the
/// card-based feature-banner look from the Pinterest/competitor reference
/// (photo + gradient scrim + title/subtitle/CTA), not a plain menu row.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners, this.onTap});

  final List<StoreBannerModel> banners;
  final ValueChanged<StoreBannerModel>? onTap;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _controller;
  Timer? _autoAdvance;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    if (widget.banners.length > 1) {
      _autoAdvance = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_page + 1) % widget.banners.length;
        _controller.animateToPage(next,
            duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    final c = AppColors.of(context);

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: widget.banners.length,
            itemBuilder: (_, i) {
              final banner = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: GestureDetector(
                  onTap: () => widget.onTap?.call(banner),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
                          Image.network(banner.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: c.bg))
                        else
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1a1206), Color(0xFF2d1f08)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        // Scrim for text legibility over any photo.
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [c.bg.withValues(alpha: 0.85), c.bg.withValues(alpha: 0.25)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(banner.title,
                                  style: GoogleFonts.notoSerif(
                                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (banner.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(banner.subtitle,
                                    style: GoogleFonts.manrope(fontSize: 11.5, color: Colors.white70),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: c.gold,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(banner.cta.toUpperCase(),
                                    style: GoogleFonts.manrope(
                                        fontSize: 9, fontWeight: FontWeight.bold, color: c.bg, letterSpacing: 0.5)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? c.gold : c.gold.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
