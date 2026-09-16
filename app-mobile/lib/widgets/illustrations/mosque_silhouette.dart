import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Full-bleed twin-minaret mosque silhouette with a crescent moon overhead,
/// rendered entirely in the app's own gold tokens. Generalizes the
/// hand-drawn mosque painter first built for the location onboarding
/// screen into a shared, reusable background illustration (onboarding,
/// empty states, section headers) so the motif reads as one system rather
/// than a one-off per screen.
class MosqueSilhouette extends StatelessWidget {
  const MosqueSilhouette({
    super.key,
    this.opacity = 1.0,
    this.showCrescent = true,
  });

  final double opacity;
  final bool showCrescent;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        painter: _MosqueSilhouettePainter(c: c, showCrescent: showCrescent),
        size: Size.infinite,
      ),
    );
  }
}

class _MosqueSilhouettePainter extends CustomPainter {
  const _MosqueSilhouettePainter({required this.c, required this.showCrescent});
  final AppColors c;
  final bool showCrescent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fill = Paint()
      ..color = c.gold.withValues(alpha: c.isDark ? 0.22 : 0.16)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = c.gold.withValues(alpha: c.isDark ? 0.55 : 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Ground wall
    final wallPath = Path()
      ..moveTo(w * 0.02, h * 0.85)
      ..lineTo(w * 0.02, h * 0.74)
      ..lineTo(w * 0.98, h * 0.74)
      ..lineTo(w * 0.98, h * 0.85)
      ..close();
    canvas.drawPath(wallPath, fill);
    canvas.drawPath(wallPath, stroke);

    for (final relX in [0.14, 0.30, 0.50, 0.70, 0.86]) {
      _drawArch(canvas, Offset(w * relX, h * 0.74), w * 0.055, h * 0.09, fill, stroke);
    }

    _drawMinaret(canvas, Offset(w * 0.06, h * 0.85), w * 0.05, h * 0.55, fill, stroke);
    _drawMinaret(canvas, Offset(w * 0.94, h * 0.85), w * 0.05, h * 0.55, fill, stroke);

    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.64), width: w * 0.42, height: w * 0.38),
      math.pi, math.pi, false, fill,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.64), width: w * 0.42, height: w * 0.38),
      math.pi, math.pi, false, stroke,
    );

    // Central dome + finial
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.40), width: w * 0.10, height: w * 0.10),
      -math.pi * 0.3, math.pi * 1.6, false,
      Paint()
        ..color = c.gold.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.40 - w * 0.07), 3.5,
        Paint()..color = c.gold.withValues(alpha: 0.9));

    if (showCrescent) {
      final crescentCenter = Offset(w * 0.74, h * 0.16);
      final r = w * 0.045;
      final glow = Paint()
        ..color = c.gold.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(crescentCenter, r * 1.6, glow);

      final moon = Path()
        ..addOval(Rect.fromCircle(center: crescentCenter, radius: r));
      final bite = Path()
        ..addOval(Rect.fromCircle(
            center: crescentCenter.translate(r * 0.55, -r * 0.15), radius: r * 0.9));
      final crescent = Path.combine(PathOperation.difference, moon, bite);
      canvas.drawPath(crescent, Paint()..color = c.gold.withValues(alpha: 0.9));
    }
  }

  void _drawMinaret(Canvas canvas, Offset base, double width, double height,
      Paint fill, Paint stroke) {
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
      ..arcTo(Rect.fromCenter(center: center, width: r * 2, height: r * 2), 0, -math.pi, false)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_MosqueSilhouettePainter old) =>
      old.showCrescent != showCrescent || old.c != c;
}
