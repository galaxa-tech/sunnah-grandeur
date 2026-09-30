import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/prayer_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/prayer_row.dart';
import '../prayer_tools/forbidden_times_screen.dart';
import 'package:intl/intl.dart';

class NamazScheduleScreen extends StatefulWidget {
  const NamazScheduleScreen({super.key});

  @override
  State<NamazScheduleScreen> createState() => _NamazScheduleScreenState();
}

class _NamazScheduleScreenState extends State<NamazScheduleScreen> {
  int _selectedDay = 0;
  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _days = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
  }

  PrayerRowState _rowState(DateTime? prayerTime, bool isToday, String nextPrayerName, String thisPrayer) {
    if (prayerTime == null) return PrayerRowState.upcoming;
    final now = DateTime.now();
    if (!isToday) {
      return prayerTime.isBefore(now) ? PrayerRowState.done : PrayerRowState.upcoming;
    }
    if (prayerTime.isBefore(now)) return PrayerRowState.done;
    if (thisPrayer == nextPrayerName) return PrayerRowState.active;
    return PrayerRowState.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final c          = AppColors.of(context);
    final prayer     = context.watch<PrayerProvider>();
    final selectedDate = _days[_selectedDay];
    final isToday    = _selectedDay == 0;
    final times      = prayer.timesForDate(selectedDate);
    final nextName   = prayer.getNextPrayerName();
    final fmt        = prayer.formatTime;
    final pos        = prayer.currentPosition;

    final locLabel = pos != null
        ? '${pos.latitude.toStringAsFixed(1)}°${pos.latitude >= 0 ? 'N' : 'S'} '
          '${pos.longitude.abs().toStringAsFixed(1)}°${pos.longitude >= 0 ? 'E' : 'W'}'
        : 'London (fallback)';

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
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Namaz Schedule', style: AppTextStyles.brandSmall(c)),
                  Text('$locLabel · ${DateFormat('EEEE').format(selectedDate)}',
                      style: AppTextStyles.brandTag(c)),
                ]),
              ),
              _IconBtn(icon: Icons.refresh_rounded, c: c,
                  onTap: () => prayer.init()),
            ]),
          ),

          // Day strip
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
              itemCount: _days.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _selectedDay = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _selectedDay == i
                        ? (c.isDark ? c.goldSurface : c.gold)
                        : (c.isDark ? c.surf : Colors.white),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: _selectedDay == i
                          ? (c.isDark ? c.gold.withValues(alpha: 0.22) : c.gold3)
                          : c.bd,
                    ),
                  ),
                  child: Column(children: [
                    Text(DateFormat('EEE').format(_days[i]).toUpperCase(),
                      style: AppTextStyles.cinzelSm(c,
                        color: _selectedDay == i
                            ? (c.isDark ? c.gold : Colors.white70) : c.t3,
                        size: 8,
                      ).copyWith(letterSpacing: 0.12 * 8),
                    ),
                    Text('${_days[i].day}',
                      style: AppTextStyles.heading(c,
                        color: _selectedDay == i
                            ? (c.isDark ? c.gold2 : Colors.white) : c.t2,
                        fontSize: 18,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          // Prayer list
          Expanded(
            child: prayer.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(children: [
                    PrayerRow(
                      name: 'Fajr',
                      time: fmt(times?.fajr),
                      state: _rowState(times?.fajr, isToday, nextName, 'Fajr'),
                    ),
                    PrayerRow(
                      name: 'Ishraq',
                      time: fmt(times?.sunrise),
                      state: PrayerRowState.optional,
                    ),
                    PrayerRow(
                      name: 'Dhuhr',
                      time: fmt(times?.dhuhr),
                      state: _rowState(times?.dhuhr, isToday, nextName, 'Dhuhr'),
                    ),
                    PrayerRow(
                      name: 'Asr',
                      time: fmt(times?.asr),
                      state: _rowState(times?.asr, isToday, nextName, 'Asr'),
                      badge: nextName == 'Asr' && isToday ? 'Now' : null,
                    ),
                    PrayerRow(
                      name: 'Maghrib',
                      time: fmt(times?.maghrib),
                      state: _rowState(times?.maghrib, isToday, nextName, 'Maghrib'),
                      badge: nextName == 'Maghrib' && isToday ? 'Now' : null,
                    ),
                    PrayerRow(
                      name: 'Isha',
                      time: fmt(times?.isha),
                      state: _rowState(times?.isha, isToday, nextName, 'Isha'),
                      badge: nextName == 'Isha' && isToday ? 'Now' : null,
                    ),

                    if (times != null) ...[
                      const SizedBox(height: 14),
                      Divider(color: c.bd),
                      const SizedBox(height: 14),
                      _ForbiddenTimesSection(c: c, times: times),
                      const SizedBox(height: 14),
                    ],
                  ]),
                ),
          ),
        ]),
      ),
    );
  }
}

// ── Forbidden Times ───────────────────────────────────────────────────────────
class _ForbiddenTimesSection extends StatelessWidget {
  const _ForbiddenTimesSection({required this.c, required this.times});
  final AppColors c;
  final PrayerTimes times;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('h:mm a');

    // Sunrise window: sunrise to sunrise+20min
    final sunriseEnd = times.sunrise.add(const Duration(minutes: 20));
    // Zawal: 18 min before dhuhr
    final zawalStart = times.dhuhr.subtract(const Duration(minutes: 18));
    // Sunset window: 20 min before maghrib
    final sunsetStart = times.maghrib.subtract(const Duration(minutes: 20));

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ForbiddenTimesScreen())),
      behavior: HitTestBehavior.opaque,
      child: Column(children: [
        Row(children: [
          Icon(Icons.block_outlined, color: c.red, size: 12),
          const SizedBox(width: 7),
          Text('FORBIDDEN PRAYER TIMES',
              style: AppTextStyles.cinzelSm(c, color: c.red, size: 8)
                  .copyWith(letterSpacing: 1.5)),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, color: c.t3, size: 16),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.red.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.red.withValues(alpha: 0.16)),
          ),
          child: Column(children: [
            _ForbiddenRow(c: c, name: 'Sunrise Window',
                sub: 'Ishraq · avoid prayer',
                time: '${fmt.format(times.sunrise)} – ${fmt.format(sunriseEnd)}'),
            const SizedBox(height: 9),
            _ForbiddenRow(c: c, name: 'Zawal Noon',
                sub: 'Before Dhuhr · 18 min',
                time: '${fmt.format(zawalStart)} – ${fmt.format(times.dhuhr)}'),
            const SizedBox(height: 9),
            _ForbiddenRow(c: c, name: 'Sunset Window',
                sub: 'Before Maghrib · 20 min',
                time: '${fmt.format(sunsetStart)} – ${fmt.format(times.maghrib)}'),
          ]),
        ),
      ]),
    );
  }
}

class _ForbiddenRow extends StatelessWidget {
  const _ForbiddenRow({required this.c, required this.name, required this.sub, required this.time});
  final AppColors c;
  final String name, sub, time;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: AppTextStyles.heading(c, fontSize: 15)),
          Text(sub,  style: AppTextStyles.bodyMuted(c, size: 9.5)),
        ]),
        Text(time, style: AppTextStyles.heading(c, fontSize: 13, color: c.red)),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.c});
  final AppColors c;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(width: 30, height: 30,
      decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.bd2)),
      child: Icon(Icons.chevron_left_rounded, color: c.gold, size: 20)),
  );
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.c, this.onTap});
  final IconData icon;
  final AppColors c;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 34, height: 34,
      decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.bd2)),
      child: Icon(icon, color: c.gold, size: 18)),
  );
}
