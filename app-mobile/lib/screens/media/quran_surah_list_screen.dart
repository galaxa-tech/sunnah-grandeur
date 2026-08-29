import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../providers/quran_provider.dart';
import '../../models/quran_model.dart';
import 'quran_reader_screen.dart';

/// Lists all 114 surahs of the Quran. Tapping one opens [QuranReaderScreen]
/// with its Arabic text and English translation.
class QuranSurahListScreen extends StatefulWidget {
  const QuranSurahListScreen({super.key});

  @override
  State<QuranSurahListScreen> createState() => _QuranSurahListScreenState();
}

class _QuranSurahListScreenState extends State<QuranSurahListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuranProvider>().loadSurahList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final quran = context.watch<QuranProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => quran.loadSurahList(forceRefresh: true),
          child: _buildBody(c, quran),
        ),
      ),
    );
  }

  Widget _buildBody(AppColors c, QuranProvider quran) {
    if (quran.isLoadingSurahs && quran.surahs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quran.surahsError != null && quran.surahs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Column(children: [
              Icon(Icons.wifi_off_rounded, color: c.t3, size: 40),
              const SizedBox(height: 14),
              Text(quran.surahsError!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted(c)),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () => quran.loadSurahList(forceRefresh: true),
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

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: quran.surahs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const EyeRow(label: '114 Surahs');
        }
        final surah = quran.surahs[index - 1];
        return _SurahRow(
          c: c,
          surah: surah,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => QuranReaderScreen(surahNumber: surah.number)),
          ),
        );
      },
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({required this.c, required this.surah, required this.onTap});
  final AppColors c;
  final SurahMeta surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: c.surfaceCardDecoration,
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.goldSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.gold.withOpacity(0.25)),
            ),
            child: Text('${surah.number}',
                style: AppTextStyles.pill(c, size: 11)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(surah.englishName,
                    style: AppTextStyles.label(c, size: 14)),
                const SizedBox(height: 2),
                Text(
                    '${surah.englishNameTranslation} · ${surah.numberOfAyahs} ayahs',
                    style: AppTextStyles.bodyMuted(c, size: 10.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(surah.name,
                style: AppTextStyles.heading(c, color: c.gold2, fontSize: 17)),
          ),
        ]),
      ),
    );
  }
}
