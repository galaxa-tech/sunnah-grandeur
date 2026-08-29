import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/video_row_item.dart';
import '../../providers/media_provider.dart';
import '../../models/video_model.dart';
import 'video_player_screen.dart';

class RuqyahScreen extends StatelessWidget {
  const RuqyahScreen({super.key});

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
                Text('Ruqyah', style: AppTextStyles.brandSmall(c)),
                Text('Healing · Protection · Evil Eye',
                    style: AppTextStyles.brandTag(c)),
              ]),
            ]),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: media.isLoadingRuqyah
                ? Center(child: CircularProgressIndicator(color: c.gold))
                : RefreshIndicator(
                    onRefresh: () => media.refreshType('ruqyah'),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(children: [
                        // Info banner
                        Container(
                          margin:
                              const EdgeInsets.fromLTRB(18, 8, 18, 12),
                          padding:
                              const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            color: c.red.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: c.red.withValues(alpha: 0.14)),
                          ),
                          child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.red.withValues(alpha: 0.10),
                                border: Border.all(
                                    color: c.red.withValues(alpha: 0.20)),
                              ),
                              child: Icon(Icons.info_outline_rounded,
                                  color: c.red, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Healing through the Quran',
                                      style: AppTextStyles.heading(c,
                                          fontSize: 14)),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Listen in a quiet place. Recitations are based on authentic Sunnah for healing and protection.',
                                    style: AppTextStyles.bodyMuted(c,
                                            size: 10)
                                        .copyWith(height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),

                        // Featured card
                        if (media.ruqyahMedia.isNotEmpty)
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => VideoPlayerScreen(
                                      video: media.ruqyahMedia.first)),
                            ),
                            child: _FeaturedCard(
                                c: c,
                                video: media.ruqyahMedia.first),
                          ),

                        const EyeRow(label: 'All Recitations'),

                        if (media.ruqyahMedia.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.healing_rounded,
                                    color: c.t3, size: 36),
                                const SizedBox(height: 12),
                                Text('No recitations available',
                                    style:
                                        AppTextStyles.bodyMuted(c)),
                                const SizedBox(height: 6),
                                Text(
                                    'Pull down to refresh or check your connection.',
                                    style: AppTextStyles.bodyMuted(c,
                                        size: 11),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),

                        ...media.ruqyahMedia.map((r) => VideoRowItem(
                              title: r.title,
                              author: r.author,
                              duration: r.duration,
                              views: r.views,
                              pillLabel: r.category,
                              pillVariant: 'red',
                              thumbColor:
                                  c.red.withValues(alpha: 0.05),
                              playIconColor: c.red,
                              thumbnailUrl:
                                  'https://img.youtube.com/vi/${r.youtubeId}/hqdefault.jpg',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          VideoPlayerScreen(video: r))),
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

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.c, required this.video});
  final AppColors c;
  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: c.red.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
              color: c.red.withValues(alpha: 0.09),
              blurRadius: 10)
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        SizedBox(
          height: 140,
          child: Stack(fit: StackFit.expand, children: [
            Image.network(
              'https://img.youtube.com/vi/${video.youtubeId}/hqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D0E08), Color(0xFF8B3828)],
                  ),
                ),
              ),
            ),
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
            Center(
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.38),
                      width: 1.5),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
            Positioned(
              bottom: 10, left: 14, right: 14,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('FEATURED',
                    style: AppTextStyles.cinzelSm(c,
                        color: const Color(0xFFFFAA9A), size: 8)
                        .copyWith(letterSpacing: 1.8)),
                const SizedBox(height: 3),
                Text(video.title,
                    style: AppTextStyles.heading(c,
                        color: Colors.white, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(video.duration,
                    style: AppTextStyles.bodyMuted(c, size: 8)
                        .copyWith(color: Colors.white)),
              ),
            ),
          ]),
        ),
        Container(
          color: c.isDark ? c.surf : Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          child: Row(children: [
            Text(video.author,
                style: AppTextStyles.body(c, size: 11)),
            const Spacer(),
            Text('${video.views} listens',
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
          child: Icon(Icons.chevron_left_rounded,
              color: c.gold, size: 20)),
      );
}
