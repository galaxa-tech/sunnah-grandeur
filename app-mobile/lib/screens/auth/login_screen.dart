// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen — minimal email + password sign-in.
//
// Google Sign-In and Guest mode live only on WelcomeScreen; this screen is a
// clean email/password form reached via "Sign In with Email".
// Navigation: all success paths use pushNamedAndRemoveUntil('/main', (_) => false)
// to cleanly clear the stack regardless of where this screen was pushed from.
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _passFocus  = FocusNode();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  bool get _anyLoading => _isLoading;

  // ── Email sign-in ─────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _anyLoading) return;

    setState(() => _isLoading = true);
    final auth    = context.read<AuthProvider>();
    final success = await auth.signIn(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      HapticFeedback.lightImpact();
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } else {
      setState(() => _isLoading = false);
      _showSnack(auth.error ?? 'Sign-in failed. Please try again.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: const Color(0xFF1F1F23),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.t2, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),

                // ── Header ─────────────────────────────────────────────────
                Text('Sunnah Grandeur', style: AppTextStyles.brand(c)),
                const SizedBox(height: 4),
                Text('Welcome back', style: AppTextStyles.displayMd(c)),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue your journey.',
                  style: AppTextStyles.italic(c, fontSize: 13),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // ── Email field ────────────────────────────────────────────
                _AuthField(
                  label: 'Email',
                  controller: _emailCtrl,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _passFocus.requestFocus(),
                  c: c,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Password field ─────────────────────────────────────────
                _AuthField(
                  label: 'Password',
                  controller: _passCtrl,
                  focusNode: _passFocus,
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  c: c,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen())),
                    child: Text('Forgot password?',
                        style: GoogleFonts.inter(
                            color: c.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Sign-in button ─────────────────────────────────────────
                _IconlessButton(
                  label: 'Sign In',
                  loading: _isLoading,
                  disabled: _anyLoading,
                  onTap: _handleLogin,
                  c: c,
                ),

                const SizedBox(height: 24),

                // ── Register link ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: AppTextStyles.bodyMuted(c, size: 13)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      child: Text('Create one',
                        style: GoogleFonts.inter(
                          color: c.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _IconlessButton — gold filled button (no logo, no icon)
// ─────────────────────────────────────────────────────────────────────────────

class _IconlessButton extends StatelessWidget {
  const _IconlessButton({
    required this.label,
    required this.loading,
    required this.disabled,
    required this.onTap,
    required this.c,
  });

  final String      label;
  final bool        loading;
  final bool        disabled;
  final VoidCallback onTap;
  final AppColors   c;

  @override
  Widget build(BuildContext context) {
    final deco = BoxDecoration(
      gradient: c.goldGradient,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: c.gold.withOpacity(0.28),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );

    const textColor = Color(0xFF1A1200);
    const spinnerColor = Color(0xFF2D1F00);

    return GestureDetector(
      onTap: (disabled || loading) ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: (disabled || loading) ? 0.55 : 1.0,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: deco,
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AuthField — validated text field with gold icon accent
// ─────────────────────────────────────────────────────────────────────────────

class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.c,
    this.focusNode,
    this.isPassword      = false,
    this.keyboardType    = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.validator,
  });

  final String                  label;
  final TextEditingController   controller;
  final IconData                icon;
  final AppColors               c;
  final FocusNode?              focusNode;
  final bool                    isPassword;
  final TextInputType           keyboardType;
  final TextInputAction         textInputAction;
  final ValueChanged<String>?   onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label.toUpperCase(),
            style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: c.gold,
                letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: c.surf,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.bd2),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: c.gold, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  obscureText: widget.isPassword && _obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: widget.onFieldSubmitted,
                  validator: widget.validator,
                  style: AppTextStyles.body(c, size: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    errorStyle: TextStyle(height: 0), // error shown by container
                  ),
                ),
              ),
              if (widget.isPassword)
                GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: c.t3, size: 18,
                  ),
                ),
            ],
          ),
        ),
        // Inline error via validator is suppressed above; Form handles it.
      ],
    );
  }
}
