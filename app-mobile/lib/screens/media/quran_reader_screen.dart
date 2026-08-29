import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/quran_provider.dart';
import '../../models/quran_model.dart';

/// Displays a single surah's ayahs — Arabic text (right-to-left) followed
/// by its English (Sahih International) translation — and records the
/// surah as the user's "last read" position for the Continue-reading entry
/// point on [QuranSurahListScreen]'s parent tab.
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final quran = context.read<QuranProvider>();
    await quran.loadSurah(widget.surahNumber);
    if (!mounted) return;
    final detail = quran.cachedSurah(widget.surahNumber);
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
    final quran = context.watch<QuranProvider>();
    final detail = quran.cachedSurah(widget.surahNumber);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail?.meta.englishName ?? 'Surah',
                      style: AppTextStyles.brandSmall(c),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      detail != null
                          ? '${detail.meta.englishNameTranslation} · ${detail.meta.revelationType} · ${detail.meta.numberOfAyahs} ayahs'
                          : 'Loading…',
                      style: AppTextStyles.brandTag(c),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (detail != null)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(detail.meta.name,
                      style: AppTextStyles.heading(c,
                          color: c.gold2, fontSize: 18)),
                ),
            ]),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody(c, quran, detail)),
        ]),
      ),
    );
  }

  Widget _buildBody(AppColors c, QuranProvider quran, SurahDetail? detail) {
    if (detail == null && quran.isLoadingSurahDetail) {
      return Center(child: CircularProgressIndicator(color: c.gold));
    }

    if (detail == null && quran.surahDetailError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Column(children: [
              Icon(Icons.wifi_off_rounded, color: c.t3, size: 40),
              const SizedBox(height: 14),
              Text(quran.surahDetailError!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted(c)),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () =>
                    quran.loadSurah(widget.surahNumber, forceRefresh: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.gold,
                  side: BorderSide(color: c.gold.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Retry'),
              ),
            ]),
          ),
        ],
      );
    }

    if (detail == null) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
      itemCount: detail.ayahs.length,
      itemBuilder: (context, index) {
        final ayah = detail.ayahs[index];
        return _AyahCard(c: c, ayah: ayah);
      },
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({required this.c, required this.ayah});
  final AppColors c;
  final Ayah ayah;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: c.surfaceCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.goldSurface,
                border: Border.all(color: c.gold.withOpacity(0.35)),
              ),
              child: Text('${ayah.numberInSurah}',
                  style: AppTextStyles.pill(c, size: 10)),
            ),
          ]),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              ayah.arabicText,
              textAlign: TextAlign.right,
              style: AppTextStyles.heading(c, fontSize: 22).copyWith(
                height: 1.9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ayah.translationText,
            style: AppTextStyles.body(c, size: 13, color: c.t2),
          ),
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
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: c.bd2)),
          child: Icon(Icons.chevron_left_rounded, color: c.gold, size: 20),
        ),
      );
}
