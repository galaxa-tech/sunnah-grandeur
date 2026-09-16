import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Soft twinkling gold "star field" for full-bleed dark backgrounds
/// (onboarding, celebratory/empty states). Purely code-drawn — no image
/// assets — so it composites cleanly at any size and matches the app's
/// existing hand-drawn illustration technique instead of introducing a new
/// asset pipeline.
class StarField extends StatefulWidget {
  const StarField({super.key, this.starCount = 40});

  final int starCount;

  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _stars = List.generate(widget.starCount, (_) {
      return _Star(
        dx: rnd.nextDouble(),
        dy: rnd.nextDouble() * 0.75,
        radius: 0.6 + rnd.nextDouble() * 1.6,
        phase: rnd.nextDouble() * 2 * math.pi,
        speed: 0.5 + rnd.nextDouble() * 0.9,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _StarFieldPainter(
          stars: _stars,
          t: _controller.value * 2 * math.pi,
          color: c.gold,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _Star {
  _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.phase,
    required this.speed,
  });
  final double dx, dy, radius, phase, speed;
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter({required this.stars, required this.t, required this.color});
  final List<_Star> stars;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final twinkle = 0.35 + 0.45 * (0.5 + 0.5 * math.sin(t * star.speed + star.phase));
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        star.radius,
        Paint()..color = color.withValues(alpha: twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => old.t != t;
}
