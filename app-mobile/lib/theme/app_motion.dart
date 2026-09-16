import 'package:flutter/animation.dart';

/// Shared motion tokens so animations across the app follow one rhythm
/// instead of ad-hoc durations/curves picked per widget.
class AppMotion {
  const AppMotion._();

  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);

  /// Standard easing for most enter/interaction animations.
  static const curve = Curves.easeOutCubic;

  /// Per-item stagger delay for list/grid entrance animations.
  static const staggerStep = Duration(milliseconds: 40);
}
