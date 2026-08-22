import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// All styles use Inter — SF Pro-equivalent weight hierarchy:
/// display w200–w300, heading w600–w700, body w400, label w500.
class AppTextStyles {
  const AppTextStyles._();

  // ── Display / Brand ────────────────────────────────────────────────────────

  static TextStyle brand(AppColors c) => GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700, color: c.t1,
    letterSpacing: -0.3,
  );

  static TextStyle brandSmall(AppColors c) => GoogleFonts.inter(
    fontSize: 19, fontWeight: FontWeight.w700, color: c.t1,
    letterSpacing: -0.2,
  );

  static TextStyle displayLg(AppColors c, {Color? color}) =>
      GoogleFonts.inter(
        fontSize: 38, fontWeight: FontWeight.w300,
        letterSpacing: -1.0, color: color ?? c.gold2,
      );

  static TextStyle displayMd(AppColors c, {Color? color}) =>
      GoogleFonts.inter(
        fontSize: 30, fontWeight: FontWeight.w500, color: color ?? c.t1,
        letterSpacing: -0.5,
      );

  static TextStyle displaySm(AppColors c, {Color? color}) =>
      GoogleFonts.inter(
        fontSize: 26, fontWeight: FontWeight.w400, color: color ?? c.gold,
        letterSpacing: -0.3,
      );

  static TextStyle displayXl(AppColors c, {Color? color}) =>
      GoogleFonts.inter(
        fontSize: 96, fontWeight: FontWeight.w200,
        letterSpacing: -4, color: color ?? c.gold,
        height: 1,
      );

  static TextStyle heading(AppColors c, {Color? color, double fontSize = 22}) =>
      GoogleFonts.inter(
        fontSize: fontSize, fontWeight: FontWeight.w600, color: color ?? c.t1,
        height: 1.15, letterSpacing: -0.2,
      );

  static TextStyle italic(AppColors c, {Color? color, double fontSize = 14}) =>
      GoogleFonts.inter(
        fontSize: fontSize, fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w300, color: color ?? c.t2,
        height: 1.7,
      );

  static TextStyle prayerName(AppColors c) => GoogleFonts.inter(
    fontSize: 17, fontWeight: FontWeight.w500, color: c.t1,
    letterSpacing: -0.1,
  );

  // ── Labels / Caps ──────────────────────────────────────────────────────────

  static TextStyle sectionLabel(AppColors c) => GoogleFonts.inter(
    fontSize: 8.5, fontWeight: FontWeight.w700, color: c.gold,
    letterSpacing: 1.4,
    decoration: TextDecoration.none,
  );

  static TextStyle brandTag(AppColors c) => GoogleFonts.inter(
    fontSize: 7.5, fontWeight: FontWeight.w600, color: c.gold,
    letterSpacing: 1.6,
  );

  static TextStyle cinzelSm(AppColors c, {Color? color, double size = 8.0}) =>
      GoogleFonts.inter(
        fontSize: size, color: color ?? c.t3,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      );

  // ── Body / UI ──────────────────────────────────────────────────────────────

  static TextStyle body(AppColors c, {double size = 13.5, Color? color,
      FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: size, color: color ?? c.t1,
          fontWeight: weight, height: 1.45);

  static TextStyle bodyMuted(AppColors c, {double size = 11}) =>
      GoogleFonts.inter(fontSize: size, color: c.t2,
          fontWeight: FontWeight.w400, height: 1.4);

  static TextStyle pill(AppColors c, {Color? color, double size = 9}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w600,
          color: color ?? c.gold, letterSpacing: 0.2);

  static TextStyle label(AppColors c, {Color? color, double size = 13}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w500,
          color: color ?? c.t1, height: 1.3);

  static TextStyle button(AppColors c, {Color color = Colors.white}) =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600,
          color: color, letterSpacing: 0.1);
}
