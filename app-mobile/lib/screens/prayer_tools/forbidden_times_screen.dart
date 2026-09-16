import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/location_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/sg_pill.dart';

// Conventional durations for the three makrooh windows. There is no single
// universally-fixed figure across madhahib — these match the common
// convention used by most prayer-time apps (~15 min after sunrise,
// ~10 min before Dhuhr, ~15 min before Maghrib).
const _kSunriseWindowMinutes = 15;
const _kZawalWindowMinutes = 10;
const _kSunsetWindowMinutes = 15;

class ForbiddenTimesScreen extends StatelessWidget {
  const ForbiddenTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final prayer = context.watch<PrayerProvider>();
    final location = context.watch<LocationProvider>();
    final times = prayer.prayerTimes;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Row(
                children: [
                   GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: c.bd2),
                      ),
                      child: Icon(Icons.arrow_back_ios_rounded, color: c.gold, size: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Forbidden Times', style: AppTextStyles.heading(c, fontSize: 19)),
                        Text('MAKROOH PRAYER WINDOWS', style: AppTextStyles.brandTag(c)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: times == null
                  ? Center(
                      child: Text(
                        prayer.isLoading ? 'Loading prayer times…' : 'Prayer times unavailable.',
                        style: AppTextStyles.bodyMuted(c, size: 13),
                      ),
                    )
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Builder(builder: (context) {
                  final sunriseStart = times.sunrise;
                  final sunriseEnd = sunriseStart.add(const Duration(minutes: _kSunriseWindowMinutes));
                  final zawalEnd = times.dhuhr;
                  final zawalStart = zawalEnd.subtract(const Duration(minutes: _kZawalWindowMinutes));
                  final sunsetEnd = times.maghrib;
                  final sunsetStart = sunsetEnd.subtract(const Duration(minutes: _kSunsetWindowMinutes));

                  final windows = [
                    (
                      idx: '01', title: 'Sunrise Window', sub: 'After Fajr · avoid prayer',
                      start: sunriseStart, end: sunriseEnd, durationLabel: '$_kSunriseWindowMinutes min',
                    ),
                    (
                      idx: '02', title: 'Zawal · Solar Noon', sub: 'Before Dhuhr begins',
                      start: zawalStart, end: zawalEnd, durationLabel: '$_kZawalWindowMinutes min',
                    ),
                    (
                      idx: '03', title: 'Sunset Window', sub: 'Before Maghrib · avoid prayer',
                      start: sunsetStart, end: sunsetEnd, durationLabel: '$_kSunsetWindowMinutes min',
                    ),
                  ];

                  return Column(
                    children: [
                      // Info banner
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.red.withValues(alpha: 0.16)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: c.red.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: c.red.withValues(alpha: 0.22)),
                              ),
                              child: Icon(Icons.info_outline_rounded, color: c.red, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('About Makrooh Times', style: AppTextStyles.displaySm(c).copyWith(fontSize: 14)),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Praying during these windows is disliked (makrooh) in Islamic jurisprudence. These times are based on your current location and today\'s prayer schedule.',
                                    style: AppTextStyles.bodyMuted(c, size: 10).copyWith(height: 1.55),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Text("TODAY'S WINDOWS", style: AppTextStyles.brandTag(c)),
                            const SizedBox(width: 10),
                            Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [c.gold.withValues(alpha: 0.2), Colors.transparent])))),
                            const SizedBox(width: 8),
                            SgPill(
                              label: '${location.locationLabel} · ${DateFormat('MMM d').format(now)}',
                              variant: 'gold',
                              fontSize: 7.5,
                            ),
                          ],
                        ),
                      ),

                      for (final w in windows) ...[
                        _ForbiddenCard(
                          idx: w.idx == '03' && now.isBefore(w.start) ? '${w.idx} · Upcoming' : w.idx,
                          title: w.title,
                          sub: w.sub,
                          timeStart: prayer.formatTime(w.start),
                          timeEnd: 'to ${prayer.formatTime(w.end)}',
                          duration: now.isBefore(w.start)
                              ? 'Duration: ${w.durationLabel} · in ${_countdown(now, w.start)}'
                              : 'Duration: ${w.durationLabel}',
                          isPassed: now.isAfter(w.end),
                          isUpcoming: now.isBefore(w.start),
                          c: c,
                        ),
                      ],

                      // Hadith reference
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: c.surf,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.bd),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SCHOLARLY REFERENCE', style: AppTextStyles.brandTag(c).copyWith(fontSize: 8, color: c.t3)),
                            const SizedBox(height: 8),
                            Text(
                              '"Three times at which the Messenger of Allah ﷺ forbade us to pray...at sunrise until the sun has risen...when it is directly overhead at noon until it has passed the meridian...when the sun turns yellow until it sets."',
                              style: AppTextStyles.italic(c, fontSize: 14).copyWith(height: 1.75),
                            ),
                            const SizedBox(height: 8),
                            Text('— Sahih Muslim 831 · Narrated by \'Uqbah ibn \'Amir', style: AppTextStyles.bodyMuted(c, size: 10)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _countdown(DateTime now, DateTime target) {
    final diff = target.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _ForbiddenCard extends StatelessWidget {
  const _ForbiddenCard({
    required this.idx, required this.title, required this.sub,
    required this.timeStart, required this.timeEnd, required this.duration,
    required this.isPassed, this.isUpcoming = false,
    required this.c,
  });
  final String idx, title, sub, timeStart, timeEnd, duration;
  final bool isPassed, isUpcoming;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final color = isUpcoming ? c.gold : c.red;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WINDOW $idx', style: AppTextStyles.brandTag(c).copyWith(fontSize: 8, color: color)),
                    const SizedBox(height: 6),
                    Text(title, style: AppTextStyles.displaySm(c).copyWith(fontSize: 20)),
                    const SizedBox(height: 3),
                    Text(sub, style: AppTextStyles.bodyMuted(c, size: 10.5)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(timeStart, style: AppTextStyles.displaySm(c).copyWith(fontSize: 18, color: color)),
                  Text(timeEnd, style: AppTextStyles.body(c, color: color, size: 9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Duration bar
          Container(
            height: 2,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(1),
            ),
            alignment: isPassed ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: isPassed ? 0.6 : 0.3,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: isUpcoming ? c.goldGradient : LinearGradient(colors: [c.red.withValues(alpha: 0.6), c.red.withValues(alpha: 0.3)]),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(duration, style: AppTextStyles.bodyMuted(c, size: 9.5)),
              SgPill(label: isPassed ? 'Passed today' : 'Upcoming', variant: isPassed ? 'red' : 'gold', fontSize: 7.5),
            ],
          ),
        ],
      ),
    );
  }
}
