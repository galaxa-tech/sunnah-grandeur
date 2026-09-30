import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The core ruqyah passages from the Quran that the Sunnah prescribes
/// (Al-Fatiha, Ayat al-Kursi, the last two ayat of Al-Baqarah, and the
/// three Quls), recited by Mishary Alafasy. Always available, so the
/// Ruqyah section is never empty even before admin-curated videos exist.
class QuranRuqyahList extends StatefulWidget {
  const QuranRuqyahList({super.key});

  @override
  State<QuranRuqyahList> createState() => _QuranRuqyahListState();
}

class _Passage {
  const _Passage(this.titleKey, this.ref, this.arabic, {this.surah, this.ayahs = const []});
  final String titleKey;
  final String ref;
  final String arabic;
  final int? surah;        // full-surah audio
  final List<int> ayahs;   // global ayah numbers (verse audio, played in order)

  List<Uri> get urls => surah != null
      ? [Uri.parse('https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$surah.mp3')]
      : ayahs
          .map((a) => Uri.parse('https://cdn.islamic.network/quran/audio/128/ar.alafasy/$a.mp3'))
          .toList();
}

const _passages = [
  _Passage('ruqyah_fatiha', '1', 'الفاتحة', surah: 1),
  _Passage('ruqyah_kursi', '2:255', 'آية الكرسي', ayahs: [262]),
  _Passage('ruqyah_baqarah_end', '2:285–286', 'خواتيم البقرة', ayahs: [292, 293]),
  _Passage('ruqyah_ikhlas', '112', 'الإخلاص', surah: 112),
  _Passage('ruqyah_falaq', '113', 'الفلق', surah: 113),
  _Passage('ruqyah_nas', '114', 'الناس', surah: 114),
];

class _QuranRuqyahListState extends State<QuranRuqyahList> {
  final _player = AudioPlayer();
  int? _current;
  bool _loading = false;
  StreamSubscription<PlayerState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        _player.stop();
        _current = null;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle(int i) async {
    if (_current == i) {
      _player.playing ? _player.pause() : _player.play();
      return;
    }
    setState(() {
      _current = i;
      _loading = true;
    });
    try {
      final urls = _passages[i].urls;
      if (urls.length == 1) {
        await _player.setUrl(urls.first.toString());
      } else {
        await _player.setAudioSource(ConcatenatingAudioSource(
            children: urls.map((u) => AudioSource.uri(u)).toList()));
      }
      _player.play();
    } catch (e) {
      debugPrint('[Ruqyah] $e');
      if (mounted) setState(() => _current = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    return Column(
      children: List.generate(_passages.length, (i) {
        final p = _passages[i];
        final active = _current == i;
        final playing = active && _player.playing;
        return GestureDetector(
          onTap: () => _toggle(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: active ? c.red.withValues(alpha: 0.08) : c.surf,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: active ? c.red.withValues(alpha: 0.35) : c.bd),
            ),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: playing ? c.red : c.red.withValues(alpha: 0.10),
                ),
                child: active && _loading
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.red),
                      )
                    : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: playing ? Colors.white : c.red, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lang.tr(p.titleKey), style: AppTextStyles.label(c, size: 14)),
                  Text('${lang.tr('quran')} ${p.ref}',
                      style: AppTextStyles.bodyMuted(c, size: 11)),
                ]),
              ),
              Text(p.arabic,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                      fontSize: 18, color: c.gold2, fontWeight: FontWeight.w700)),
            ]),
          ),
        );
      }),
    );
  }
}
