import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A section divider row with a Cinzel label, decorative horizontal lines,
/// and an optional trailing widget (e.g., a pill badge).
///
/// Matches the .er / .eye / .eline HTML pattern.
class EyeRow extends StatelessWidget {
  const EyeRow({
    super.key,
    required this.label,
    this.trailing,
    EdgeInsets? padding,
  }) : padding = padding ?? const EdgeInsets.fromLTRB(18, 16, 18, 8);

  final String label;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: padding,
      child: Row(children: [
        Text(label, style: AppTextStyles.sectionLabel(c)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                c.gold.withOpacity(0.20),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ]),
    );
  }
}
