import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/media_section_card.dart';
import '../../widgets/video_row_item.dart';
import '../../providers/media_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/video_model.dart';
import 'quran_screen.dart';
import 'ruqyah_screen.dart';
import 'youtube_feed_screen.dart';
import 'video_player_screen.dart';

class MediaHubScreen extends StatefulWidget {
  const MediaHubScreen({super.key});

  @override
  State<MediaHubScreen> createState() => _MediaHubScreenState();
}

class _MediaHubScreenState extends State<MediaHubScreen> {
  bool   _searchOpen = false;
  String _query      = '';
  Timer? _debounce;
  final  _ctrl       = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = v.trim().toLowerCase());
    });
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) { _query = ''; _ctrl.clear(); }
    });
  }

  List<VideoModel> _results(MediaProvider media) {
    if (_query.isEmpty) return [];
    return [
      ...media.videos,
      ...media.quranMedia,
      ...media.ruqyahMedia,
    ].where((v) =>
        v.title.toLowerCase().contains(_query) ||
        v.category.toLowerCase().contains(_query) ||
        v.author.toLowerCase().contains(_query)).take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c     = AppColors.of(context);
    final lang  = context.watch<LanguageProvider>();
    final media = context.watch<MediaProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: _searchOpen
                ? Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        onChanged: _onQueryChanged,
                        style: AppTextStyles.body(c, size: 14),
                        decoration: InputDecoration(
                          hintText: 'Search videos, Quran, Ruqyah…',
                          hintStyle: AppTextStyles.bodyMuted(c, size: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _IconBtn(
                        icon: Icons.close_rounded,
                        c: c,
                        color: c.t3,
                        onTap: _toggleSearch),
                  ])
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(lang.tr('media'),
                            style: AppTextStyles.brand(c)),
                        Text(lang.tr('islamic_content_library'),
                            style: AppTextStyles.brandTag(c)),
                      ]),
                      _IconBtn(
                          icon: Icons.search_rounded,
                          c: c,
                          color: c.gold,
                          onTap: _toggleSearch),
                    ],
                  ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: _searchOpen && _query.isNotEmpty
                // Search results
                ? _buildSearchResults(c, _results(media), context)
                // Default hub
                : SingleChildScrollView(
                    child: Column(children: [
                      EyeRow(label: lang.tr('choose_section')),

                      // ── Islamic Videos ────────────────────────────
                      MediaSectionCard(
                        title:         lang.tr('islamic_videos'),
                        subtitle:      lang.tr('islamic_videos_sub'),
                        sectionLabel:  lang.tr('section_01'),
                        badge: media.isLoadingVideos
                            ? '…'
                            : '${media.videos.length} ${lang.tr("videos")}',
                        categoryColor: const Color(0xFFE2C07A),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3D2A08),
                            Color(0xFF6B4C18),
                            Color(0xFF8B6824)
                          ],
                          stops: [0.0, 0.4, 1.0],
                        ),
                        icon: Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.18),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 1.5),
                          ),
                          child: media.isLoadingVideos
                              ? const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white)
                              : const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 28),
                        ),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const YoutubeFeedScreen())),
                      ),

                      // ── Quran ─────────────────────────────────────
                      MediaSectionCard(
                        title:         lang.tr('quran'),
                        subtitle:      lang.tr('quran_sub'),
                        sectionLabel:  lang.tr('section_02'),
                        badge: media.isLoadingQuran
                            ? '…'
                            : '${media.quranMedia.length} ${lang.tr("surahs")}',
                        categoryColor: const Color(0xFF6EE8A8),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0D2E1E),
                            Color(0xFF1A5C3A),
                            Color(0xFF2E7D52)
                          ],
                          stops: [0.0, 0.4, 1.0],
                        ),
                        icon: Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withValues(alpha: 0.18),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.40),
                                width: 1.5),
                          ),
                          child: media.isLoadingQuran
                              ? const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white)
                              : const Icon(Icons.menu_book_rounded,
                                  color: Colors.white, size: 28),
                        ),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const QuranScreen())),
                      ),

                      // ── Ruqyah ────────────────────────────────────
                      MediaSectionCard(
                        title:         lang.tr('ruqyah'),
                        subtitle:      lang.tr('ruqyah_sub'),
                        sectionLabel:  lang.tr('section_03'),
                        badge: media.isLoadingRuqyah
                            ? '…'
                            : '${media.ruqyahMedia.length} ${lang.tr("recitations")}',
                        categoryColor: const Color(0xFFFFAA9A),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3D0E08),
                            Color(0xFF6B2018),
                            Color(0xFF8B3828)
                          ],
                          stops: [0.0, 0.4, 1.0],
                        ),
                        icon: Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withValues(alpha: 0.15),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.38),
                                width: 1.5),
                          ),
                          child: media.isLoadingRuqyah
                              ? const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white)
                              : const Icon(Icons.healing_rounded,
                                  color: Colors.white, size: 28),
                        ),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const RuqyahScreen())),
                      ),

                      // ── Trending preview ──────────────────────────
                      if (media.videos.isNotEmpty) ...[
                        EyeRow(label: lang.tr('trending_now')),
                        ...media.videos.take(2).map((v) => VideoRowItem(
                              title:        v.title,
                              author:       v.author,
                              duration:     v.duration,
                              views:        v.views,
                              pillLabel:    v.category,
                              thumbnailUrl:
                                  'https://img.youtube.com/vi/${v.youtubeId}/hqdefault.jpg',
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          VideoPlayerScreen(video: v))),
                            )),
                      ],

                      // ── Per-section error banners ─────────────────
                      if (!media.isLoading) ...[
                        if (media.videosError != null)
                          _ErrorBanner(c: c, message: media.videosError!,
                              onRetry: () => media.refreshType('video')),
                        if (media.quranError != null)
                          _ErrorBanner(c: c, message: media.quranError!,
                              onRetry: () => media.refreshType('quran')),
                        if (media.ruqyahError != null)
                          _ErrorBanner(c: c, message: media.ruqyahError!,
                              onRetry: () => media.refreshType('ruqyah')),
                      ],

                      const SizedBox(height: 16),
                    ]),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSearchResults(
      AppColors c, List<VideoModel> results, BuildContext ctx) {
    if (results.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, color: c.t3, size: 42),
          const SizedBox(height: 12),
          Text('No results found', style: AppTextStyles.bodyMuted(c)),
          const SizedBox(height: 6),
          Text('Try a different keyword.',
              style: AppTextStyles.bodyMuted(c, size: 11)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final v = results[i];
        return VideoRowItem(
          title:        v.title,
          author:       v.author,
          duration:     v.duration,
          views:        v.views,
          pillLabel:    v.category,
          thumbnailUrl:
              'https://img.youtube.com/vi/${v.youtubeId}/hqdefault.jpg',
          onTap: () => Navigator.push(ctx,
              MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(video: v))),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.c, required this.message, required this.onRetry});
  final AppColors c;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: c.surf,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.bd),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: c.gold, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodyMuted(c, size: 11)
                    .copyWith(height: 1.4)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: Text('Retry',
                style: AppTextStyles.body(c, size: 11, color: c.gold)),
          ),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn(
      {required this.icon,
      required this.c,
      required this.color,
      required this.onTap});
  final IconData icon;
  final AppColors c;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.bd2)),
          child: Icon(icon, color: color, size: 18),
        ),
      );
}
