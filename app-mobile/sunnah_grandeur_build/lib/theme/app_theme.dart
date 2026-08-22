import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppColors.light);
  static ThemeData dark()  => _build(AppColors.dark);

  static ThemeData _build(AppColors c) {
    return ThemeData(
      brightness: c.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme(
        brightness:    c.isDark ? Brightness.dark : Brightness.light,
        primary:       c.gold,
        onPrimary:     c.isDark ? c.bg : Colors.white,
        secondary:     c.gold2,
        onSecondary:   c.isDark ? c.bg : Colors.white,
        surface:       c.surf,
        onSurface:     c.t1,
        error:         c.red,
        onError:       Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.t1),
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22, fontWeight: FontWeight.w500, color: c.t1,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bg2,
        selectedItemColor: c.gold,
        unselectedItemColor: c.t3,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: c.bd,
      textTheme: GoogleFonts.jostTextTheme().apply(
        bodyColor: c.t1, displayColor: c.t1,
      ),
      useMaterial3: true,
    );
  }
}
