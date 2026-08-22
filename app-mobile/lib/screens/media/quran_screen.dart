import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/video_row_item.dart';
import '../../providers/media_provider.dart';
import '../../models/video_model.dart';
import 'video_player_screen.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c     = AppColors.of(context);
    final media = context.watch<MediaProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Row(children: [
              _BackBtn(c: c),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quran', style: AppTextStyles.brandSmall(c)),
                Text('Tilawah · Tajweed · Memorization',
                    style: AppTextStyles.brandTag(c)),
              ]),
            ]),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: media.isLoadingQuran
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => media.refreshType('quran'),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(children: [
                        // Featured card
                        if (media.quranMedia.isNotEmpty)
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => VideoPlayerScreen(
                                      video: media.quranMedia.first)),
                            ),
                            child: _FeaturedQuranCard(
                                c: c, video: media.quranMedia.first),
                          ),

                        const EyeRow(label: 'All Recitations'),

                        if (media.quranMedia.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text('No recitations available.',
                                style: AppTextStyles.bodyMuted(c)),
                          ),

                        ...media.quranMedia.map((m) => VideoRowItem(
                              title:        m.title,
                              author:       m.author,
                              duration:     m.duration,
                              views:        m.views,
                              pillLabel:    m.category,
                              pillVariant:  'green',
                              thumbnailUrl: m.thumbnail,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          VideoPlayerScreen(video: m))),
                            )),

                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _FeaturedQuranCard extends StatelessWidget {
  const _FeaturedQuranCard({required this.c, required this.video});
  final AppColors c;
  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF2E7D52).withValues(alpha: 0.20)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A2E7D52), blurRadius: 12)
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        // Thumbnail
        SizedBox(
          height: 150,
          child: Stack(fit: StackFit.expand, children: [
            if (video.thumbnail.isNotEmpty)
              Image.network(video.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0D2E1E), Color(0xFF2E7D52)],
                          ),
                        ),
                      )),
            // Dark overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65)
                  ],
                ),
              ),
            ),
            // Play button
            Center(
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.38),
                      width: 1.5),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 28),
              ),
            ),
            // Title overlay
            Positioned(
              bottom: 10, left: 14, right: 14,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Featured Tilawah',
                    style: AppTextStyles.cinzelSm(c,
                        color: const Color(0xFF6EE8A8), size: 8)
                        .copyWith(letterSpacing: 1.8)),
                const SizedBox(height: 3),
                Text(video.title,
                    style: AppTextStyles.heading(c,
                        color: Colors.white, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
            // Duration badge
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x992E7D52),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(video.duration,
                    style: AppTextStyles.bodyMuted(c, size: 8)
                        .copyWith(color: Colors.white)),
              ),
            ),
          ]),
        ),
        // Meta
        Container(
          color: c.isDark ? c.surf : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Text(video.author,
                style: AppTextStyles.body(c, size: 11)),
            const Spacer(),
            Text('${video.views} views',
                style: AppTextStyles.bodyMuted(c, size: 10)),
          ]),
        ),
      ]),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.c});
  final AppColors c;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: c.bd2)),
          child:
              Icon(Icons.chevron_left_rounded, color: c.gold, size: 20)),
      );
}
