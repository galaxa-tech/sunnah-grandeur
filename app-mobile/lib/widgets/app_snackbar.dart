import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Semantic tone for [showAppSnackbar] — picks the accent color and icon.
enum AppSnackbarType { info, success, error }

/// Shows a SnackBar styled to match the app's premium dark/gold aesthetic —
/// a floating, rounded, dark-surface toast with a colored accent icon —
/// instead of Flutter's plain default SnackBar. Use this anywhere a
/// transient status message is shown so every screen shares one look.
void showAppSnackbar(
  BuildContext context,
  String message, {
  AppSnackbarType type = AppSnackbarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final c = AppColors.of(context);
  final Color accent;
  final IconData icon;
  switch (type) {
    case AppSnackbarType.success:
      accent = c.green;
      icon = Icons.check_circle_outline_rounded;
      break;
    case AppSnackbarType.error:
      accent = c.red;
      icon = Icons.error_outline_rounded;
      break;
    case AppSnackbarType.info:
      accent = c.gold;
      icon = Icons.info_outline_rounded;
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: c.isDark ? c.elev : Colors.white,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      duration: duration,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withValues(alpha: 0.25)),
      ),
      content: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppTextStyles.body(c, size: 13)),
          ),
        ],
      ),
    ),
  );
}
