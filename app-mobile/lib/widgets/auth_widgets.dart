import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared auth UI — one look for every sign-in / sign-up surface.
//   • GoogleGLogo          — the real 4-colour Google "G" (vector, no asset)
//   • AuthSocialButton     — "Continue with Google / Apple" per brand guidelines
//   • AuthPrimaryButton    — gold filled CTA with loading state
//   • AuthTextField        — floating-label field, animated gold focus ring,
//                            inline validation errors, password toggle
// ─────────────────────────────────────────────────────────────────────────────

/// The official multicolour Google "G", drawn as vector paths so it is
/// crisp at any size and needs no bundled image.
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: _GPainter()));
}

class _GPainter extends CustomPainter {
  static const _blue   = Color(0xFF4285F4);
  static const _green  = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red    = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final r = (s - stroke) / 2;
    final center = Offset(s / 2, s / 2);
    final rect = Rect.fromCircle(center: center, radius: r);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    double deg(double d) => d * math.pi / 180;
    // Angles clockwise from 3 o'clock.
    canvas.drawArc(rect, deg(0), deg(45), false, arc(_blue));           // bar → bottom-right
    canvas.drawArc(rect, deg(45), deg(90), false, arc(_green));         // bottom
    canvas.drawArc(rect, deg(135), deg(80), false, arc(_yellow));       // left
    canvas.drawArc(rect, deg(215), deg(100), false, arc(_red));         // top (opening at top-right)
    // Crossbar of the G.
    final bar = Paint()..color = _blue;
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke * 0.05, stroke),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum AuthProviderKind { google, apple }

/// "Continue with Google" / "Continue with Apple" button. Google's button is
/// white with the colour G (Google brand guidelines); Apple's is black.
class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.kind,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.disabled = false,
  });

  final AuthProviderKind kind;
  final String label;
  final VoidCallback onTap;
  final bool loading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isGoogle = kind == AuthProviderKind.google;
    final bg = isGoogle ? Colors.white : Colors.black;
    final fg = isGoogle ? const Color(0xFF1F1F1F) : Colors.white;
    final inactive = disabled || loading;

    return _Pressable(
      onTap: inactive ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled && !loading ? 0.5 : 1,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isGoogle
                  ? (c.isDark ? Colors.transparent : const Color(0xFFDADCE0))
                  : Colors.white.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: loading
              ? Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isGoogle ? const Color(0xFF4285F4) : Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGoogle)
                      const GoogleGLogo(size: 20)
                    else
                      const Icon(Icons.apple, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Gold gradient primary button used for the main action of a form.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.disabled = false,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;
  final bool disabled;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = outlined ? c.gold : const Color(0xFF1A1200);
    final inactive = disabled || loading;

    return _Pressable(
      onTap: inactive ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled && !loading ? 0.5 : 1,
        child: Container(
          height: 54,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.gold.withValues(alpha: 0.55), width: 1.2),
                )
              : BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.gold2, c.gold, c.gold3],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: c.gold.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
          child: loading
              ? SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: fg),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Floating-label text field with an animated gold focus border and inline
/// validation messages (errors are *shown*, not swallowed).
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.focusNode,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.validator,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final FocusNode? focusNode;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final String? helperText;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    OutlineInputBorder border(Color color, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: w),
        );

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      autofillHints: widget.autofillHints,
      textCapitalization: widget.textCapitalization,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      cursorColor: c.gold,
      style: GoogleFonts.inter(fontSize: 15, color: c.t1),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperStyle: GoogleFonts.inter(fontSize: 11.5, color: c.t3),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: c.t3),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) =>
            GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.error) ? c.red : c.gold,
            )),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: c.red, height: 1.3),
        errorMaxLines: 2,
        filled: true,
        fillColor: c.surf,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        prefixIcon: Icon(widget.icon, size: 19),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.error)) return c.red;
          if (states.contains(WidgetState.focused)) return c.gold;
          return c.t3;
        }),
        suffixIcon: widget.isPassword
            ? IconButton(
                splashRadius: 20,
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 19,
                  color: c.t3,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        enabledBorder: border(c.bd2),
        focusedBorder: border(c.gold, 1.6),
        errorBorder: border(c.red.withValues(alpha: 0.7)),
        focusedErrorBorder: border(c.red, 1.6),
      ),
    );
  }
}

/// "or" divider between social and email options.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, this.label = 'or'});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: c.bd2, thickness: 0.8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(label, style: GoogleFonts.inter(color: c.t3, fontSize: 12)),
        ),
        Expanded(child: Divider(color: c.bd2, thickness: 0.8)),
      ],
    );
  }
}

/// Scale-on-press wrapper with a light haptic — gives buttons tactile feel.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 110),
          child: widget.child,
        ),
      ),
    );
  }
}
