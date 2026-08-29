import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/dawah_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/profile_stats_provider.dart';
import '../../services/local/fasting_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/sg_pill.dart';
import '../prayer_tools/qibla_finder_screen.dart';
import '../prayer_tools/tasbeeh_screen.dart';
import '../prayer_tools/masjid_finder_screen.dart';
import '../prayer_tools/forbidden_times_screen.dart';
import '../prayer_tools/zakat_calculator_screen.dart';
import '../prayer_tools/hijri_calendar_screen.dart';
import 'namaz_schedule_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c     = AppColors.of(context);
    final lang  = context.watch<LanguageProvider>();
    final dawah = context.watch<DawahProvider>();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [

          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lang.tr('app_name'), style: AppTextStyles.brand(c)),
                  Text(lang.tr('tagline'), style: AppTextStyles.brandTag(c)),
                ]),
                Row(children: [
                  _IconBtn(
                    icon: Icons.location_on_outlined,
                    c: c,
                    onTap: () => Navigator.pushNamed(context, '/settings/location'),
                  ),
                  const SizedBox(width: 7),
                  Stack(children: [
                    _IconBtn(
                      icon: Icons.notifications_outlined,
                      c: c,
                      onTap: () => Navigator.pushNamed(context, '/settings/notifications'),
                    ),
                    Positioned(
                      top: 5, right: 6,
                      child: Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: c.red, shape: BoxShape.circle,
                          border: Border.all(color: c.bg, width: 1.5),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(children: [

                // ── Prayer Hero ────────────────────────────────────────────────
                _PrayerHeroCard(c: c),

                // ── Hadith of the Day ──────────────────────────────────────────
                EyeRow(
                  label: lang.tr('daily_inspiration'),
                  trailing: SgPill(label: lang.tr('hadith'), variant: 'gold'),
                ),
                dawah.isLoading
                  ? Center(child: Padding(padding: const EdgeInsets.all(20), child: CircularProgressIndicator(color: c.gold)))
                  : _HadithDailyCard(c: c, hadith: dawah.dailyHadith, lang: lang),

                // ── Sawm section ────────────────────────────────────────────────
                EyeRow(
                  label: lang.tr('sawm'),
                  trailing: SgPill(label: lang.tr('active'), variant: 'gold'),
                ),
                _SawmCard(lang: lang),

                // ── Quick Access ───────────────────────────────────────────────
                EyeRow(label: lang.tr('quick_access')),
                _QuickAccessGrid(c: c, lang: lang),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Prayer Hero Card ──────────────────────────────────────────────────────────
class _PrayerHeroCard extends StatefulWidget {
  const _PrayerHeroCard({required this.c});
  final AppColors c;

  @override
  State<_PrayerHeroCard> createState() => _PrayerHeroCardState();
}

class _PrayerHeroCardState extends State<_PrayerHeroCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c      = widget.c;
    final lang   = context.watch<LanguageProvider>();
    final prayer = context.watch<PrayerProvider>();

    if (prayer.isLoading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(18, 6, 18, 0),
        height: 140,
        decoration: c.goldCardDecoration,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final nextKey  = prayer.getNextPrayerName(); // lowercase translation key
    final nextName = lang.tr(nextKey);
    final nextTime = prayer.getNextPrayerTime();
    final timeStr  = nextTime != null ? DateFormat('h:mm a').format(nextTime) : '--:--';

    double progress = 0.0;
    String remaining = '--';
    if (nextTime != null) {
      final diff = nextTime.difference(DateTime.now());
      if (!diff.isNegative) {
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        remaining = h > 0 ? '${h}h ${m}m' : '${m}m';
        progress = 1.0 - (diff.inMinutes / 240).clamp(0.0, 1.0);
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 6, 18, 0),
      padding: const EdgeInsets.all(18),
      decoration: c.goldCardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lang.tr('next_prayer'), style: AppTextStyles.sectionLabel(c)),
        const SizedBox(height: 5),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
          Text(nextName, style: AppTextStyles.displayMd(c)),
          const SizedBox(width: 14),
          Text(timeStr,  style: AppTextStyles.displayLg(c)),
        ]),
        Text('${lang.tr("in")} $remaining', style: AppTextStyles.italic(c)),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LinearProgressIndicator(
            value: progress,
            color: c.gold,
            backgroundColor: c.bd,
            minHeight: 2,
          ),
        ),
        const SizedBox(height: 5),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(lang.tr('calculation_mwl'), style: AppTextStyles.bodyMuted(c, size: 9)),
          Text(nextName, style: AppTextStyles.pill(c, size: 9,
              color: c.gold).copyWith(fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}

// ── Hadith Daily Card ────────────────────────────────────────────────────────
class _HadithDailyCard extends StatelessWidget {
  const _HadithDailyCard({required this.c, this.hadith, required this.lang});
  final AppColors c;
  final dynamic hadith;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    if (hadith == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.isDark ? c.surf : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.bd),
        boxShadow: c.isDark ? null : [
          BoxShadow(color: const Color(0x0C644028), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: c.gold, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(hadith.title, style: AppTextStyles.heading(c, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hadith.content,
            style: AppTextStyles.body(c, size: 12).copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          Divider(color: c.bd, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hadith.source, style: AppTextStyles.bodyMuted(c, size: 10).copyWith(fontWeight: FontWeight.w500)),
              Text(lang.tr('added_today'), style: AppTextStyles.bodyMuted(c, size: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sawm Card ─────────────────────────────────────────────────────────────────
class _SawmCard extends StatefulWidget {
  const _SawmCard({required this.lang});
  final LanguageProvider lang;

  @override
  State<_SawmCard> createState() => _SawmCardState();
}

class _SawmCardState extends State<_SawmCard> {
  bool _fastedToday = false;

  // Legacy single-day keys from the old tracker (SharedPreferences-only,
  // single-day, no history). Read once on load so a day already marked
  // fasted under the old scheme isn't silently lost when the real
  // per-date FastingService takes over. Never written to again.
  static const _legacyKey     = 'sawm_fasted_today';
  static const _legacyDateKey = 'sawm_fasted_date';

  @override
  void initState() {
    super.initState();
    _loadFasted();
  }

  Future<void> _loadFasted() async {
    final today = DateTime.now();
    var fasted = await FastingService.isFastedOnDate(today);

    if (!fasted) {
      final prefs      = await SharedPreferences.getInstance();
      final legacyDate = prefs.getString(_legacyDateKey);
      final todayKey   = today.toIso8601String().substring(0, 10);
      if (legacyDate == todayKey && (prefs.getBool(_legacyKey) ?? false)) {
        fasted = true;
        await FastingService.setFasted(today, true);
      }
    }

    if (mounted) setState(() => _fastedToday = fasted);
  }

  Future<void> _toggleFasted() async {
    HapticFeedback.lightImpact();
    final next = !_fastedToday;
    setState(() => _fastedToday = next);
    await FastingService.setFasted(DateTime.now(), next);
    if (mounted) context.read<ProfileStatsProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c      = AppColors.of(context);
    final lang   = context.watch<LanguageProvider>();
    final prayer = context.watch<PrayerProvider>();
    final times  = prayer.prayerTimes;

    if (times == null) return const SizedBox.shrink();

    final sehri    = DateFormat('h:mm').format(times.fajr);
    final iftar    = DateFormat('h:mm').format(times.maghrib);
    final sehriSub = DateFormat('a').format(times.fajr);
    final iftarSub = DateFormat('a').format(times.maghrib);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: c.goldCardDecoration,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _TimeCell(c: c, label: lang.tr('sehri'),  time: sehri, sub: sehriSub),
            Container(width: 1, height: 50, color: c.gold.withValues(alpha: 0.18)),
            _TimeCell(c: c, label: lang.tr('iftar'),  time: iftar, sub: iftarSub),
            Container(width: 1, height: 50, color: c.gold.withValues(alpha: 0.18)),
            _TimeCell(c: c, label: lang.tr('today'),
                time: DateFormat('d').format(DateTime.now()),
                sub:  DateFormat('MMM').format(DateTime.now())),
          ]),
        ),
        GestureDetector(
          onTap: _toggleFasted,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _fastedToday
                  ? c.green.withValues(alpha: 0.12)
                  : (c.isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _fastedToday
                      ? c.green.withValues(alpha: 0.4)
                      : (c.isDark ? Colors.white : Colors.black).withValues(alpha: 0.14)),
            ),
            child: Row(children: [
              Icon(
                _fastedToday ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: _fastedToday ? c.green : c.t2,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(lang.tr('i_fasted_today'),
                  style: AppTextStyles.body(c,
                      size: 12,
                      color: _fastedToday ? c.green : c.t2)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({required this.c, required this.label,
      required this.time, required this.sub});
  final AppColors c;
  final String label, time, sub;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label.toUpperCase(), style: AppTextStyles.cinzelSm(c, size: 8.5)),
      const SizedBox(height: 4),
      Text(time, style: AppTextStyles.displaySm(c)),
      Text(sub,  style: AppTextStyles.bodyMuted(c, size: 8)),
    ]);
  }
}

// ── Quick Access Grid ─────────────────────────────────────────────────────────
class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.c, required this.lang});
  final AppColors c;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Column(children: [
        Row(children: [
          Expanded(child: _AccessCard(
            c: c, icon: Icons.calendar_month_outlined,
            title: lang.tr('namaz_schedule'), sub: lang.tr('five_prayer_times'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NamazScheduleScreen())),
          )),
          const SizedBox(width: 8),
          Expanded(child: _AccessCard(
            c: c, icon: Icons.block_outlined,
            title: lang.tr('forbidden_times'), sub: lang.tr('makrooh_windows'),
            iconColor: c.red,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ForbiddenTimesScreen())),
          )),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _AccessCard(
            c: c, icon: Icons.explore_outlined,
            title: lang.tr('qibla_finder'), sub: lang.tr('live_compass'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const QiblaFinderScreen())),
          )),
          const SizedBox(width: 8),
          Expanded(child: _AccessCard(
            c: c, icon: Icons.spa_outlined,
            title: lang.tr('tasbeeh'), sub: lang.tr('digital_dhikr'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TasbeehScreen())),
          )),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _AccessCard(
            c: c, icon: Icons.calculate_outlined,
            title: lang.tr('zakat_calculator'), sub: lang.tr('calculate_zakat_due'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen())),
          )),
          const SizedBox(width: 8),
          Expanded(child: _AccessCard(
            c: c, icon: Icons.calendar_today_outlined,
            title: lang.tr('hijri_calendar'), sub: lang.tr('islamic_lunar_dates'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HijriCalendarScreen())),
          )),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MasjidFinderScreen())),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: c.surfaceCardDecoration.copyWith(
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              _iconBox(c, Icons.mosque_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(lang.tr('masjid_finder'), style: AppTextStyles.label(c, size: 12)),
                  const SizedBox(height: 2),
                  Text(lang.tr('mosques_nearby'),
                      style: AppTextStyles.bodyMuted(c, size: 9.5)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: c.t3, size: 18),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _iconBox(AppColors c, IconData icon, {Color? iconColor}) {
    final col = iconColor ?? c.gold;
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: col, size: 18),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.c, required this.icon, required this.title, required this.sub,
    this.onTap, this.iconColor,
  });
  final AppColors c;
  final IconData icon;
  final String title, sub;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final col = iconColor ?? c.gold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: c.surfaceCardDecoration,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: col.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: col, size: 18),
          ),
          const SizedBox(height: 9),
          Text(title, style: AppTextStyles.label(c, size: 12)),
          const SizedBox(height: 2),
          Text(sub, style: AppTextStyles.bodyMuted(c, size: 9.5)),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.c, this.onTap});
  final IconData icon;
  final AppColors c;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: c.surf, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.bd2),
          boxShadow: [BoxShadow(color: const Color(0x0C644028), blurRadius: 3)],
        ),
        child: Icon(icon, color: c.gold, size: 18),
      ),
    );
  }
}
