import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/quran_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/local/quran_bookmark_service.dart';
import '../../services/quran_api_service.dart';
import '../../models/quran_model.dart';
import 'quran_surah_list_screen.dart';
import 'quran_reader_screen.dart';

/// The Quran section:
///   • Read   — Arabic (Uthmani) + translation in the app language
///   • Listen — full-surah recitation (Mishary Alafasy) with a player bar
/// Lectures/tafsir videos live under Islamic Videos, not here.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final q = context.read<QuranProvider>();
      q.loadLastRead();
      q.loadSurahList();
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
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Row(children: [
              _BackBtn(c: c),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lang.tr('quran'), style: AppTextStyles.brandSmall(c)),
                  Text(lang.tr('quran_tab_sub'), style: AppTextStyles.brandTag(c)),
                ]),
              ),
              Text('القرآن الكريم',
                  textDirection: TextDirection.rtl,
                  style: surahNameStyle(c.gold2, size: 20)),
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
                border: Border.all(color: c.gold.withValues(alpha: 0.4)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              labelColor: c.gold,
              unselectedLabelColor: c.t2,
              labelStyle: AppTextStyles.pill(c, size: 12.5),
              unselectedLabelStyle: AppTextStyles.pill(c, size: 12.5, color: c.t2),
              tabs: [
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.menu_book_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(lang.tr('read_tab')),
                  ]),
                ),
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.headphones_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(lang.tr('listen_tab')),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_ReadTab(), _ListenTab()],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Read ────────────────────────────────────────────────────────────────────

class _ReadTab extends StatelessWidget {
  const _ReadTab();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    final quran = context.watch<QuranProvider>();

