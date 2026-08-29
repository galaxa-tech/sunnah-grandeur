import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AlarmOnboardingScreen extends StatefulWidget {
  const AlarmOnboardingScreen({super.key});

  @override
  State<AlarmOnboardingScreen> createState() => _AlarmOnboardingScreenState();
}

class _AlarmOnboardingScreenState extends State<AlarmOnboardingScreen> {
  final Map<String, bool> _alarms = {
    'Fajr Alert (5:12 AM)':    true,
    'Sunrise Window (6:38 AM)': false,
    'Dhuhr Alert (12:08 PM)':  true,
    'Asr Alert (3:47 PM)':     true,
    'Maghrib Alert (6:22 PM)': true,
    'Isha Alert (7:48 PM)':    false,
  };

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            const SizedBox(height: 24),
            Text(lang.tr('app_name'), style: AppTextStyles.brand(c)),
            const SizedBox(height: 3),
            Text(lang.tr('tagline'), style: AppTextStyles.brandTag(c)),

            const SizedBox(height: 18),

            _AlarmIllustration(c: c),

            const SizedBox(height: 10),

            Text(lang.tr('enable_notifications'),
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMd(c)),
            const SizedBox(height: 4),
            Text(
              lang.tr('notifications_desc'),
              style: AppTextStyles.italic(c, fontSize: 12),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(lang.tr('prayer_alerts'),
                  style: AppTextStyles.label(c, size: 13)),
              _Toggle(
                value: _alarms.values.every((v) => v),
                c: c,
                onChanged: (val) => setState(() {
                  _alarms.updateAll((_, __) => val);
                }),
              ),
            ]),

            Divider(color: c.bd, height: 18),

            Expanded(
              child: ListView.separated(
                itemCount: _alarms.length,
                separatorBuilder: (_, __) => Divider(color: c.bd, height: 1),
                itemBuilder: (_, i) {
                  final name = _alarms.keys.elementAt(i);
                  final val  = _alarms.values.elementAt(i);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: (val ? c.gold : c.t3).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: (val ? c.gold : c.t3).withValues(alpha: 0.18)),
                        ),
                        child: Icon(Icons.alarm_outlined,
                            color: val ? c.gold : c.t3, size: 17),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name,
                          style: AppTextStyles.body(c, size: 13)
                              .copyWith(color: val ? c.t1 : c.t3))),
                      _Toggle(
                        value: val,
                        c: c,
                        onChanged: (v) => setState(() {
                          _alarms[name] = v;
                        }),
                      ),
                    ]),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            _GoldButton(
              label: '${lang.tr("enable_btn")} →',
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text(lang.tr('skip'),
                  style: AppTextStyles.bodyMuted(c, size: 11)),
            ),
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }
}

// ── Alarm clock illustration ──────────────────────────────────────────────────
class _AlarmIllustration extends StatelessWidget {
  const _AlarmIllustration({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: CustomPaint(
        size: const Size(90, 90),
        painter: _AlarmClockPainter(c: c),
      ),
    );
  }
}

class _AlarmClockPainter extends CustomPainter {
  const _AlarmClockPainter({required this.c});
  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2 + 6;
    final r = size.width * 0.34;
    final strokePaint = Paint()
      ..color = c.gold.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Face
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = c.gold.withValues(alpha: 0.08));
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = c.gold.withValues(alpha: 0.40)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8);
    canvas.drawCircle(Offset(cx, cy), r * 0.92,
        Paint()..color = c.gold.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7);

    // Hour ticks
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final isMajor = i % 3 == 0;
      final outerR = r * 0.88;
      final innerR = isMajor ? r * 0.72 : r * 0.80;
      canvas.drawLine(
        Offset(cx + outerR * math.sin(angle), cy - outerR * math.cos(angle)),
        Offset(cx + innerR * math.sin(angle), cy - innerR * math.cos(angle)),
        Paint()
          ..color = c.gold.withValues(alpha: isMajor ? 0.55 : 0.22)
          ..strokeWidth = isMajor ? 1.5 : 0.9
          ..strokeCap = StrokeCap.round,
      );
    }

    // Hands — show 5:12 AM
    const hourAngle    = (5 / 12 + 12 / 720) * 2 * math.pi - math.pi / 2;
    const minuteAngle  = (12 / 60) * 2 * math.pi - math.pi / 2;
    canvas.drawLine(Offset(cx, cy),
        Offset(cx + r * 0.50 * math.cos(hourAngle),
            cy + r * 0.50 * math.sin(hourAngle)), strokePaint);
    canvas.drawLine(Offset(cx, cy),
        Offset(cx + r * 0.68 * math.cos(minuteAngle),
            cy + r * 0.68 * math.sin(minuteAngle)), strokePaint);

    // Center dot
    canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = c.gold);

    // Bell bumps
    for (final offset in [-r * 0.6, r * 0.6]) {
      final bx = cx + offset;
      final by = cy - r * 0.85;
      canvas.drawArc(Rect.fromCenter(
          center: Offset(bx, by + 5.5), width: 16, height: 16),
          -math.pi * 0.9, math.pi * 0.8, false, strokePaint);
    }

    // Feet
    canvas.drawLine(Offset(cx - 12, cy + r), Offset(cx - 20, cy + r + 10), strokePaint);
    canvas.drawLine(Offset(cx + 12, cy + r), Offset(cx + 20, cy + r + 10), strokePaint);

    // Bell ring lines
    final rp = Paint()
      ..color = c.gold.withValues(alpha: 0.28)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (final i in [-1, 1]) {
      canvas.drawLine(Offset(cx + i * 36, cy - r * 0.10),
          Offset(cx + i * 44, cy - r * 0.30), rp);
      canvas.drawLine(Offset(cx + i * 40, cy + 0),
          Offset(cx + i * 50, cy + 0), rp);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Animated toggle ───────────────────────────────────────────────────────────
class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.c, required this.onChanged});
  final bool value;
  final AppColors c;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42, height: 24,
        decoration: BoxDecoration(
          color: value ? c.gold : c.bd2,
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gold button ───────────────────────────────────────────────────────────────
class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 48,
        decoration: BoxDecoration(
          gradient: c.goldGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
            color: c.gold.withValues(alpha: 0.28),
            blurRadius: 14, offset: const Offset(0, 4),
          )],
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.button(c)),
      ),
    );
  }
}
