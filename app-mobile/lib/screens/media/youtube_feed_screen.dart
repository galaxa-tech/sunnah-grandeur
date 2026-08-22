import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/video_row_item.dart';
import '../../providers/media_provider.dart';
import '../../models/video_model.dart';
import 'video_player_screen.dart';

class YoutubeFeedScreen extends StatelessWidget {
  const YoutubeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
                Text('Islamic Videos', style: AppTextStyles.brandSmall(c)),
                Text('Curated YouTube Feed', style: AppTextStyles.brandTag(c)),
              ]),
            ]),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: media.isLoadingVideos
              ? const Center(child: CircularProgressIndicator())
              : media.videos.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.play_circle_outline_rounded, color: c.t3, size: 48),
                    const SizedBox(height: 12),
                    Text('No videos yet', style: AppTextStyles.bodyMuted(c)),
                    const SizedBox(height: 6),
                    Text('Videos will appear here once added.', style: AppTextStyles.bodyMuted(c, size: 11)),
                  ]))
                : SingleChildScrollView(
                  child: Column(children: [
                    // Highlighted video (using first video for now)
                    if (media.videos.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: media.videos.first))),
                        child: _FeaturedVideoCard(c: c, video: media.videos.first),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Feed List
                    ...media.videos.map((v) => VideoRowItem(
                      title: v.title, 
                      author: v.author, 
                      duration: v.duration,
                      views: v.views, 
                      pillLabel: v.category, 
                      pillVariant: 'gold',
                      thumbnailUrl: v.thumbnail,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: v))),
                    )),

                    const SizedBox(height: 10),
                  ]),
                ),
          ),
        ]),
      ),
    );
  }
}

class _FeaturedVideoCard extends StatelessWidget {
  const _FeaturedVideoCard({required this.c, required this.video});
  final AppColors c;
  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.gold.withOpacity(0.20)),
        boxShadow: [BoxShadow(color: c.gold.withOpacity(0.12), blurRadius: 12)],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        // Thumbnail area
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.surf,
            image: DecorationImage(image: NetworkImage(video.thumbnail), fit: BoxFit.cover),
          ),
          child: Stack(alignment: Alignment.center, children: [
            // Play button over red YouTube style bg
            Container(
              width: 58, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red.withOpacity(0.85),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ),
            // Duration badge
            Positioned(
              bottom: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(video.duration,
                  style: AppTextStyles.bodyMuted(c, size: 10)
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ),
          ]),
        ),
        // Meta info
        Container(
          color: c.isDark ? c.surf : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(video.title, style: AppTextStyles.heading(c, fontSize: 17)),
            const SizedBox(height: 4),
            Row(children: [
              Text(video.author, style: AppTextStyles.body(c, size: 12)),
              const Spacer(),
              Text('${video.views} views', style: AppTextStyles.bodyMuted(c, size: 10)),
            ]),
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
    child: Container(width: 30, height: 30,
      decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.bd2)),
      child: Icon(Icons.chevron_left_rounded, color: c.gold, size: 20)),
  );
}
