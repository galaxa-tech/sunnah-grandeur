import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/hijri_converter.dart';

/// Hijri (Islamic lunar) calendar — self-contained local state, matching
/// the pattern of other single-purpose prayer tool screens in this app.
class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late final HijriDate _today;
  late HijriDate _viewedMonth; // day is irrelevant, only year/month matter

  @override
  void initState() {
    super.initState();
    _today = HijriDate.today();
    _viewedMonth = HijriDate(_today.year, _today.month, 1);
  }

  void _goToMonth(int delta) {
    setState(() => _viewedMonth = _viewedMonth.addMonths(delta));
  }

  void _goToToday() {
    setState(() => _viewedMonth = HijriDate(_today.year, _today.month, 1));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final todayGregorian = _today.toGregorian();

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
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hijri Calendar', style: AppTextStyles.heading(c, fontSize: 19)),
                  Text('ISLAMIC LUNAR CALENDAR', style: AppTextStyles.brandTag(c)),
                ],
              )),
              GestureDetector(
                onTap: _goToToday,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.isDark ? c.surf : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.bd2),
                  ),
                  child: Text('Today', style: AppTextStyles.bodyMuted(c, size: 10)),
                ),
              ),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              child: Column(children: [
                // Today hero card — Gregorian + Hijri side by side.
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: c.goldCardDecoration,
                  child: Column(children: [
                    Text('TODAY', style: AppTextStyles.brandTag(c)),
                    const SizedBox(height: 10),
                    Text(_today.toString(), style: AppTextStyles.displaySm(c).copyWith(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(todayGregorian),
                      style: AppTextStyles.bodyMuted(c, size: 11.5),
                    ),
                    if (_today.isRamadan || _today.isEid) ...[
                      const SizedBox(height: 10),
                      _EventChip(c: c, label: _today.isEid ? _today.eidLabel! : 'Ramadan Mubarak'),
                    ],
                  ]),
                ),

                // Month navigator
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _NavBtn(c: c, icon: Icons.chevron_left_rounded, onTap: () => _goToMonth(-1)),
                  Column(children: [
                    Text(_viewedMonth.monthName, style: AppTextStyles.heading(c, fontSize: 17)),
                    Text('${_viewedMonth.year} AH', style: AppTextStyles.bodyMuted(c, size: 10.5)),
                  ]),
                  _NavBtn(c: c, icon: Icons.chevron_right_rounded, onTap: () => _goToMonth(1)),
                ]),
                const SizedBox(height: 14),

                _MonthGrid(c: c, viewedMonth: _viewedMonth, today: _today),

                const SizedBox(height: 16),
                _LegendRow(c: c),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Month grid ───────────────────────────────────────────────────────────────
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.c, required this.viewedMonth, required this.today});

  final AppColors c;
  final HijriDate viewedMonth; // year/month of the month being viewed
  final HijriDate today;

  @override
  Widget build(BuildContext context) {
    final year = viewedMonth.year;
    final month = viewedMonth.month;
    final daysInMonth = HijriDate.daysInMonth(year, month);
    final firstOfMonth = HijriDate(year, month, 1);
    final firstGregorian = firstOfMonth.toGregorian();
    // DateTime.weekday: Mon=1 .. Sun=7. We want a Sunday-first grid
    // (leading blank cells) to match weekdayShortLabels.
    final leadingBlanks = firstGregorian.weekday % 7;

    final cells = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final hijri = HijriDate(year, month, day);
      final gregorian = hijri.toGregorian();
      final isToday = hijri.isSameDay(today);
      cells.add(_DayCell(c: c, hijri: hijri, gregorian: gregorian, isToday: isToday));
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.bd),
      ),
      child: Column(children: [
        Row(
          children: weekdayShortLabels
              .map((label) => Expanded(
                    child: Center(
                      child: Text(label, style: AppTextStyles.bodyMuted(c, size: 9.5)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 2,
          childAspectRatio: 0.82,
          children: cells,
        ),
      ]),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.c,
    required this.hijri,
    required this.gregorian,
    required this.isToday,
  });

  final AppColors c;
  final HijriDate hijri;
  final DateTime gregorian;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final isEid = hijri.isEid;
    final isRamadan = hijri.isRamadan;

    Color bg = Colors.transparent;
    Color border = Colors.transparent;
    Color numColor = c.t1;

    if (isToday) {
      bg = c.gold;
      border = c.gold;
      numColor = Colors.white;
    } else if (isEid) {
      bg = c.gold.withValues(alpha: 0.12);
      border = c.gold.withValues(alpha: 0.35);
      numColor = c.gold;
    } else if (isRamadan) {
      bg = c.green.withValues(alpha: 0.07);
      border = c.green.withValues(alpha: 0.20);
    }

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${hijri.day}',
              style: AppTextStyles.body(c, size: 13, weight: FontWeight.w600, color: numColor)),
          Text(DateFormat('d/M').format(gregorian),
              style: AppTextStyles.bodyMuted(c, size: 7.5)
                  .copyWith(color: isToday ? Colors.white70 : c.t3)),
          if (isEid && !isToday) ...[
            const SizedBox(height: 1),
            Icon(Icons.star_rounded, size: 8, color: c.gold),
          ] else if (isRamadan && !isToday) ...[
            const SizedBox(height: 1),
            Icon(Icons.nightlight_round, size: 7, color: c.green),
          ],
        ],
      ),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────
class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(c: c, color: c.gold, label: 'Today'),
        _LegendItem(c: c, color: c.gold.withValues(alpha: 0.4), icon: Icons.star_rounded, label: 'Eid'),
        _LegendItem(c: c, color: c.green.withValues(alpha: 0.5), icon: Icons.nightlight_round, label: 'Ramadan'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.c, required this.color, required this.label, this.icon});
  final AppColors c;
  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = icon; // local var so the null-check below promotes it
    return Row(mainAxisSize: MainAxisSize.min, children: [
      iconData != null
          ? Icon(iconData, size: 12, color: color)
          : Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 5),
      Text(label, style: AppTextStyles.bodyMuted(c, size: 10)),
    ]);
  }
}

// ── Event chip (Ramadan / Eid banner on the hero card) ──────────────────────
class _EventChip extends StatelessWidget {
  const _EventChip({required this.c, required this.label});
  final AppColors c;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.gold.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: AppTextStyles.pill(c, size: 10)),
    );
  }
}

// ── Nav / back buttons ───────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.c, required this.icon, required this.onTap});
  final AppColors c;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: c.surf, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.bd2),
        ),
        child: Icon(icon, color: c.gold, size: 22),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: c.surf, borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.bd2),
        ),
        child: Icon(Icons.chevron_left_rounded, color: c.gold, size: 20),
      ),
    );
  }
}
