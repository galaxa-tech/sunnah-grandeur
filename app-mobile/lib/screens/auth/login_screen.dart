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
import 'register_screen.dart';
import 'forgot_password_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen — Google + email/password sign-in.
//
// [popOnSuccess] — when pushed from an in-app gate (checkout, orders), pop
// back to where the user was instead of resetting to /main, so the cart /
// checkout flow continues seamlessly.
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.popOnSuccess = false});
  final bool popOnSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _passFocus  = FocusNode();

  bool _emailLoading  = false;
  bool _googleLoading = false;

  bool get _busy => _emailLoading || _googleLoading;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _onSuccess() {
    HapticFeedback.lightImpact();
    if (widget.popOnSuccess) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _busy) return;

    setState(() => _emailLoading = true);
    final auth = context.read<AuthProvider>();
    final lang = context.read<LanguageProvider>();
    final success = await auth.signIn(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      _onSuccess();
    } else {
      setState(() => _emailLoading = false);
      showAppSnackbar(context, auth.error ?? lang.tr('login_failed'),
          type: AppSnackbarType.error, duration: const Duration(seconds: 4));
    }
  }

  Future<void> _handleGoogle() async {
    if (_busy) return;
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      _onSuccess();
    } else {
      setState(() => _googleLoading = false);
      final msg = auth.error ?? '';
      if (msg.isNotEmpty) {
        showAppSnackbar(context, msg,
            type: AppSnackbarType.error, duration: const Duration(seconds: 4));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

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
                      const BrandLockup(logoSize: 76, wordmarkSize: 26),
                      const SizedBox(height: 22),
                      Text(lang.tr('welcome_back'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSerif(
                              fontSize: 24, fontWeight: FontWeight.w600, color: c.t1)),
                      const SizedBox(height: 6),
                      Text(lang.tr('login_subtitle'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13.5, color: c.t2)),
                      const SizedBox(height: 28),

                      AuthSocialButton(
                        kind: AuthProviderKind.google,
                        label: lang.tr('continue_with_google'),
                        loading: _googleLoading,
                        disabled: _busy && !_googleLoading,
                        onTap: _handleGoogle,
                      ),
                      const SizedBox(height: 20),
                      AuthOrDivider(label: lang.tr('or_label')),
                      const SizedBox(height: 20),

                      AuthTextField(
                        label: lang.tr('email'),
                        controller: _emailCtrl,
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
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (v) => (v == null || v.isEmpty)
                            ? lang.tr('password_required')
                            : null,
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen())),
                          child: Text(lang.tr('forgot_password'),
                              style: GoogleFonts.inter(
                                  color: c.gold,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AuthPrimaryButton(
                        label: lang.tr('sign_in'),
                        loading: _emailLoading,
                        disabled: _busy && !_emailLoading,
                        onTap: _handleLogin,
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(lang.tr('no_account'),
                              style: GoogleFonts.inter(fontSize: 13, color: c.t2)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RegisterScreen(
                                    popOnSuccess: widget.popOnSuccess),
                              ),
                            ),
                            child: Text(lang.tr('create_account'),
                                style: GoogleFonts.inter(
                                  color: c.gold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                        ],
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
