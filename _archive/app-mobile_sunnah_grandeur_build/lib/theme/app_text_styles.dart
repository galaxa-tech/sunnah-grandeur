import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// AppTextStyles — typography helpers using Google Fonts.
///
/// Three type scales:
///   - Cormorant Garamond  → display / brand / numbers
///   - Cinzel              → labels / section headings (small caps feel)
///   - Jost                → body / UI text
/// ───────────────────────────────────────────────────────────────────────────
class AppTextStyles {
  const AppTextStyles._();

  // ── Cormorant Garamond ─────────────────────────────────────────────────────

  static TextStyle brand(AppColors c) => GoogleFonts.cormorantGaramond(
    fontSize: 22, fontWeight: FontWeight.w500, color: c.t1,
    letterSpacing: 0.07 * 22,
  );

  static TextStyle brandSmall(AppColors c) => GoogleFonts.cormorantGaramond(
    fontSize: 19, fontWeight: FontWeight.w500, color: c.t1,
  );

  static TextStyle displayLg(AppColors c, {Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 38, fontWeight: FontWeight.w300,
        letterSpacing: 0.05 * 38, color: color ?? c.gold2,
      );

  static TextStyle displayMd(AppColors c, {Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 30, fontWeight: FontWeight.w400, color: color ?? c.t1,
      );

  static TextStyle displaySm(AppColors c, {Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 26, fontWeight: FontWeight.w300, color: color ?? c.gold,
      );

  static TextStyle displayXl(AppColors c, {Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 96, fontWeight: FontWeight.w300,
        letterSpacing: -2, color: color ?? c.gold,
        height: 1,
      );

  static TextStyle heading(AppColors c, {Color? color, double fontSize = 22}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: fontSize, fontWeight: FontWeight.w400, color: color ?? c.t1,
        height: 1.15,
      );

  static TextStyle italic(AppColors c, {Color? color, double fontSize = 14}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: fontSize, fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w300, color: color ?? c.t3,
        height: 1.8,
      );

  static TextStyle prayerName(AppColors c) => GoogleFonts.cormorantGaramond(
    fontSize: 17, color: c.t1,
  );

  // ── Cinzel ─────────────────────────────────────────────────────────────────

  static TextStyle sectionLabel(AppColors c) => GoogleFonts.cinzel(
    fontSize: 8.5, fontWeight: FontWeight.w400, color: c.gold,
    letterSpacing: 0.28 * 8.5,
    decoration: TextDecoration.none,
  );

  static TextStyle brandTag(AppColors c) => GoogleFonts.cinzel(
    fontSize: 7.5, fontWeight: FontWeight.w400, color: c.gold,
    letterSpacing: 0.3 * 7.5,
  );

  static TextStyle cinzelSm(AppColors c, {Color? color, double size = 8.0}) =>
      GoogleFonts.cinzel(
        fontSize: size, color: color ?? c.t3,
        letterSpacing: 0.2 * size,
      );

  // ── Jost ───────────────────────────────────────────────────────────────────

  static TextStyle body(AppColors c, {double size = 13, Color? color,
      FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.jost(fontSize: size, color: color ?? c.t1, fontWeight: weight);

  static TextStyle bodyMuted(AppColors c, {double size = 10}) =>
      GoogleFonts.jost(fontSize: size, color: c.t3);

  static TextStyle pill(AppColors c, {Color? color, double size = 8.5}) =>
      GoogleFonts.jost(fontSize: size, fontWeight: FontWeight.w500,
          color: color ?? c.gold);

  static TextStyle label(AppColors c, {Color? color, double size = 12}) =>
      GoogleFonts.jost(fontSize: size, fontWeight: FontWeight.w500,
          color: color ?? c.t1);

  static TextStyle button(AppColors c, {Color color = Colors.white}) =>
      GoogleFonts.jost(fontSize: 14, fontWeight: FontWeight.w600,
          color: color, letterSpacing: 0.04 * 14);
}
