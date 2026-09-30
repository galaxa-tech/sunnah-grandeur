import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/media_section_card.dart';
import '../../widgets/video_row_item.dart';
import '../../providers/media_provider.dart';
import '../../providers/language_provider.dart';
import 'quran_screen.dart';
import 'ruqyah_screen.dart';
import 'youtube_feed_screen.dart';
import 'video_player_screen.dart';

class MediaHubScreen extends StatelessWidget {
  const MediaHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c       = AppColors.of(context);
    final lang    = context.watch<LanguageProvider>();
    final media   = context.watch<MediaProvider>();
    final trending = media.videos.take(2).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lang.tr('media'), style: AppTextStyles.brand(c)),
                Text(lang.tr('islamic_content_library'), style: AppTextStyles.brandTag(c)),
              ]),
              _IconBtn(icon: Icons.search_rounded, c: c),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                EyeRow(label: lang.tr('choose_section')),

                // Islamic Videos
                MediaSectionCard(
                  title:         lang.tr('islamic_videos'),
                  subtitle:      lang.tr('islamic_videos_sub'),
                  sectionLabel:  lang.tr('section_01'),
                  badge:         '${media.videos.length} ${lang.tr("videos")}',
                  categoryColor: const Color(0xFFE2C07A),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF3D2A08), Color(0xFF6B4C18), Color(0xFF8B6824)],
                    stops: [0.0, 0.4, 1.0],
                  ),
                  icon: Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                      border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.5),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  ),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const YoutubeFeedScreen())),
                ),

                // Quran
                MediaSectionCard(
                  title:         lang.tr('quran'),
                  subtitle:      lang.tr('quran_sub'),
                  sectionLabel:  lang.tr('section_02'),
                  badge:         '${media.quranMedia.length} ${lang.tr("surahs")}',
                  categoryColor: const Color(0xFF6EE8A8),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF0D2E1E), Color(0xFF1A5C3A), Color(0xFF2E7D52)],
                    stops: [0.0, 0.4, 1.0],
                  ),
                  icon: Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withOpacity(0.18),
                      border: Border.all(color: Colors.white.withOpacity(0.40), width: 1.5),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
                  ),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const QuranScreen())),
                ),

                // Ruqyah
                MediaSectionCard(
                  title:         lang.tr('ruqyah'),
                  subtitle:      lang.tr('ruqyah_sub'),
                  sectionLabel:  lang.tr('section_03'),
                  badge:         '${media.ruqyahMedia.length} ${lang.tr("recitations")}',
                  categoryColor: const Color(0xFFFFAA9A),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF3D0E08), Color(0xFF6B2018), Color(0xFF8B3828)],
                    stops: [0.0, 0.4, 1.0],
                  ),
                  icon: Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white.withOpacity(0.38), width: 1.5),
                    ),
                    child: const Icon(Icons.healing_rounded, color: Colors.white, size: 28),
                  ),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RuqyahScreen())),
                ),

                if (trending.isNotEmpty) ...[
                  EyeRow(label: lang.tr('trending_now')),
                  ...trending.map((v) => VideoRowItem(
                        title: v.title,
                        author: v.author,
                        duration: v.duration,
                        views: v.views,
                        pillLabel: v.category,
                        thumbnailUrl: v.thumbnail,
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: v))),
                      )),
                ],
                const SizedBox(height: 10),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.c});
  final IconData icon;
  final AppColors c;
  @override
  Widget build(BuildContext context) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.bd2)),
    child: Icon(icon, color: c.gold, size: 18),
  );
}
