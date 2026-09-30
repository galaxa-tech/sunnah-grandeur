import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import 'app_snackbar.dart';
import 'auth_widgets.dart';
import 'brand_lockup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthGate — wraps any widget that requires a real account.
//
//   AuthGate(feature: 'checkout', child: CheckoutScreen())
//
// Real signed-in user → child. Guest / signed out → branded sign-in prompt.
// Sign-in screens are pushed with popOnSuccess, so after signing in the user
// lands straight back here and the gate swaps to the child (cart intact).
// ─────────────────────────────────────────────────────────────────────────────

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.child,
    this.feature = 'this feature',
    this.icon = Icons.lock_outline_rounded,
  });

  final Widget   child;

  /// 'checkout' or 'order history' pick tailored copy; anything else uses
  /// the generic message.
  final String   feature;

  /// Small feature badge shown on the prompt.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.hasAccount) return child;
    return _AuthPromptScreen(feature: feature, icon: icon);
  }
}

class _AuthPromptScreen extends StatefulWidget {
  const _AuthPromptScreen({required this.feature, required this.icon});
  final String   feature;
  final IconData icon;

  @override
  State<_AuthPromptScreen> createState() => _AuthPromptScreenState();
}

class _AuthPromptScreenState extends State<_AuthPromptScreen> {
  bool _googleLoading = false;

  Future<void> _onGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithGoogle();
    if (!mounted) return;
    if (!ok) {
      setState(() => _googleLoading = false);
      final msg = auth.error ?? '';
      if (msg.isNotEmpty) {
        showAppSnackbar(context, msg, type: AppSnackbarType.error);
      }
    }
    // On success AuthProvider notifies → AuthGate rebuilds → shows child.
  }

  void _push(Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    final body = switch (widget.feature) {
      'checkout'      => lang.tr('gate_checkout_body'),
      'order history' => lang.tr('gate_orders_body'),
      _               => lang.tr('guest_register_sub'),
    };

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.t2, size: 18),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const BrandLockup(logoSize: 84, wordmarkSize: 26),
                      Positioned(
                        top: 52,
                        right: 0,
                        left: 70,
                        child: Center(
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.surf,
                              border: Border.all(color: c.gold.withValues(alpha: 0.45)),
                            ),
                            child: Icon(widget.icon, color: c.gold, size: 17),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    lang.tr('gate_title'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSerif(
                        fontSize: 23, fontWeight: FontWeight.w600, color: c.t1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13.5, color: c.t2, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  AuthSocialButton(
                    kind: AuthProviderKind.google,
                    label: lang.tr('continue_with_google'),
                    loading: _googleLoading,
                    onTap: _onGoogle,
                  ),
                  const SizedBox(height: 18),
                  AuthOrDivider(label: lang.tr('or_label')),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: AuthPrimaryButton(
                          label: lang.tr('sign_in'),
                          icon: Icons.mail_outline_rounded,
                          outlined: true,
                          disabled: _googleLoading,
                          onTap: () => _push(const LoginScreen(popOnSuccess: true)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AuthPrimaryButton(
                          label: lang.tr('create_account'),
                          disabled: _googleLoading,
                          onTap: () => _push(const RegisterScreen(popOnSuccess: true)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
