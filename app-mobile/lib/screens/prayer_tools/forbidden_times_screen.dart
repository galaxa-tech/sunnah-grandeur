import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/sg_pill.dart';

class ForbiddenTimesScreen extends StatelessWidget {
  const ForbiddenTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
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
                          const SgPill(label: 'New York · Mar 10', variant: 'gold', fontSize: 7.5),
                        ],
                      ),
                    ),

                    // Card 1: Sunrise
                    _ForbiddenCard(
                      idx: '01',
                      title: 'Sunrise Window',
                      sub: 'After Fajr · avoid prayer',
                      timeStart: '6:38',
                      timeEnd: 'to 7:08 AM',
                      duration: 'Duration: 30 min',
                      isPassed: true,
                      c: c,
                    ),

                    // Card 2: Zawal
                    _ForbiddenCard(
                      idx: '02',
                      title: 'Zawal · Solar Noon',
                      sub: 'Before Dhuhr begins',
                      timeStart: '11:50',
                      timeEnd: 'to 12:08 PM',
                      duration: 'Duration: 18 min',
                      isPassed: true,
                      c: c,
                    ),

                    // Card 3: Sunset (Upcoming - golden)
                    _ForbiddenCard(
                      idx: '03 · Upcoming',
                      title: 'Sunset Window',
                      sub: 'Before Maghrib · avoid prayer',
                      timeStart: '6:02',
                      timeEnd: 'to 6:22 PM',
                      duration: 'Duration: 20 min · in 2h 15m',
                      isPassed: false,
                      isUpcoming: true,
                      c: c,
                    ),

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
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
