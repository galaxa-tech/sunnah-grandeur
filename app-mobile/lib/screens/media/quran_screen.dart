import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/video_row_item.dart';
import '../../providers/media_provider.dart';
import '../../providers/quran_provider.dart';
import '../../services/local/quran_bookmark_service.dart';
import '../../models/video_model.dart';
import 'video_player_screen.dart';
import 'quran_surah_list_screen.dart';
import 'quran_reader_screen.dart';

/// The Quran section: a "Read" tab with the real Arabic Quran text plus
/// English translation, and a "Watch" tab with the existing YouTube
/// recitation videos (unchanged from before).
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuranProvider>().loadLastRead();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

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

          const SizedBox(height: 8),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.bd),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: c.goldSurface,
                border: Border.all(color: c.gold.withOpacity(0.4)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              labelColor: c.gold,
              unselectedLabelColor: c.t2,
              labelStyle: AppTextStyles.pill(c, size: 12),
              unselectedLabelStyle: AppTextStyles.pill(c, size: 12, color: c.t2),
              tabs: const [
                Tab(text: 'Read'),
                Tab(text: 'Watch'),
              ],
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ReadTab(),
                _WatchTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// "Read" tab — real Quran text: a Continue-reading entry point (when a
/// last-read bookmark exists) followed by the full surah list.
class _ReadTab extends StatelessWidget {
  const _ReadTab();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final quran = context.watch<QuranProvider>();

    return Column(children: [
      if (quran.bookmarkLoaded && quran.lastRead != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),
          child: _ContinueReadingCard(c: c, bookmark: quran.lastRead!),
        ),
      const Expanded(child: QuranSurahListScreen()),
    ]);
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.c, required this.bookmark});
  final AppColors c;
  final QuranBookmark bookmark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuranReaderScreen(
            surahNumber: bookmark.surahNumber,
            scrollToAyah: bookmark.ayahNumber,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: c.goldCardDecoration,
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.goldSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.menu_book_rounded, color: c.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Continue Reading', style: AppTextStyles.pill(c, size: 10)),
                const SizedBox(height: 2),
                Text(
                  bookmark.surahName.isNotEmpty
                      ? 'Surah ${bookmark.surahName} · Ayah ${bookmark.ayahNumber}'
                      : 'Ayah ${bookmark.ayahNumber}',
                  style: AppTextStyles.label(c, size: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.gold, size: 22),
        ]),
      ),
    );
  }
}

/// "Watch" tab — the existing YouTube Quran recitation list. Unchanged
/// from the previous QuranScreen implementation.
class _WatchTab extends StatelessWidget {
  const _WatchTab();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final media = context.watch<MediaProvider>();

    return media.isLoadingQuran
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
