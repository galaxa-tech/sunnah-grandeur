import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppColors.light);
  static ThemeData dark()  => _build(AppColors.dark);

  static ThemeData _build(AppColors c) {
    final base = GoogleFonts.interTextTheme(
      c.isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(bodyColor: c.t1, displayColor: c.t1);

    return ThemeData(
      fontFamily: GoogleFonts.inter().fontFamily,
      brightness: c.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme(
        brightness:  c.isDark ? Brightness.dark : Brightness.light,
        primary:     c.gold,
        onPrimary:   c.isDark ? c.bg : Colors.white,
        secondary:   c.gold2,
        onSecondary: c.isDark ? c.bg : Colors.white,
        surface:     c.surf,
        onSurface:   c.t1,
        error:       c.red,
        onError:     Colors.white,
      ),
      textTheme: base.copyWith(
        displayLarge:  base.displayLarge?.copyWith(fontWeight: FontWeight.w700),
        displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w700),
        displaySmall:  base.displaySmall?.copyWith(fontWeight: FontWeight.w600),
        headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
        headlineMedium:base.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        titleLarge:    base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium:   base.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        titleSmall:    base.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        bodyLarge:     base.bodyLarge?.copyWith(fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium:    base.bodyMedium?.copyWith(fontWeight: FontWeight.w400, height: 1.5),
        bodySmall:     base.bodySmall?.copyWith(fontWeight: FontWeight.w400, color: c.t2),
        labelLarge:    base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        labelMedium:   base.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        labelSmall:    base.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: c.t2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:            c.bg,
        elevation:                  0,
        scrolledUnderElevation:     0,
        systemOverlayStyle: c.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: c.t1, size: 22),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700, color: c.t1,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      c.bg2,
        selectedItemColor:    c.gold,
        unselectedItemColor:  c.t3,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      // InputDecoration defaults — cleaner text fields
      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      c.surf,
        border:         OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.bd2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.bd2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.gold, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // Card defaults
      cardTheme: CardThemeData(
        color:     c.surf,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.bd),
        ),
      ),
      // Chip defaults
      chipTheme: ChipThemeData(
        backgroundColor:   c.surf,
        selectedColor:     c.gold,
        side:              BorderSide(color: c.bd2),
        labelStyle:        GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        padding:           const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      dividerColor: c.bd,
      useMaterial3: true,
    );
  }
}
