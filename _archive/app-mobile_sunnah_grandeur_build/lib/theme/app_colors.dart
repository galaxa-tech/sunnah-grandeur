import 'package:flutter/material.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// AppColors — static color tokens for both light and dark modes.
///
/// Usage:
///   AppColors.light.gold      → light gold token
///   AppColors.dark.gold       → dark gold token
///   AppColors.of(context).t1  → resolves based on current theme
/// ───────────────────────────────────────────────────────────────────────────
class AppColors {
  const AppColors._({
    required this.bg,
    required this.bg2,
    required this.surf,
    required this.elev,
    required this.bd,
    required this.bd2,
    required this.gold,
    required this.gold2,
    required this.gold3,
    required this.goldSurface,
    required this.t1,
    required this.t2,
    required this.t3,
    required this.red,
    required this.green,
    required this.blue,
    required this.isDark,
  });

  final Color bg;
  final Color bg2;
  final Color surf;
  final Color elev;
  final Color bd;
  final Color bd2;
  final Color gold;
  final Color gold2;
  final Color gold3;
  final Color goldSurface;   // gold at very low opacity for backgrounds
  final Color t1;
  final Color t2;
  final Color t3;
  final Color red;
  final Color green;
  final Color blue;
  final bool isDark;

  // ── Light palette ──────────────────────────────────────────────────────────
  static const AppColors light = AppColors._(
    bg:          Color(0xFFF8F3EA),
    bg2:         Color(0xFFF2EDE0),
    surf:        Color(0xFFEDE7D8),
    elev:        Color(0xFFE6DFD0),
    bd:          Color(0xFFDDD4C0),
    bd2:         Color(0xFFCFC4AC),
    gold:        Color(0xFFA07828),
    gold2:       Color(0xFFB8962E),
    gold3:       Color(0xFF7A5A18),
    goldSurface: Color(0x17A07828),  // 9% opacity
    t1:          Color(0xFF1A1512),
    t2:          Color(0xFF5A4E40),
    t3:          Color(0xFF9E8E78),
    red:         Color(0xFFC0392B),
    green:       Color(0xFF2E7D52),
    blue:        Color(0xFF4A44CC),
    isDark:      false,
  );

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const AppColors dark = AppColors._(
    bg:          Color(0xFF0D0D0F),
    bg2:         Color(0xFF111113),
    surf:        Color(0xFF171719),
    elev:        Color(0xFF1F1F23),
    bd:          Color(0xFF252528),
    bd2:         Color(0xFF2E2E34),
    gold:        Color(0xFFC8A55A),
    gold2:       Color(0xFFE2C07A),
    gold3:       Color(0xFF8C6E30),
    goldSurface: Color(0x1AC8A55A),  // 10% opacity
    t1:          Color(0xFFF2EDE4),
    t2:          Color(0xFFB8B0A4),
    t3:          Color(0xFF706860),
    red:         Color(0xFFE87B6B),
    green:       Color(0xFF4CAF82),
    blue:        Color(0xFF635BFF),
    isDark:      true,
  );

  /// Resolves the current theme's color set from BuildContext.
  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Gold gradient used on primary buttons and hero cards.
  LinearGradient get goldGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, gold3],
  );

  /// Gold card background gradient.
  LinearGradient get goldCardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gold.withOpacity(isDark ? 0.09 : 0.10),
      gold.withOpacity(isDark ? 0.02 : 0.03),
    ],
  );

  BoxDecoration get goldCardDecoration => BoxDecoration(
    gradient: goldCardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: gold.withOpacity(isDark ? 0.15 : 0.18)),
  );

  BoxDecoration get surfaceCardDecoration => BoxDecoration(
    color: surf,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: bd),
  );
}
