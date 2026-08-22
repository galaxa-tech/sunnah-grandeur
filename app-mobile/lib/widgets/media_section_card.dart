import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A media section card with a gradient background, icon, title, and badge.
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
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String sectionLabel;
  final String badge;
  final Gradient gradient;
  final Color categoryColor;
  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: gradient,
          border: Border.all(color: c.bd2),
        ),
        child: Stack(children: [
          // Gradient overlay (bottom)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.55],
                  colors: [Color(0xA6000000), Colors.transparent],
                ),
              ),
            ),
          ),
          // Center icon
          Center(child: icon),
          // Meta bottom-left
          Positioned(
            left: 14, bottom: 12, right: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sectionLabel,
                  style: AppTextStyles.cinzelSm(c, color: categoryColor, size: 8)
                      .copyWith(letterSpacing: 0.28 * 8),
                ),
                const SizedBox(height: 4),
                Text(title,
                  style: AppTextStyles.heading(c, color: Colors.white,
                      fontSize: 19)),
                const SizedBox(height: 3),
                Text(subtitle,
                  style: AppTextStyles.bodyMuted(c, size: 10)
                      .copyWith(color: Colors.white60)),
              ],
            ),
          ),
          // Badge top-right
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withOpacity(0.32)),
              ),
              child: Text(badge,
                style: AppTextStyles.bodyMuted(c, size: 8)
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ),
        ]),
      ),
    );
  }
}
