import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Qibla Finder Screen with a fully custom-painted compass.
class QiblaFinderScreen extends StatefulWidget {
  const QiblaFinderScreen({super.key});

  @override
  State<QiblaFinderScreen> createState() => _QiblaFinderScreenState();
}

class _QiblaFinderScreenState extends State<QiblaFinderScreen> {
  Future<void>? _permissionFuture;

  @override
  void initState() {
    super.initState();
    _permissionFuture = _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    final locationStatus = await FlutterQiblah.checkLocationStatus();
    if (locationStatus.enabled &&
        (locationStatus.status == LocationPermission.denied ||
            locationStatus.status == LocationPermission.deniedForever)) {
      await FlutterQiblah.requestPermissions();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<Position?> _getPosition() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (kIsWeb) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Row(children: [
                _BackBtn(c: c),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Qibla Finder', style: AppTextStyles.brandSmall(c)),
                  Text('Mobile only', style: AppTextStyles.brandTag(c)),
                ])),
              ]),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.explore_outlined, color: c.gold, size: 56),
                    const SizedBox(height: 20),
                    Text('Compass Not Available', style: AppTextStyles.heading(c, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(
                      'The Qibla compass requires device motion sensors.\nPlease use the Sunnah Grandeur mobile app.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted(c, size: 13),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );
    }

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
                child: FutureBuilder<Position?>(
                  future: _getPosition(),
                  builder: (context, posSnap) {
                    final pos = posSnap.data;
                    final locText = pos != null
                        ? '${pos.latitude.toStringAsFixed(1)}°${pos.latitude >= 0 ? 'N' : 'S'} ${pos.longitude.toStringAsFixed(1)}°${pos.longitude >= 0 ? 'E' : 'W'}'
                        : 'Fetching location...';

                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Qibla Finder', style: AppTextStyles.brandSmall(c)),
                      Text(locText, style: AppTextStyles.brandTag(c)),
                    ]);
                  }
                ),
              ),
            ]),
          ),

          Expanded(
            child: FutureBuilder(
              future: _permissionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: c.gold));
                }
                return StreamBuilder(
                  stream: FlutterQiblah.qiblahStream,
                  builder: (context, AsyncSnapshot<QiblahDirection> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: c.gold));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}", style: AppTextStyles.body(c)));
                    }

                    final qiblahDirection = snapshot.data!;
                    
                    return SingleChildScrollView(
                      child: Column(children: [
                        const SizedBox(height: 10),
                        // Animated compass
                        Transform.rotate(
                          angle: (qiblahDirection.direction * (math.pi / 180) * -1),
                          child: CustomPaint(
                            size: const Size(310, 310),
                            painter: _CompassPainter(
                              qiblaBearing: qiblahDirection.qiblah,
                              c: c,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Stats card
                        _StatsCard(
                          c: c, 
                          bearing: qiblahDirection.qiblah.toStringAsFixed(0),
                          offset: qiblahDirection.offset.toStringAsFixed(0),
                        ),
                        const SizedBox(height: 14),

                        // Quran quote
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Text(
                            '"Turn your face toward al-Masjid al-Haram. And wherever you are, turn your faces toward it."\n\n— Al-Baqarah 2:144',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.italic(c, fontSize: 13.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Compass Painter ─────────────────────────────────────────────────────────
class _CompassPainter extends CustomPainter {
  const _CompassPainter({required this.qiblaBearing, required this.c});
  final double qiblaBearing; // degrees from North
  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.32; // compass ring radius ~100/310

    // ── Atmosphere rings
    _drawRing(canvas, cx, cy, size.width * 0.499, c.gold.withValues(alpha: 0.07));
    _drawRing(canvas, cx, cy, size.width * 0.476, c.gold.withValues(alpha: 0.04));

    // ── Compass disc
    final discPaint = Paint()
      ..color = c.isDark ? const Color(0xD00A0A0C) : const Color(0x4CE8DABC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, discPaint);
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()
          ..color = c.gold.withValues(alpha: c.isDark ? 0.22 : 0.26)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
    canvas.drawCircle(Offset(cx, cy), r * 0.94,
        Paint()
          ..color = c.gold.withValues(alpha: c.isDark ? 0.07 : 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6);

    // ── Tick marks
    _drawTicks(canvas, cx, cy, r);

    // ── Cardinal labels
    _drawCardinals(canvas, cx, cy, r);

    // ── Kaaba (outside ring at bearing 243°)
    _drawKaaba(canvas, cx, cy, r);

    // ── Dashed guide line
    _drawDashedLine(canvas, cx, cy, r);

    // ── Needle (Static in this frame, as the whole CustomPaint rotates)
    _drawNeedle(canvas, cx, cy, r);

    // ── Center pivot
    canvas.drawCircle(Offset(cx, cy), 9,
        Paint()..color = c.isDark ? const Color(0xFF1A1A1C) : const Color(0xFFEDE7D8));
    canvas.drawCircle(Offset(cx, cy), 9,
        Paint()
          ..color = c.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    canvas.drawCircle(Offset(cx, cy), 4,
        Paint()..color = c.gold.withValues(alpha: 0.92));
  }

  void _drawRing(Canvas canvas, double cx, double cy, double r, Color color) {
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  void _drawTicks(Canvas canvas, double cx, double cy, double r) {
    final majorPaint = Paint()
      ..color = c.gold.withValues(alpha: c.isDark ? 0.30 : 0.34)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final minorPaint = Paint()
      ..color = c.gold.withValues(alpha: c.isDark ? 0.15 : 0.16)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;

    // Cardinal at 0°, 90°, 180°, 270°
    for (final deg in [0.0, 90.0, 180.0, 270.0]) {
      final rad = deg * math.pi / 180;
      final inner = r * 0.76;
      canvas.drawLine(
        Offset(cx + inner * math.sin(rad), cy - inner * math.cos(rad)),
        Offset(cx + r    * math.sin(rad), cy - r    * math.cos(rad)),
        majorPaint,
      );
    }
    // Inter-cardinal at 45°, 135°, 225°, 315°
    for (final deg in [45.0, 135.0, 225.0, 315.0]) {
      final rad = deg * math.pi / 180;
      final inner = r * 0.81;
      canvas.drawLine(
        Offset(cx + inner * math.sin(rad), cy - inner * math.cos(rad)),
        Offset(cx + r    * math.sin(rad), cy - r    * math.cos(rad)),
        minorPaint,
      );
    }
  }

  void _drawCardinals(Canvas canvas, double cx, double cy, double r) {
    final style = GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w700, color: c.gold,
      letterSpacing: 1.0,
    );
    final mutedStyle = GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w400,
      color: c.gold.withValues(alpha: 0.38),
    );

    _drawText(canvas, 'N', cx, cy - r * 1.17, style);
    _drawText(canvas, 'S', cx, cy + r * 1.17, mutedStyle);
    _drawText(canvas, 'W', cx - r * 1.17, cy, mutedStyle);
    _drawText(canvas, 'E', cx + r * 1.17, cy, mutedStyle);
  }

  void _drawText(Canvas canvas, String text, double x, double y, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  void _drawNeedle(Canvas canvas, double cx, double cy, double r) {
    const bearingRad = 0.0; // Point North always in its own frame 

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(bearingRad);

    // Upper pointer (gold gradient)
    final upperPath = Path()
      ..moveTo(0, -r * 0.92)
      ..lineTo(-8, 8)
      ..lineTo(0, 24)
      ..lineTo(8, 8)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: c.isDark
          ? [const Color(0xFFF0D488), c.gold, c.gold3]
          : [const Color(0xFFD4A830), c.gold, c.gold3],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromLTWH(-8, -r * 0.92, 16, r * 0.92 + 24));

    canvas.drawPath(upperPath,
        Paint()..shader = gradient..style = PaintingStyle.fill);

    // Lower counter-pointer (dark)
    final lowerPath = Path()
      ..moveTo(0, 24)
      ..lineTo(-6, 8)
      ..lineTo(0, -10)
      ..lineTo(6, 8)
      ..close();
    canvas.drawPath(lowerPath,
        Paint()..color = c.isDark
            ? const Color(0xBF282420)
            : Colors.black.withValues(alpha: 0.35));

    canvas.restore();
  }

  void _drawKaaba(Canvas canvas, double cx, double cy, double r) {
    final bearingRad = qiblaBearing * math.pi / 180.0;
    final kDist = r * 1.38;
    final kx = cx + kDist * math.sin(bearingRad);
    final ky = cy - kDist * math.cos(bearingRad);

    // Glow halos
    canvas.drawCircle(Offset(kx, ky), 30,
        Paint()
          ..color = c.gold.withValues(alpha: c.isDark ? 0.12 : 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    canvas.drawCircle(Offset(kx, ky), 23,
        Paint()
          ..color = c.gold.withValues(alpha: c.isDark ? 0.07 : 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9);

    // Kaaba body
    final kRect = Rect.fromCenter(
        center: Offset(kx, ky), width: 28, height: 28);
    final rr = RRect.fromRectAndRadius(kRect, const Radius.circular(3.5));
    canvas.drawRRect(rr,
        Paint()..color = c.isDark ? const Color(0xFF060608) : Colors.white);
    canvas.drawRRect(rr,
        Paint()
          ..color = c.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);

    // Cloth bands
    final bandPaint = Paint()
      ..color = c.gold.withValues(alpha: 0.55)
      ..strokeWidth = 0.9;
    for (var offset in [-5.0, 0.0, 5.0]) {
      canvas.drawLine(
        Offset(kx - 12, ky + offset),
        Offset(kx + 12, ky + offset),
        bandPaint,
      );
    }

    // Door
    final doorRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(kx - 4, ky + 3, 8, 10), const Radius.circular(1.5));
    canvas.drawRRect(doorRect,
        Paint()..color = c.gold.withValues(alpha: 0.15));
    canvas.drawRRect(doorRect,
        Paint()
          ..color = c.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1);

    // QIBLA label
    _drawText(canvas, 'QIBLA', kx, ky + 20,
        GoogleFonts.inter(
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
          color: c.gold.withValues(alpha: 0.80),
          letterSpacing: 1.2,
        ));
  }

  void _drawDashedLine(Canvas canvas, double cx, double cy, double r) {
    final bearingRad = qiblaBearing * math.pi / 180.0;
    // Ring edge at 243°
    final x1 = cx + r    * math.sin(bearingRad);
    final y1 = cy - r    * math.cos(bearingRad);
    // Kaaba edge (r=138/155 * size.width/2)
    final kDist = r * 1.38;
    final x2 = cx + (kDist - 14) * math.sin(bearingRad);
    final y2 = cy - (kDist - 14) * math.cos(bearingRad);

    final paint = Paint()
      ..color = c.gold.withValues(alpha: 0.20)
      ..strokeWidth = 1;

    const dashLen = 3.0;
    const gapLen  = 3.5;
    final dx = x2 - x1, dy = y2 - y1;
    final len = math.sqrt(dx * dx + dy * dy);
    final steps = (len / (dashLen + gapLen)).floor();
    final ux = dx / len, uy = dy / len;

    for (var i = 0; i < steps; i++) {
      final t0 = i * (dashLen + gapLen);
      final t1 = t0 + dashLen;
      canvas.drawLine(
        Offset(x1 + ux * t0, y1 + uy * t0),
        Offset(x1 + ux * t1, y1 + uy * t1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.qiblaBearing != qiblaBearing || old.c != c;
}

// ── Stats card ────────────────────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.c, required this.bearing, required this.offset});
  final AppColors c;
  final String bearing;
  final String offset;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: c.goldCardDecoration,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _StatCell(c: c, label: 'Qibla',   value: '$bearing°', sub: 'From North'),
        Container(width: 1, height: 56, color: c.gold.withValues(alpha: 0.16)),
        _StatCell(c: c, label: 'Offset',  value: '$offset°',  sub: 'Relative'),
        Container(width: 1, height: 56, color: c.gold.withValues(alpha: 0.16)),
        _StatCell(c: c, label: 'Accuracy', value: 'High',   sub: '±2°', valueColor: c.green),
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.c, required this.label,
      required this.value, required this.sub, this.valueColor});
  final AppColors c;
  final String label, value, sub;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label.toUpperCase(),
          style: AppTextStyles.cinzelSm(c, size: 8)),
      const SizedBox(height: 5),
      Text(value, style: AppTextStyles.displaySm(c,
          color: valueColor ?? c.gold)),
      const SizedBox(height: 2),
      Text(sub, style: AppTextStyles.bodyMuted(c, size: 9)),
    ]);
  }
}

// ── Back button ───────────────────────────────────────────────────────────────
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