    return Column(children: [
      if (quran.bookmarkLoaded && quran.lastRead != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),
          child: _ContinueReadingCard(c: c, lang: lang, bookmark: quran.lastRead!),
        ),
      const Expanded(child: QuranSurahListScreen()),
    ]);
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.c, required this.lang, required this.bookmark});
  final AppColors c;
  final LanguageProvider lang;
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
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.goldSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.bookmark_rounded, color: c.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.tr('continue_reading'), style: AppTextStyles.pill(c, size: 10)),
                const SizedBox(height: 2),
                Text(
                  bookmark.surahName.isNotEmpty
                      ? '${lang.tr('surah')} ${bookmark.surahName} · ${lang.tr('ayah')} ${bookmark.ayahNumber}'
                      : '${lang.tr('ayah')} ${bookmark.ayahNumber}',
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

// ── Listen ──────────────────────────────────────────────────────────────────

class _ListenTab extends StatefulWidget {
  const _ListenTab();

  @override
  State<_ListenTab> createState() => _ListenTabState();
}

class _ListenTabState extends State<_ListenTab>
    with AutomaticKeepAliveClientMixin {
  final _player = AudioPlayer();
  SurahMeta? _current;
  String _query = '';
  bool _loadingTrack = false;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) _playNext();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(SurahMeta s) async {
    if (_current?.number == s.number) {
      _player.playing ? _player.pause() : _player.play();
      return;
    }
    setState(() {
      _current = s;
      _loadingTrack = true;
    });
    try {
      await _player.setUrl(QuranApiService.audioUrl(s.number));
      _player.play();
    } catch (e) {
      debugPrint('[Quran listen] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.read<LanguageProvider>().tr('audio_load_failed')),
        ));
      }
    } finally {
      if (mounted) setState(() => _loadingTrack = false);
    }
  }

  void _playNext() {
    final surahs = context.read<QuranProvider>().surahs;
    final cur = _current;
    if (cur == null || cur.number >= surahs.length) return;
    _play(surahs[cur.number]); // list is 0-based, numbers are 1-based
  }

  void _playPrev() {
    final surahs = context.read<QuranProvider>().surahs;
    final cur = _current;
    if (cur == null || cur.number <= 1) return;
    _play(surahs[cur.number - 2]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    final quran = context.watch<QuranProvider>();

    if (quran.surahs.isEmpty) {
      return Center(
        child: quran.isLoadingSurahs
            ? CircularProgressIndicator(color: c.gold)
            : TextButton(
                onPressed: () => quran.loadSurahList(forceRefresh: true),
                child: Text(lang.tr('retry'), style: TextStyle(color: c.gold)),
              ),
      );
    }

    final q = _query.toLowerCase();
    final list = q.isEmpty
        ? quran.surahs
        : quran.surahs
            .where((s) =>
                s.englishName.toLowerCase().contains(q) ||
                s.englishNameTranslation.toLowerCase().contains(q) ||
                '${s.number}' == q)
            .toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.goldSurface,
              border: Border.all(color: c.gold.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.mic_external_on_rounded, color: c.gold, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mishary Rashid Alafasy', style: AppTextStyles.label(c, size: 13.5)),
              Text(lang.tr('reciter'), style: AppTextStyles.bodyMuted(c, size: 11)),
            ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
        child: TextField(
          onChanged: (v) => setState(() => _query = v.trim()),
          style: AppTextStyles.body(c, size: 14),
          decoration: InputDecoration(
            hintText: lang.tr('search_surah'),
            hintStyle: AppTextStyles.bodyMuted(c, size: 13),
            prefixIcon: Icon(Icons.search_rounded, color: c.t3, size: 20),
            filled: true,
            fillColor: c.surf,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.bd),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.bd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.gold),
            ),
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final s = list[i];
            final isCurrent = _current?.number == s.number;
            final playing = isCurrent && _player.playing;
            return InkWell(
              onTap: () => _play(s),
              child: Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrent ? c.goldSurface : c.surf,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isCurrent ? c.gold.withValues(alpha: 0.5) : c.bd),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 30,
                    child: Text('${s.number}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.pill(c, size: 12)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.englishName, style: AppTextStyles.label(c, size: 14)),
                        Text('${s.englishNameTranslation} · ${s.numberOfAyahs} ${lang.tr('ayahs')}',
                            style: AppTextStyles.bodyMuted(c, size: 10.5)),
                      ],
                    ),
                  ),
                  Text(s.name,
                      textDirection: TextDirection.rtl,
                      style: surahNameStyle(c.gold2, size: 16)),
                  const SizedBox(width: 10),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: playing ? c.gold : Colors.transparent,
                      border: Border.all(color: c.gold.withValues(alpha: 0.6)),
                    ),
                    child: isCurrent && _loadingTrack
                        ? Padding(
                            padding: const EdgeInsets.all(9),
                            child: CircularProgressIndicator(strokeWidth: 2, color: c.gold),
                          )
                        : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: playing ? c.bg : c.gold, size: 20),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
      if (_current != null) _PlayerBar(
        c: c,
        player: _player,
        surah: _current!,
        onNext: _playNext,
        onPrev: _playPrev,
      ),
    ]);
  }
}

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({
    required this.c,
    required this.player,
    required this.surah,
    required this.onNext,
    required this.onPrev,
  });
  final AppColors c;
  final AudioPlayer player;
  final SurahMeta surah;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: c.bg2,
        border: Border(top: BorderSide(color: c.gold.withValues(alpha: 0.25))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${surah.number}. ${surah.englishName}',
                  style: AppTextStyles.label(c, size: 13.5),
                  overflow: TextOverflow.ellipsis),
              Text(surah.englishNameTranslation,
                  style: AppTextStyles.bodyMuted(c, size: 11)),
            ]),
          ),
          IconButton(
            icon: Icon(Icons.skip_previous_rounded, color: c.t1),
            onPressed: onPrev,
          ),
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (_, snap) {
              final playing = snap.data?.playing ?? false;
              return GestureDetector(
                onTap: () => playing ? player.pause() : player.play(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.goldGradient),
                  child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: const Color(0xFF1A1200), size: 26),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.skip_next_rounded, color: c.t1),
            onPressed: onNext,
          ),
        ]),
        StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (_, snap) {
            final pos = snap.data ?? Duration.zero;
            final total = player.duration ?? Duration.zero;
            final max = total.inMilliseconds.toDouble();
            return Row(children: [
              Text(_fmt(pos), style: GoogleFonts.inter(fontSize: 10.5, color: c.t3)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: c.gold,
                    inactiveTrackColor: c.bd2,
                    thumbColor: c.gold,
                  ),
                  child: Slider(
                    value: max <= 0 ? 0 : pos.inMilliseconds.clamp(0, max).toDouble(),
                    max: max <= 0 ? 1 : max,
                    onChanged: max <= 0
                        ? null
                        : (v) => player.seek(Duration(milliseconds: v.round())),
                  ),
                ),
              ),
              Text(_fmt(total), style: GoogleFonts.inter(fontSize: 10.5, color: c.t3)),
            ]);
          },
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
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.bd2)),
          child: Icon(Icons.chevron_left_rounded, color: c.gold, size: 22)),
      );
}
