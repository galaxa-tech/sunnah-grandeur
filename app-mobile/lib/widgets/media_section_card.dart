import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'net_image.dart';

/// A media section tile. When [previews] (thumbnail URLs) are provided it
/// shows a live collage of the section's newest content under a tinted
/// gradient; otherwise it falls back to a designed cover ([artwork] over
/// [gradient]).
class MediaSectionCard extends StatelessWidget {
  const MediaSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sectionLabel,
    required this.badge,
    required this.gradient,
    required this.categoryColor,
    required this.icon,
    this.previews = const [],
    this.artwork,
    this.loading = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String sectionLabel;
  final String badge;
  final Gradient gradient;
  final Color categoryColor;
  final IconData icon;
  final List<String> previews;
  final Widget? artwork;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tint = gradient.colors.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            height: 164,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: categoryColor.withValues(alpha: 0.25)),
            ),
            child: Stack(fit: StackFit.expand, children: [
              if (previews.isNotEmpty)
                _Collage(urls: previews)
              else if (artwork != null)
                artwork!,
              // Tint + legibility scrim
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      tint.withValues(alpha: 0.96),
                      tint.withValues(alpha: previews.isNotEmpty ? 0.55 : 0.2),
                      tint.withValues(alpha: previews.isNotEmpty ? 0.15 : 0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Meta
              Positioned(
                left: 16, bottom: 14, right: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: loading
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.6, color: Colors.white),
                              )
                            : Icon(icon, color: Colors.white, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sectionLabel,
                        style: AppTextStyles.cinzelSm(c, color: categoryColor, size: 8.5)
                            .copyWith(letterSpacing: 2.2),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(title,
                        style: GoogleFonts.notoSerif(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            height: 1.1)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 11.5, color: Colors.white.withValues(alpha: 0.78), height: 1.35)),
                  ],
                ),
              ),
              // Badge
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(badge,
                      style: GoogleFonts.inter(
                          fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              // Chevron
              Positioned(
                right: 14, bottom: 14,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  child: Icon(Icons.arrow_forward_rounded, color: tint, size: 18),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 1 large + up to 2 stacked thumbnails, aligned to the right side of the
/// card so the title area on the left stays readable.
class _Collage extends StatelessWidget {
  const _Collage({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final small = urls.skip(1).take(2).toList();
    return Row(children: [
      const Spacer(flex: 2),
      Expanded(
        flex: 5,
        child: Row(children: [
          Expanded(flex: 3, child: NetImage(urls.first)),
          if (small.isNotEmpty) ...[
            const SizedBox(width: 2),
            Expanded(
              flex: 2,
              child: Column(children: [
                for (var i = 0; i < small.length; i++) ...[
                  if (i > 0) const SizedBox(height: 2),
                  Expanded(child: NetImage(small[i])),
                ],
              ]),
            ),
          ],
        ]),
      ),
    ]);
  }
}
