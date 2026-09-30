import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/brand_lockup.dart';
import 'login_screen.dart';

// See welcome_screen.dart — Apple sign-in is only wired up on iOS.
bool get _appleSignInAvailable => !kIsWeb && Platform.isIOS;

// ─────────────────────────────────────────────────────────────────────────────
// RegisterScreen — Google (one tap) or name + email + password.
//
// Guests upgrading keep their session (link, not a new account).
// [popOnSuccess] — return to the calling screen (checkout gate) on success.
// ─────────────────────────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.popOnSuccess = false});
  final bool popOnSuccess;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _emailFocus  = FocusNode();
  final _passFocus   = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading     = false;
  bool _googleLoading = false;
  bool _appleLoading  = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool get _busy => _isLoading || _googleLoading || _appleLoading;

  void _onSuccess() {
    HapticFeedback.lightImpact();
    if (widget.popOnSuccess) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    }
  }

  void _showError(String msg) {
    if (msg.isEmpty) return;
    showAppSnackbar(context, msg,
        type: AppSnackbarType.error, duration: const Duration(seconds: 4));
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _busy) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final lang = context.read<LanguageProvider>();
    final success = await auth.register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      _onSuccess();
    } else {
      setState(() => _isLoading = false);
      _showError(auth.error ?? lang.tr('register_failed'));
    }
  }

  Future<void> _handleGoogle() async {
    if (_busy) return;
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      _onSuccess();
    } else {
      setState(() => _googleLoading = false);
      _showError(auth.error ?? '');
    }
  }

  Future<void> _handleApple() async {
    if (_busy) return;
    setState(() => _appleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithApple();
    if (!mounted) return;
    if (ok) {
      _onSuccess();
    } else {
      setState(() => _appleLoading = false);
      _showError(auth.error ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c       = AppColors.of(context);
    final isGuest = context.watch<AuthProvider>().isGuest;
    final lang    = context.watch<LanguageProvider>();

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
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BrandLockup(logoSize: 72, wordmarkSize: 24),
                      const SizedBox(height: 20),
                      Text(
                        isGuest ? lang.tr('save_progress') : lang.tr('create_free_account'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSerif(
                            fontSize: 23, fontWeight: FontWeight.w600, color: c.t1),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isGuest ? lang.tr('guest_register_sub') : lang.tr('register_subtitle'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13.5, color: c.t2, height: 1.45),
                      ),
                      if (isGuest) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: c.goldSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.gold.withValues(alpha: 0.22)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified_user_outlined, color: c.gold, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(lang.tr('guest_session_notice'),
                                    style: GoogleFonts.inter(
                                        color: c.t2, fontSize: 12, height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      AuthSocialButton(
                        kind: AuthProviderKind.google,
                        label: lang.tr('continue_with_google'),
                        loading: _googleLoading,
                        disabled: _busy && !_googleLoading,
                        onTap: _handleGoogle,
                      ),
                      if (_appleSignInAvailable) ...[
                        const SizedBox(height: 12),
                        AuthSocialButton(
                          kind: AuthProviderKind.apple,
                          label: lang.tr('continue_with_apple'),
                          loading: _appleLoading,
                          disabled: _busy && !_appleLoading,
                          onTap: _handleApple,
                        ),
                      ],
                      const SizedBox(height: 20),
                      AuthOrDivider(label: lang.tr('or_label')),
                      const SizedBox(height: 20),

                      AuthTextField(
                        label: lang.tr('full_name'),
                        controller: _nameCtrl,
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return lang.tr('name_required');
                          if (t.length < 2) return lang.tr('name_too_short');
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        label: lang.tr('email'),
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        onFieldSubmitted: (_) => _passFocus.requestFocus(),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return lang.tr('email_required');
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
                            return lang.tr('email_invalid');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        label: lang.tr('password'),
                        controller: _passCtrl,
                        focusNode: _passFocus,
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        autofillHints: const [AutofillHints.newPassword],
                        helperText: lang.tr('password_min'),
                        onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return lang.tr('password_required');
                          if (v.length < 6) return lang.tr('password_min');
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        label: lang.tr('confirm_password'),
                        controller: _confirmCtrl,
                        focusNode: _confirmFocus,
                        icon: Icons.lock_reset_rounded,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleRegister(),
                        validator: (v) =>
                            v != _passCtrl.text ? lang.tr('password_mismatch') : null,
                      ),
                      const SizedBox(height: 24),
                      AuthPrimaryButton(
                        label: lang.tr('create_account'),
                        loading: _isLoading,
                        disabled: _busy && !_isLoading,
                        onTap: _handleRegister,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(lang.tr('have_account'),
                              style: GoogleFonts.inter(fontSize: 13, color: c.t2)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    LoginScreen(popOnSuccess: widget.popOnSuccess),
                              ),
                            ),
                            child: Text(lang.tr('sign_in'),
                                style: GoogleFonts.inter(
                                  color: c.gold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        lang.tr('by_continuing'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 10.5, color: c.t3.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
