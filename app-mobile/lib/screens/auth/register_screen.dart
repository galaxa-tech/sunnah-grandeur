// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RegisterScreen — minimal 3-field signup (name, email, password).
//
// Phone removed to reduce friction. Google Sign-In is offered here only for
// guests upgrading their account (isGuest branch) — normal registration is a
// clean email/password form; new users pick Google from WelcomeScreen instead.
// Navigation: all success paths use pushNamedAndRemoveUntil('/main', (_) => false).
// ─────────────────────────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();

  bool _isLoading     = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  bool get _anyLoading => _isLoading || _googleLoading;

  // ── Email register ────────────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || _anyLoading) return;

    setState(() => _isLoading = true);
    final auth    = context.read<AuthProvider>();
    final success = await auth.register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      HapticFeedback.lightImpact();
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } else {
      setState(() => _isLoading = false);
      _showSnack(auth.error ?? 'Registration failed. Please try again.');
    }
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<void> _handleGoogle() async {
    if (_anyLoading) return;
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithGoogle();
    if (!mounted) return;

    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } else {
      setState(() => _googleLoading = false);
      final msg = auth.error ?? '';
      if (msg.isNotEmpty) _showSnack(msg);
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
    final c       = AppColors.of(context);
    final isGuest = context.watch<AuthProvider>().isGuest;

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
                const SizedBox(height: 12),
                Text(
                  isGuest ? 'Save Your Progress' : 'Create Account',
                  style: AppTextStyles.displayMd(c),
                ),
                const SizedBox(height: 6),
                Text(
                  isGuest
                      ? 'Create an account to sync your favorites, orders & settings.'
                      : 'Join the community. Takes less than a minute.',
                  style: AppTextStyles.italic(c, fontSize: 13),
                  textAlign: TextAlign.center,
                ),

                // Guest upgrade notice
                if (isGuest) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: c.goldSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.gold.withOpacity(0.22)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: c.gold, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your guest session will be preserved when you upgrade.',
                            style: GoogleFonts.inter(
                                color: c.t2, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Google — guest-upgrade path only (text only, no logo) ──
                // Normal registration is email/password only; new users pick
                // Google from WelcomeScreen. Guests upgrading get it here too
                // since it's the fastest way to save their progress.
                if (isGuest) ...[
                  _IconlessButton(
                    label: 'Continue with Google',
                    loading: _googleLoading,
                    disabled: _anyLoading,
                    onTap: _handleGoogle,
                    isGold: false,
                    c: c,
                  ),

                  const SizedBox(height: 20),

                  // ── Divider ──────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: c.bd2, thickness: 0.8)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('or create with email',
                            style: GoogleFonts.inter(
                                color: c.t3, fontSize: 11)),
                      ),
                      Expanded(child: Divider(color: c.bd2, thickness: 0.8)),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],

                // ── Name ───────────────────────────────────────────────────
                _RegField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  c: c,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Name is too short';
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // ── Email ──────────────────────────────────────────────────
                _RegField(
                  label: 'Email Address',
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _passFocus.requestFocus(),
                  c: c,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // ── Password ───────────────────────────────────────────────
                _RegField(
                  label: 'Password',
                  controller: _passCtrl,
                  focusNode: _passFocus,
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  c: c,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // ── Create Account button ──────────────────────────────────
                _IconlessButton(
                  label: isGuest ? 'Save & Upgrade Account' : 'Create Account',
                  loading: _isLoading,
                  disabled: _anyLoading,
                  onTap: _handleRegister,
                  isGold: true,
                  c: c,
                ),

                const SizedBox(height: 24),

                // ── Sign-in link ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: AppTextStyles.bodyMuted(c, size: 13)),
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Text('Sign in',
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
// _IconlessButton — dark surface or gold filled, text only
// ─────────────────────────────────────────────────────────────────────────────
class _IconlessButton extends StatelessWidget {
  const _IconlessButton({
    required this.label,
    required this.loading,
    required this.disabled,
    required this.onTap,
    required this.isGold,
    required this.c,
  });

  final String      label;
  final bool        loading;
  final bool        disabled;
  final VoidCallback onTap;
  final bool        isGold;
  final AppColors   c;

  @override
  Widget build(BuildContext context) {
    final deco = isGold
        ? BoxDecoration(
            gradient: c.goldGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: c.gold.withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          )
        : BoxDecoration(
            color: c.surf,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.gold.withOpacity(0.45), width: 1.2),
          );

    final textColor = isGold ? const Color(0xFF1A1200) : c.t1;
    final spinnerColor = isGold ? const Color(0xFF2D1F00) : c.gold;

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
// _RegField — validated form field
// ─────────────────────────────────────────────────────────────────────────────
class _RegField extends StatefulWidget {
  const _RegField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.c,
    this.focusNode,
    this.isPassword          = false,
    this.keyboardType        = TextInputType.text,
    this.textCapitalization  = TextCapitalization.none,
    this.textInputAction     = TextInputAction.next,
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
  final TextCapitalization      textCapitalization;
  final TextInputAction         textInputAction;
  final ValueChanged<String>?   onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  State<_RegField> createState() => _RegFieldState();
}

class _RegFieldState extends State<_RegField> {
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
                  controller:          widget.controller,
                  focusNode:           widget.focusNode,
                  obscureText:         widget.isPassword && _obscure,
                  keyboardType:        widget.keyboardType,
                  textCapitalization:  widget.textCapitalization,
                  textInputAction:     widget.textInputAction,
                  onFieldSubmitted:    widget.onFieldSubmitted,
                  validator:           widget.validator,
                  style: AppTextStyles.body(c, size: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    errorStyle: TextStyle(height: 0, fontSize: 0),
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
      ],
    );
  }
}
