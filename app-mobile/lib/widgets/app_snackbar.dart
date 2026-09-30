import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Semantic tone for [showAppSnackbar] — picks the accent color and icon.
enum AppSnackbarType { info, success, error }

/// Shows a SnackBar styled to match the app's premium dark/gold aesthetic —
/// a floating, rounded, dark-surface toast with a colored accent icon —
/// instead of Flutter's plain default SnackBar. Use this anywhere a
/// transient status message is shown so every screen shares one look.
///
/// Optional [actionLabel]/[onAction] add a gold text action (e.g. "Undo",
/// "View cart"). Any toast already showing is replaced, so rapid actions
/// don't queue up a backlog of messages.
void showAppSnackbar(
  BuildContext context,
  String message, {
  AppSnackbarType type = AppSnackbarType.info,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
  Widget? leading,
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

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: c.isDark ? c.elev : Colors.white,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      duration: duration,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: 0.30)),
      ),
      content: Row(
        children: [
          leading ?? Icon(icon, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: AppTextStyles.body(c, size: 13.5)),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onAction();
              },
              style: TextButton.styleFrom(
                foregroundColor: c.gold,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 36),
              ),
              child: Text(
                actionLabel,
                style: AppTextStyles.body(c, size: 13, color: c.gold,
                    weight: FontWeight.w700),
              ),
            ),
        ],
      ),
    ),
  );
}
