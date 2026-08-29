import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_snackbar.dart';

class LocationOnboardingScreen extends StatefulWidget {
  const LocationOnboardingScreen({super.key});

  @override
  State<LocationOnboardingScreen> createState() => _LocationOnboardingScreenState();
}

class _LocationOnboardingScreenState extends State<LocationOnboardingScreen> {
  final _searchCtrl = TextEditingController();
  List<CityResult> _suggestions = [];
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q, LocationProvider loc) {
    setState(() => _suggestions = loc.searchCities(q));
  }

  Future<void> _useGps(LocationProvider loc) async {
    final ok = await loc.useCurrentLocation();
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/onboard/alarms');
    } else if (loc.error != null) {
      showAppSnackbar(context, loc.error!,
          type: AppSnackbarType.error, duration: const Duration(seconds: 3));
    }
  }

  void _pickCity(CityResult city, LocationProvider loc) async {
    await loc.setManualLocation(city.lat, city.lng, city.displayName);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboard/alarms');
  }

  @override
  Widget build(BuildContext context) {
    final c   = AppColors.of(context);
    final loc = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            const SizedBox(height: 24),
            Text('Sunnah Grandeur', style: AppTextStyles.brand(c)),
            const SizedBox(height: 3),
            Text('Living the Prophetic Way', style: AppTextStyles.brandTag(c)),

            const SizedBox(height: 20),

            // Mosque illustration
            Flexible(
              child: AspectRatio(
                aspectRatio: 1.1,
                child: CustomPaint(painter: _MosquePainter(c: c)),
              ),
            ),

            const SizedBox(height: 12),

            Text('Accurate Prayer Times',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMd(c)),
            const SizedBox(height: 5),
            Text(
              'Grant location access to receive precise\nprayer times and Qibla direction.',
              style: AppTextStyles.italic(c, fontSize: 12.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // ── GPS card ────────────────────────────────────────────────────
            GestureDetector(
              onTap: loc.isLoading ? null : () => _useGps(loc),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: c.isDark ? c.surf : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: loc.hasLocation ? c.gold.withValues(alpha: 0.40) : c.bd),
                ),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: c.goldSurface, shape: BoxShape.circle,
                      border: Border.all(color: c.gold.withValues(alpha: 0.22)),
                    ),
                    child: loc.isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(9),
                            child: CircularProgressIndicator(strokeWidth: 2, color: c.gold),
                          )
                        : Icon(Icons.my_location_rounded, color: c.gold, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use Current Location', style: AppTextStyles.label(c, size: 13)),
                      Text(
                        loc.hasLocation ? loc.locationLabel : 'Tap to detect via GPS',
                        style: AppTextStyles.bodyMuted(c, size: 10),
                      ),
                    ],
                  )),
                  if (loc.hasLocation)
                    Icon(Icons.check_circle_rounded, color: c.green, size: 20)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.goldSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.gold.withValues(alpha: 0.20)),
                      ),
                      child: Text('Detect', style: AppTextStyles.pill(c, size: 10.5)),
                    ),
                ]),
              ),
            ),

            const SizedBox(height: 8),

            // ── Manual search ────────────────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _showSearch
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: GestureDetector(
                onTap: () => setState(() { _showSearch = true; }),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: c.surf,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.bd),
                  ),
                  child: Row(children: [
                    Icon(Icons.search_rounded, color: c.t3, size: 17),
                    const SizedBox(width: 10),
                    Text('Set City Manually', style: AppTextStyles.body(c, size: 12, color: c.t3)),
                  ]),
                ),
              ),
              secondChild: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: c.surf,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.gold.withValues(alpha: 0.30)),
                    ),
                    child: Row(children: [
                      Icon(Icons.search_rounded, color: c.gold, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          style: AppTextStyles.body(c, size: 13),
                          decoration: InputDecoration(
                            hintText: 'Search city...',
                            hintStyle: AppTextStyles.bodyMuted(c, size: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (q) => _onSearchChanged(q, loc),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _showSearch = false;
                          _suggestions = [];
                          _searchCtrl.clear();
                        }),
                        child: Icon(Icons.close_rounded, color: c.t3, size: 15),
                      ),
                    ]),
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.bd),
                      ),
                      child: Column(
                        children: _suggestions.map((city) => GestureDetector(
                          onTap: () => _pickCity(city, loc),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: c.bd, width: 0.5)),
                            ),
                            child: Row(children: [
                              Icon(Icons.location_city_outlined, color: c.t3, size: 14),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(city.city, style: AppTextStyles.body(c, size: 13)),
                                  Text('${city.country} · ${city.coordLabel}',
                                      style: AppTextStyles.bodyMuted(c, size: 10)),
                                ],
                              )),
                              Icon(Icons.chevron_right_rounded, color: c.t3, size: 16),
                            ]),
                          ),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Main CTA ────────────────────────────────────────────────────
            _GoldButton(
              label: loc.hasLocation ? 'Continue →' : 'Enable Location Access →',
              onTap: loc.isLoading
                  ? null
                  : loc.hasLocation
                      ? () => Navigator.pushReplacementNamed(context, '/onboard/alarms')
                      : () => _useGps(loc),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/onboard/alarms'),
              child: Text('Skip for now', style: AppTextStyles.bodyMuted(c, size: 11)),
            ),

            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }
}

