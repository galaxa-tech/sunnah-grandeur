// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WelcomeScreen — premium minimal onboarding gateway.
//
// Flow:
//   ① Continue with Google  →  Firebase Google Auth → clears stack → /main
//   ② Continue as Guest     →  anonymous sign-in    → clears stack → /main
//   ③ Sign In with Email    →  pushes LoginScreen
//   ④ Create Account        →  pushes RegisterScreen
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
  bool _guestLoading  = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _onGoogle() async {
    if (_googleLoading || _guestLoading) return;
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithGoogle();
    if (!mounted) return;

    if (ok) {
      // Clear entire navigator stack, land cleanly on ShellScreen.
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } else {
      setState(() => _googleLoading = false);
      final msg = auth.error ?? '';
      if (msg.isNotEmpty) _showError(msg);
    }
  }

  Future<void> _onGuest() async {
    if (_googleLoading || _guestLoading) return;
    setState(() => _guestLoading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInAsGuest();
    if (!mounted) return;

    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } else {
      setState(() => _guestLoading = false);
      _showError(auth.error ?? 'Could not enter as guest. Check your connection.');
    }
  }

  void _onSignIn() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));

  void _onRegister() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const RegisterScreen()));

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: const Color(0xFF1F1F23),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final busy = _googleLoading || _guestLoading;

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

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      _buildHero(c),
                      const Spacer(flex: 2),
                      _buildActions(c, busy),
                      const SizedBox(height: 28),
                      _buildFooter(c),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero(AppColors c) {
    return Column(
      children: [
        // Gold mosque badge
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: c.goldGradient,
            boxShadow: [
              BoxShadow(
                color: c.gold.withValues(alpha: 0.32),
                blurRadius: 36,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text('🕌', style: TextStyle(fontSize: 40)),
          ),
        ),

        const SizedBox(height: 24),

        // App name with gold shimmer
        ShaderMask(
          shaderCallback: (bounds) => c.goldGradient.createShader(bounds),
          child: Text(
            'Sunnah Grandeur',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Arabic bismillah
        Text(
          'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيم',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 16,
            color: c.gold.withValues(alpha: 0.70),
            height: 1.6,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Your complete Islamic lifestyle companion',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: c.t3,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActions(AppColors c, bool busy) {
    return Column(
      children: [
        // ── 1. Continue with Google ────────────────────────────────────────
        // Dark surface, gold border, text only — no icon/logo.
        _AuthButton(
          label: 'Continue with Google',
          loading: _googleLoading,
          disabled: busy && !_googleLoading,
          onTap: _onGoogle,
          style: _AuthButtonStyle.googleDark,
          c: c,
        ),

        const SizedBox(height: 12),

        // ── 2. Continue as Guest ───────────────────────────────────────────
        // Gold gradient — instant frictionless access.
        _AuthButton(
          label: 'Continue as Guest',
          leadingIcon: Icons.arrow_forward_rounded,
          loading: _guestLoading,
          disabled: busy && !_guestLoading,
          onTap: _onGuest,
          style: _AuthButtonStyle.goldFilled,
          c: c,
        ),

        const SizedBox(height: 28),

        // ── Divider ────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(child: Divider(color: c.bd2, thickness: 0.8)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('or',
                  style: GoogleFonts.inter(color: c.t3, fontSize: 12)),
            ),
            Expanded(child: Divider(color: c.bd2, thickness: 0.8)),
          ],
        ),

        const SizedBox(height: 20),

        // ── 3. Sign In with Email ──────────────────────────────────────────
        _AuthButton(
          label: 'Sign In with Email',
          leadingIcon: Icons.mail_outline_rounded,
          loading: false,
          disabled: busy,
          onTap: busy ? () {} : _onSignIn,
          style: _AuthButtonStyle.outline,
          c: c,
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(AppColors c) {
    return Column(
      children: [
        // Register link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account? ",
                style: GoogleFonts.inter(color: c.t3, fontSize: 13)),
            GestureDetector(
              onTap: _onRegister,
              child: Text('Create one',
                style: GoogleFonts.inter(
                  color: c.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Text(
          'By continuing, you agree to our Terms & Privacy Policy.',
          style: GoogleFonts.inter(
            color: c.t3.withValues(alpha: 0.55),
            fontSize: 10.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AuthButton — unified button for all auth actions
// ─────────────────────────────────────────────────────────────────────────────

enum _AuthButtonStyle { googleDark, goldFilled, outline }

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.loading,
    required this.disabled,
    required this.onTap,
    required this.style,
    required this.c,
    this.leadingIcon,
  });

  final String          label;
  final bool            loading;
  final bool            disabled;
  final VoidCallback    onTap;
  final _AuthButtonStyle style;
  final AppColors       c;
  final IconData?       leadingIcon;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration deco;
    final Color textColor;
    final Color? iconColor;

    switch (style) {
      case _AuthButtonStyle.googleDark:
        // Dark surface, subtle gold border — premium, no logo
        deco = BoxDecoration(
          color: c.surf,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.gold.withValues(alpha: 0.45), width: 1.2),
        );
        textColor = c.t1;
        iconColor = null;

      case _AuthButtonStyle.goldFilled:
        // Gold gradient — primary / most frictionless action
        deco = BoxDecoration(
          gradient: c.goldGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: c.gold.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        );
        textColor = const Color(0xFF1A1200); // dark on gold for contrast
        iconColor = const Color(0xFF1A1200);

      case _AuthButtonStyle.outline:
        // Subtle outline, secondary
        deco = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.bd2, width: 1),
        );
        textColor = c.t2;
        iconColor = c.t2;
    }

    return GestureDetector(
      onTap: (disabled || loading) ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: (disabled || loading) ? 0.55 : 1.0,
        child: Container(
          height: 54,
          decoration: deco,
          child: loading
              ? Center(
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          style == _AuthButtonStyle.goldFilled
                              ? const Color(0xFF2D1F00)
                              : c.gold),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 18, color: iconColor ?? textColor),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
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
      ..color       = c.gold.withValues(alpha: 0.04)
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
