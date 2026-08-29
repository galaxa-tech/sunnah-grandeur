import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shows a confirmation dialog styled to match the app's dark-surface,
/// gold-accented aesthetic — used in place of Flutter's plain default
/// [AlertDialog] for confirmations (e.g. deleting an account, discarding
/// changes).
///
/// Returns `true` if the user tapped the confirm action, `false`/`null`
/// otherwise (dismissed or cancelled).
Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool danger = false,
}) {
  final c = AppColors.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: c.isDark ? c.elev : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.bd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.heading(c, fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTextStyles.body(c, size: 13, color: c.t2)
                  .copyWith(height: 1.5),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.bd2),
                      ),
                      child: Text(cancelLabel,
                          style: AppTextStyles.label(c, size: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: danger ? null : c.goldGradient,
                        color: danger ? c.red : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        confirmLabel,
                        style: AppTextStyles.button(
                          c,
                          color: danger
                              ? Colors.white
                              : (c.isDark ? c.bg : Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
