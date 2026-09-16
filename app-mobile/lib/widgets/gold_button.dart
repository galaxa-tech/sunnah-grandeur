import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_motion.dart';

/// Shared primary CTA — pill-shaped gold-gradient button with a press-scale
/// micro-interaction. Single source of truth replacing the three near-
/// identical `_GoldButton` copies previously hand-rolled per onboarding
/// screen.
class GoldButton extends StatefulWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 52,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final IconData? icon;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.5,
          duration: AppMotion.base,
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: c.goldGradient,
              borderRadius: BorderRadius.circular(widget.height),
              boxShadow: [
                BoxShadow(
                  color: c.gold.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon,
                      color: c.isDark ? c.bg : Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(widget.label, style: AppTextStyles.button(c)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
