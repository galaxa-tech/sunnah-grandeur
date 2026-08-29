import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// A pill/badge widget.
/// [variant]: 'gold' | 'green' | 'red'
class SgPill extends StatelessWidget {
  const SgPill({
    super.key,
    required this.label,
    this.variant = 'gold',
    this.fontSize = 8.5,
  });

  final String label;
  final String variant;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Color bg, border, fg;
    switch (variant) {
      case 'green':
        bg     = c.green.withValues(alpha: 0.10);
        border = c.green.withValues(alpha: 0.22);
        fg     = c.green;
        break;
      case 'red':
        bg     = c.red.withValues(alpha: 0.10);
        border = c.red.withValues(alpha: 0.22);
        fg     = c.red;
        break;
      default:
        bg     = c.goldSurface;
        border = c.gold.withValues(alpha: 0.22);
        fg     = c.gold;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}