// ── Mosque CustomPainter ──────────────────────────────────────────────────────
class _MosquePainter extends CustomPainter {
  const _MosquePainter({required this.c});
  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final basePaint = Paint()
      ..color = c.gold.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = c.gold.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final goldFill = Paint()
      ..color = c.gold.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
        Path()..addRect(Rect.fromLTWH(0, h * 0.82, w, h * 0.18)),
        Paint()..color = c.gold.withValues(alpha: 0.08));

    _drawMinaret(canvas, Offset(w * 0.10, h * 0.82), w * 0.065,
        basePaint, strokePaint, c, h);
    _drawMinaret(canvas, Offset(w * 0.90, h * 0.82), w * 0.065,
        basePaint, strokePaint, c, h);

    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.62),
          width: w * 0.40, height: w * 0.36),
      math.pi, math.pi, false, goldFill,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.62),
          width: w * 0.40, height: w * 0.36),
      math.pi, math.pi, false, strokePaint,
    );

    for (final cx in [w * 0.28, w * 0.72]) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, h * 0.70),
            width: w * 0.24, height: w * 0.24),
        math.pi, math.pi, false, goldFill,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, h * 0.70),
            width: w * 0.24, height: w * 0.24),
        math.pi, math.pi, false, strokePaint,
      );
    }

    final wallPath = Path()
      ..moveTo(w * 0.035, h * 0.82)
      ..lineTo(w * 0.035, h * 0.72)
      ..lineTo(w * 0.965, h * 0.72)
      ..lineTo(w * 0.965, h * 0.82)
      ..close();
    canvas.drawPath(wallPath, basePaint);
    canvas.drawPath(wallPath, strokePaint);

    for (final relX in [0.22, 0.38, 0.50, 0.62, 0.78]) {
      _drawArch(canvas, Offset(w * relX, h * 0.72), w * 0.05, h * 0.08,
          goldFill, strokePaint);
    }

    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.44),
          width: w * 0.08, height: w * 0.08),
      -math.pi * 0.3, math.pi * 1.6, false,
      Paint()..color = c.gold.withValues(alpha: 0.80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
    );
    canvas.drawCircle(Offset(w * 0.50, h * 0.44 - w * 0.06), 3.5,
        Paint()..color = c.gold.withValues(alpha: 0.85));
  }

  void _drawMinaret(Canvas canvas, Offset base, double width,
      Paint fill, Paint stroke, AppColors c, double h) {
    final height = h * 0.50;
    final path = Path()
      ..moveTo(base.dx - width / 2, base.dy)
      ..lineTo(base.dx - width * 0.6, base.dy - height * 0.7)
      ..lineTo(base.dx, base.dy - height)
      ..lineTo(base.dx + width * 0.6, base.dy - height * 0.7)
      ..lineTo(base.dx + width / 2, base.dy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawArch(Canvas canvas, Offset center, double r, double legH,
      Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx - r, center.dy)
      ..lineTo(center.dx - r, center.dy + legH)
      ..lineTo(center.dx + r, center.dy + legH)
      ..lineTo(center.dx + r, center.dy)
      ..arcTo(Rect.fromCenter(center: center, width: r * 2, height: r * 2),
          0, -math.pi, false)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_MosquePainter old) => false;
}

// ── Gold button ───────────────────────────────────────────────────────────────
class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          height: 48,
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
      ),
    );
  }
}
