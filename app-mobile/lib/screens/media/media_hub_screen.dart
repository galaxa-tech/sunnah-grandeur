import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    _debounce = Timer(const Duration(milliseconds: 300), () {
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
    return [...media.videos, ...media.ruqyahMedia]
        .where((v) =>
            v.title.toLowerCase().contains(_query) ||
            v.category.toLowerCase().contains(_query) ||
            v.author.toLowerCase().contains(_query))
        .take(20)
        .toList();
  }

  void _open(VideoModel v) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: v)));

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
                          hintText: lang.tr('search_media_hint'),
                          hintStyle: AppTextStyles.bodyMuted(c, size: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _IconBtn(icon: Icons.close_rounded, c: c, color: c.t3, onTap: _toggleSearch),
                  ])
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(lang.tr('media'), style: AppTextStyles.brand(c)),
                        Text(lang.tr('islamic_content_library'), style: AppTextStyles.brandTag(c)),
                      ]),
                      _IconBtn(icon: Icons.search_rounded, c: c, color: c.gold, onTap: _toggleSearch),
                    ],
                  ),
          ),

          Expanded(
            child: _searchOpen && _query.isNotEmpty
                ? _buildSearchResults(c, lang, _results(media))
                : RefreshIndicator(
                    color: c.gold,
                    onRefresh: media.refreshAll,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20),
                      children: [
                        EyeRow(label: lang.tr('choose_section')),

                        // ── Islamic Videos — live thumbnails ─────────────
                        MediaSectionCard(
                          title:        lang.tr('islamic_videos'),
                          subtitle:     lang.tr('islamic_videos_sub'),
                          sectionLabel: lang.tr('section_01'),
                          badge: media.isLoadingVideos
                              ? '…'
                              : '${media.videos.length} ${lang.tr("videos")}',
                          categoryColor: const Color(0xFFE2C07A),
                          icon: Icons.play_arrow_rounded,
                          loading: media.isLoadingVideos,
                          previews: media.videos.take(3).map((v) => v.thumbnailHq).toList(),
                          artwork: const _CalligraphyArt(text: 'مرئيات إسلامية'),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2A1C05), Color(0xFF6B4C18), Color(0xFF8B6824)],
                          ),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const YoutubeFeedScreen())),
                        ),

                        // ── Quran — read & listen ────────────────────────
                        MediaSectionCard(
                          title:        lang.tr('quran'),
                          subtitle:     lang.tr('quran_sub'),
                          sectionLabel: lang.tr('section_02'),
                          badge:        lang.tr('surahs_114'),
                          categoryColor: const Color(0xFF6EE8A8),
                          icon: Icons.menu_book_rounded,
                          artwork: const _CalligraphyArt(text: 'القرآن الكريم', size: 46),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF082016), Color(0xFF1A5C3A), Color(0xFF2E7D52)],
                          ),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const QuranScreen())),
                        ),

                        // ── Ruqyah ───────────────────────────────────────
                        MediaSectionCard(
                          title:        lang.tr('ruqyah'),
                          subtitle:     lang.tr('ruqyah_sub'),
                          sectionLabel: lang.tr('section_03'),
                          badge: media.isLoadingRuqyah
                              ? '…'
                              : media.ruqyahMedia.isEmpty
                                  ? lang.tr('ruqyah_from_quran')
                                  : '${media.ruqyahMedia.length} ${lang.tr("recitations")}',
                          categoryColor: const Color(0xFFFFAA9A),
                          icon: Icons.healing_rounded,
                          loading: media.isLoadingRuqyah,
                          previews: media.ruqyahMedia.take(3).map((v) => v.thumbnailHq).toList(),
                          artwork: const _CalligraphyArt(text: 'الرقية الشرعية'),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2A0A05), Color(0xFF6B2018), Color(0xFF8B3828)],
                          ),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RuqyahScreen())),
                        ),

                        // ── Load failure (distinct from "nothing yet") ──
                        if (media.videosFailed || media.ruqyahFailed)
                          _ErrorBanner(
                            c: c,
                            message: lang.tr('media_load_failed'),
                            retryLabel: lang.tr('retry'),
                            onRetry: media.refreshAll,
                          ),

                        // ── Latest videos ────────────────────────────────
                        if (media.videos.isNotEmpty) ...[
                          EyeRow(label: lang.tr('latest_videos')),
                          ...media.videos.take(4).map((v) => VideoRowItem(
                                title:        v.title,
                                author:       v.author,
                                duration:     v.duration,
                                views:        v.views,
                                pillLabel:    v.category,
                                thumbnailUrl: v.thumbnailHq,
                                onTap: () => _open(v),
                              )),
                        ],
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSearchResults(AppColors c, LanguageProvider lang, List<VideoModel> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, color: c.t3, size: 42),
          const SizedBox(height: 12),
          Text(lang.tr('no_results'), style: AppTextStyles.bodyMuted(c)),
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
          thumbnailUrl: v.thumbnailHq,
          onTap: () => _open(v),
        );
      },
    );
  }
}

/// Designed cover for a section with no thumbnails: large faded Arabic
/// calligraphy over a subtle geometric grid, right-aligned.
class _CalligraphyArt extends StatelessWidget {
  const _CalligraphyArt({required this.text, this.size = 38});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      CustomPaint(painter: _StarGridPainter()),
      Align(
        alignment: const Alignment(0.85, -0.25),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiri(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.30),
            height: 1.2,
          ),
        ),
      ),
    ]);
  }
}

class _StarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const step = 34.0;
    for (double x = size.width * 0.35; x < size.width + step; x += step) {
      for (double y = -step / 2; y < size.height + step; y += step) {
        final r = Rect.fromCenter(center: Offset(x, y), width: 20, height: 20);
        canvas.drawRect(r, p);
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(0.785398);
        canvas.drawRect(const Rect.fromLTWH(-10, -10, 20, 20), p);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.c,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });
  final AppColors c;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: c.surf,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.bd),
        ),
        child: Row(children: [
          Icon(Icons.wifi_off_rounded, color: c.gold, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyles.bodyMuted(c, size: 12))),
          TextButton(
            onPressed: onRetry,
            child: Text(retryLabel, style: AppTextStyles.body(c, size: 12, color: c.gold)),
          ),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.c, required this.color, required this.onTap});
  final IconData icon;
  final AppColors c;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.bd2)),
          child: Icon(icon, color: color, size: 18),
        ),
      );
}
