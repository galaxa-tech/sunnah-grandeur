import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/video_row_item.dart';
import '../../providers/media_provider.dart';
import '../../models/video_model.dart';
import 'video_player_screen.dart';

class RuqyahScreen extends StatefulWidget {
  const RuqyahScreen({super.key});

  @override
  State<RuqyahScreen> createState() => _RuqyahScreenState();
}

class _RuqyahScreenState extends State<RuqyahScreen> {
  int _selected = 0;
  final List<String> _filters = ['All', 'General Ruqyah', 'Evil Eye', 'Sihr', 'Sleep'];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final media = context.watch<MediaProvider>();
    
    // Filter logic
    final displayedMedia = _selected == 0 
        ? media.ruqyahMedia 
        : media.ruqyahMedia.where((m) => m.category.toLowerCase() == _filters[_selected].toLowerCase()).toList();

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

          // Filter chips
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              itemCount: _filters.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selected == i
                        ? c.red
                        : (c.isDark ? c.surf : Colors.white),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: _selected == i ? c.red.withOpacity(0.7) : c.bd2),
                  ),
                  child: Text(_filters[i],
                      style: AppTextStyles.pill(c, size: 10,
                          color: _selected == i ? Colors.white : c.t3)),
                ),
              ),
            ),
          ),

          Expanded(
            child: media.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => media.refreshType('ruqyah'),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(children: [
                      // Info banner
                      Container(
                        margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          color: c.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.red.withOpacity(0.14)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.red.withOpacity(0.10),
                              border: Border.all(color: c.red.withOpacity(0.20)),
                            ),
                            child: Icon(Icons.info_outline_rounded,
                                color: c.red, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Healing through the Quran',
                                  style: AppTextStyles.heading(c, fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(
                                'Listen in a quiet place. Recitations are based on authentic Sunnah for healing and protection.',
                                style: AppTextStyles.bodyMuted(c, size: 10)
                                    .copyWith(height: 1.5),
                              ),
                            ],
                          )),
                        ]),
                      ),

                      // Featured card
                      if (displayedMedia.isNotEmpty)
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: displayedMedia.first))),
                          child: _FeaturedRuqyahCard(c: c, video: displayedMedia.first),
                        ),

                      const EyeRow(label: 'All Recitations'),

                      if (displayedMedia.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text('No recitations found in this category.', style: AppTextStyles.bodyMuted(c)),
                        ),

                      ...displayedMedia.map((r) => VideoRowItem(
                        title: r.title, author: r.author, duration: r.duration,
                        views: r.views, pillLabel: r.category, pillVariant: 'red',
                        thumbColor: c.red.withOpacity(0.05),
                        playIconColor: c.red,
                        thumbnailUrl: r.thumbnail,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: r))),
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

class _FeaturedRuqyahCard extends StatelessWidget {
  const _FeaturedRuqyahCard({required this.c, required this.video});
  final AppColors c;
  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.red.withOpacity(0.18)),
        boxShadow: [BoxShadow(color: c.red.withOpacity(0.09), blurRadius: 10)],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        Container(
          height: 130,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF3D0E08), Color(0xFF8B3828)],
            ),
          ),
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
                border: Border.all(color: Colors.white.withOpacity(0.38), width: 1.5),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 26),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    stops: [0, 0.7],
                    colors: [Color(0xA6000000), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Featured',
                    style: AppTextStyles.cinzelSm(c,
                        color: const Color(0xFFFFAA9A), size: 8)
                        .copyWith(letterSpacing: 0.22 * 8)),
                  const SizedBox(height: 3),
                  Text(video.title,
                    style: AppTextStyles.heading(c, color: Colors.white, fontSize: 17)),
                ]),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Text(video.author, style: AppTextStyles.body(c, size: 11)),
            const Spacer(),
            Text('${video.views} listens', style: AppTextStyles.bodyMuted(c, size: 10)),
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
