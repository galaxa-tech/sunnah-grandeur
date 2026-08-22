import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A horizontal video/media row item showing a thumbnail, play button,
/// duration badge, title, metadata, and optional pill.
class VideoRowItem extends StatelessWidget {
  const VideoRowItem({
    super.key,
    required this.title,
    required this.author,
    required this.duration,
    required this.views,
    this.pillLabel,
    this.pillVariant = 'gold',
    this.thumbnailUrl,
    this.thumbColor,
    this.playIconColor,
    this.onTap,
  });

  final String title;
  final String author;
  final String duration;
  final String views;
  final String? pillLabel;
  final String pillVariant;
  final String? thumbnailUrl;
  final Color? thumbColor;
  final Color? playIconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final iconColor = playIconColor ?? c.gold;
    final tColor = thumbColor ?? c.goldSurface;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail
          Container(
            width: 90, height: 62,
            decoration: BoxDecoration(
              color: tColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.bd),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(alignment: Alignment.center, children: [
              if (thumbnailUrl != null)
                Positioned.fill(
                  child: Image.network(
                    thumbnailUrl!,
                    fit: BoxFit.cover,
                    frameBuilder: (_, child, frame, loaded) =>
                        frame == null && !loaded
                            ? Container(color: tColor)
                            : child,
                    errorBuilder: (_, __, ___) => Container(color: tColor),
                  ),
                ),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.14),
                  border: Border.all(color: iconColor.withValues(alpha: 0.32)),
                ),
                child: Icon(Icons.play_arrow_rounded, color: iconColor, size: 16),
              ),
              Positioned(
                bottom: 5, right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(duration,
                    style: AppTextStyles.bodyMuted(c, size: 8)
                        .copyWith(color: Colors.white)),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(title, style: AppTextStyles.heading(c, fontSize: 14),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(children: [
                  Text(author, style: AppTextStyles.bodyMuted(c, size: 9.5)),
                  if (pillLabel != null) ...[
                    const SizedBox(width: 6),
                    _pill(c, pillLabel!, pillVariant),
                  ],
                  const Spacer(),
                  Text(views, style: AppTextStyles.bodyMuted(c, size: 9.5)),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _pill(AppColors c, String label, String variant) {
    Color fg, bg, border;
    switch (variant) {
      case 'green':
        fg = c.green; bg = c.green.withValues(alpha: 0.10); border = c.green.withValues(alpha: 0.22);
        break;
      case 'red':
        fg = c.red;   bg = c.red.withValues(alpha: 0.10);   border = c.red.withValues(alpha: 0.22);
        break;
      default:
        fg = c.gold;  bg = c.goldSurface;              border = c.gold.withValues(alpha: 0.22);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(100),
        border: Border.all(color: border),
      ),
      child: Text(label,
        style: GoogleFonts.inter(fontSize: 8, color: fg, fontWeight: FontWeight.w500)),
    );
  }
}
