import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/quran_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/quran_model.dart';

/// Arabic Quran text in the Amiri Quran typeface (designed for the Uthmani
/// script and its marks), falling back to Amiri / Noto Naskh.
TextStyle quranArabicStyle(Color color, {double size = 26}) =>
    GoogleFonts.amiriQuran(
      fontSize: size,
      color: color,
      height: 2.1,
    ).copyWith(fontFamilyFallback: [
      GoogleFonts.amiri().fontFamily!,
      GoogleFonts.notoNaskhArabic().fontFamily!,
    ]);

/// Surah names (e.g. "سُورَةُ البَقَرَةِ") — Amiri reads better than the
/// Quran face at small sizes.
TextStyle surahNameStyle(Color color, {double size = 18}) =>
    GoogleFonts.amiri(fontSize: size, color: color, fontWeight: FontWeight.w700, height: 1.4);

/// Reads one surah: Bismillah header, then each ayah (Arabic, right-to-left)
/// with its translation in the app language (Bangla or English). Records
/// the position for "Continue reading".
class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    this.scrollToAyah,
  });

  final int surahNumber;
  final int? scrollToAyah;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  double _arabicSize = 26;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _langCode => context.read<LanguageProvider>().langCode;

  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    final quran = context.read<QuranProvider>();
    final code = _langCode;
    await quran.loadSurah(widget.surahNumber, langCode: code, forceRefresh: force);
    if (!mounted) return;
    final detail = quran.cachedSurah(widget.surahNumber, langCode: code);
    if (detail != null) {
      await quran.markLastRead(
        surahNumber: detail.meta.number,
        surahName: detail.meta.englishName,
        ayahNumber: widget.scrollToAyah ?? 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    final quran = context.watch<QuranProvider>();
    final detail = quran.cachedSurah(widget.surahNumber, langCode: lang.langCode);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 10, 4),
            child: Row(children: [
              _BackBtn(c: c),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail?.meta.englishName ?? lang.tr('surah'),
                      style: AppTextStyles.brandSmall(c),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      detail != null
                          ? '${detail.meta.englishNameTranslation} · ${detail.meta.numberOfAyahs} ${lang.tr('ayahs')}'
                          : lang.tr('loading'),
                      style: AppTextStyles.brandTag(c),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'A−',
                icon: Icon(Icons.text_decrease_rounded, color: c.t2, size: 20),
                onPressed: () => setState(
                    () => _arabicSize = (_arabicSize - 2).clamp(18, 40)),
              ),
              IconButton(
                tooltip: 'A+',
                icon: Icon(Icons.text_increase_rounded, color: c.t2, size: 20),
                onPressed: () => setState(
                    () => _arabicSize = (_arabicSize + 2).clamp(18, 40)),
              ),
            ]),
          ),
          Expanded(child: _buildBody(c, lang, quran, detail)),
        ]),
      ),
    );
  }

  Widget _buildBody(AppColors c, LanguageProvider lang, QuranProvider quran,
      SurahDetail? detail) {
    if (detail == null && quran.isLoadingSurahDetail) {
      return Center(child: CircularProgressIndicator(color: c.gold));
    }

    if (detail == null && quran.surahDetailError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off_rounded, color: c.t3, size: 40),
            const SizedBox(height: 14),
            Text(quran.surahDetailError!,
                textAlign: TextAlign.center, style: AppTextStyles.bodyMuted(c)),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => _load(force: true),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.gold,
                side: BorderSide(color: c.gold.withValues(alpha: 0.4)),
              ),
              child: Text(lang.tr('retry')),
            ),
          ]),
        ),
      );
    }

    if (detail == null) return const SizedBox.shrink();

    final showBismillah = detail.meta.number != 1 && detail.meta.number != 9;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
      itemCount: detail.ayahs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SurahHeader(c: c, meta: detail.meta, showBismillah: showBismillah);
        }
        return _AyahCard(
          c: c,
          ayah: detail.ayahs[index - 1],
          arabicSize: _arabicSize,
        );
      },
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.c, required this.meta, required this.showBismillah});
  final AppColors c;
  final SurahMeta meta;
  final bool showBismillah;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2E1E), Color(0xFF1A5C3A), Color(0xFF2E7D52)],
        ),
        border: Border.all(color: c.gold.withValues(alpha: 0.35)),
      ),
      child: Column(children: [
        Text(meta.name,
            textDirection: TextDirection.rtl,
            style: surahNameStyle(const Color(0xFFF3DE9B), size: 26)),
        const SizedBox(height: 2),
        Text(
          '${meta.englishName} · ${meta.englishNameTranslation}',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        ),
        Text(
          meta.revelationType == 'Meccan' ? 'Makki' : 'Madani',
          style: GoogleFonts.inter(
              fontSize: 10.5, color: Colors.white54, letterSpacing: 1.2),
        ),
        if (showBismillah) ...[
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 6),
          Text(
            'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
            textDirection: TextDirection.rtl,
            style: quranArabicStyle(Colors.white, size: 24),
          ),
        ],
      ]),
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({required this.c, required this.ayah, required this.arabicSize});
  final AppColors c;
  final Ayah ayah;
  final double arabicSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: c.surfaceCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.goldSurface,
                border: Border.all(color: c.gold.withValues(alpha: 0.35)),
              ),
              child: Text('${ayah.numberInSurah}',
                  style: AppTextStyles.pill(c, size: 11)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            ayah.arabicText,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: quranArabicStyle(c.t1, size: arabicSize),
          ),
          if (ayah.translationText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              ayah.translationText,
              style: AppTextStyles.body(c, size: 14, color: c.t2)
                  .copyWith(height: 1.6),
            ),
          ],
        ],
      ),
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.bd2)),
          child: Icon(Icons.chevron_left_rounded, color: c.gold, size: 22),
        ),
      );
}
