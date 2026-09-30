import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/brand_lockup.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

// Sign in with Apple is only offered on iOS — that's the only platform
// wired up on the Apple Developer / Firebase side (App ID capability +
// entitlement), and it's what App Store review requires alongside Google.
bool get _appleSignInAvailable => !kIsWeb && Platform.isIOS;

// ─────────────────────────────────────────────────────────────────────────────
// WelcomeScreen — branded auth choice screen.
//
// Hierarchy (primary → tertiary):
//   ① Continue with Google (+ Apple on iOS) → clears stack → /main
//   ② Sign in / Create account (email)      → Login / Register screens
//   ③ Explore as guest (anonymous)          → clears stack → /main
//
// Navigation note: auth success uses pushNamedAndRemoveUntil('/main', (_) => false)
// to atomically clear the stack and prevent double-ShellScreen issues from
// LandingPage's reactive rebuild fighting with imperative navigation.
// ─────────────────────────────────────────────────────────────────────────────

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _fadeIn;
  late final Animation<Offset>    _slideUp;

  bool _googleLoading = false;
  bool _appleLoading  = false;
  bool _guestLoading  = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _busy => _googleLoading || _appleLoading || _guestLoading;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _onGoogle() async {
    if (_busy) return;
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithGoogle();
    if (!mounted) return;

    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } else {
      setState(() => _googleLoading = false);
      final msg = auth.error ?? '';
      if (msg.isNotEmpty) _showError(msg);
    }
  }

  Future<void> _onApple() async {
    if (_busy) return;
    setState(() => _appleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithApple();
    if (!mounted) return;

    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } else {
      setState(() => _appleLoading = false);
      final msg = auth.error ?? '';
      if (msg.isNotEmpty) _showError(msg);
    }
  }

  Future<void> _onGuest() async {
    if (_busy) return;
    setState(() => _guestLoading = true);
    final auth = context.read<AuthProvider>();
    final lang = context.read<LanguageProvider>();
    final ok   = await auth.signInAsGuest();
    if (!mounted) return;

    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } else {
      setState(() => _guestLoading = false);
      _showError(auth.error ?? lang.tr('guest_failed'));
    }
  }

  void _onSignIn() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));

  void _onRegister() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const RegisterScreen()));

  void _showError(String msg) => showAppSnackbar(context, msg,
      type: AppSnackbarType.error, duration: const Duration(seconds: 4));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          // ── Background geometric decoration ─────────────────────────────
          Positioned(
            top: -size.width * 0.18,
            right: -size.width * 0.28,
            child: _GeometricCircle(size: size.width * 0.90, c: c),
          ),
          Positioned(
            bottom: -size.width * 0.28,
            left: -size.width * 0.22,
            child: _GeometricCircle(size: size.width * 0.80, c: c),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: 440, minHeight: box.maxHeight),
                        child: IntrinsicHeight(child: _content(c, lang)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(AppColors c, LanguageProvider lang) {
    return Column(
      children: [
        const Spacer(flex: 3),
        const SizedBox(height: 24),
        const BrandLockup(logoSize: 112, wordmarkSize: 34),
        const SizedBox(height: 14),
        Text(
          'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيم',
          style: GoogleFonts.amiri(
            fontSize: 17,
            color: c.gold.withValues(alpha: 0.75),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lang.tr('welcome_value'),
          style: GoogleFonts.inter(fontSize: 13.5, color: c.t2, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const Spacer(flex: 3),
        const SizedBox(height: 28),

        // ── Primary: Google (+ Apple on iOS) ─────────────────────────────
        AuthSocialButton(
          kind: AuthProviderKind.google,
          label: lang.tr('continue_with_google'),
          loading: _googleLoading,
          disabled: _busy && !_googleLoading,
          onTap: _onGoogle,
        ),
        if (_appleSignInAvailable) ...[
          const SizedBox(height: 12),
          AuthSocialButton(
            kind: AuthProviderKind.apple,
            label: lang.tr('continue_with_apple'),
            loading: _appleLoading,
            disabled: _busy && !_appleLoading,
            onTap: _onApple,
          ),
        ],
        const SizedBox(height: 18),
        AuthOrDivider(label: lang.tr('or_label')),
        const SizedBox(height: 18),

        // ── Secondary: email ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: AuthPrimaryButton(
                label: lang.tr('sign_in'),
                icon: Icons.mail_outline_rounded,
                outlined: true,
                disabled: _busy,
                onTap: _onSignIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AuthPrimaryButton(
                label: lang.tr('create_account'),
                disabled: _busy,
                onTap: _onRegister,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Tertiary: guest ──────────────────────────────────────────────
        TextButton.icon(
          onPressed: _busy ? null : _onGuest,
          style: TextButton.styleFrom(
            foregroundColor: c.t1,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          icon: _guestLoading
              ? SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c.gold))
              : Icon(Icons.explore_outlined, size: 18, color: c.gold),
          label: Text(
            lang.tr('explore_as_guest'),
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: c.t1,
              decoration: TextDecoration.underline,
              decorationColor: c.gold.withValues(alpha: 0.5),
            ),
          ),
        ),
        Text(
          lang.tr('guest_hint'),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 11.5, color: c.t3, height: 1.4),
        ),
        const SizedBox(height: 18),
        Text(
          lang.tr('by_continuing'),
          style: GoogleFonts.inter(
            color: c.t3.withValues(alpha: 0.7),
            fontSize: 10.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background ornament — Islamic geometric circle pattern
// ─────────────────────────────────────────────────────────────────────────────

class _GeometricCircle extends StatelessWidget {
  const _GeometricCircle({required this.size, required this.c});
  final double    size;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GeomPainter(c: c)),
    );
  }
}

class _GeomPainter extends CustomPainter {
  const _GeomPainter({required this.c});
  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final cx   = size.width  / 2;
    final cy   = size.height / 2;
    final maxR = size.width  / 2;

    final paint = Paint()
      ..color       = c.gold.withValues(alpha: 0.05)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Concentric rings
    for (int i = 1; i <= 7; i++) {
      canvas.drawCircle(Offset(cx, cy), maxR * (i / 7), paint);
    }

    // 8-pointed star lines
    const segments = 8;
    for (int i = 0; i < segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(angle) * maxR, cy + math.sin(angle) * maxR),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GeomPainter old) => false;
}
