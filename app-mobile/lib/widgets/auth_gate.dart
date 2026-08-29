import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import 'app_snackbar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthGate — wraps any widget that requires a real account.
//
// Usage:
//   AuthGate(
//     feature: 'checkout',   // shown in the prompt copy
//     child: CheckoutScreen(),
//   )
//
// If the user is signed in with a real account → shows child.
// If the user is a guest or not signed in      → shows upgrade prompt.
// ─────────────────────────────────────────────────────────────────────────────

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.child,
    this.feature = 'this feature',
    this.icon = Icons.lock_outline_rounded,
  });

  /// The child widget to show when the user has a real account.
  final Widget  child;

  /// Human-readable feature name, e.g. 'checkout', 'order history'.
  final String  feature;

  /// Icon shown on the lock screen.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Pass-through: real signed-in user.
    if (auth.hasAccount) return child;

    // Blocked: show upgrade prompt.
    return _AuthPromptScreen(feature: feature, icon: icon);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AuthPromptScreen — premium lock screen shown for guests.
// ─────────────────────────────────────────────────────────────────────────────

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
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithGoogle();
    if (mounted) {
      if (!ok) {
        setState(() => _googleLoading = false);
        showAppSnackbar(context, auth.error ?? 'Google sign-in failed.',
            type: AppSnackbarType.error);
      }
      // On success, AuthProvider notifies → AuthGate rebuilds → shows child.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.goldSurface,
                    border: Border.all(
                        color: c.gold.withOpacity(0.25)),
                  ),
                  child: Icon(widget.icon, color: c.gold, size: 34),
                ),

                const SizedBox(height: 28),

                Text(
                  'Sign in to continue',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: c.t1,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                Text(
                  'You need an account to access ${widget.feature}.\nIt only takes a moment.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.t3,
                    height: 1.55,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // Google button
                _GoogleSignInButton(
                  loading: _googleLoading,
                  onTap: _onGoogle,
                  c: c,
                ),

                const SizedBox(height: 14),

                // Email / Register
                _OutlineButton(
                  label: 'Create Account',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  c: c,
                ),

                const SizedBox(height: 14),

                // Sign in with email
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Already have an account? Sign in',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: c.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
// Local sub-widgets (standalone so they don't leak imports)
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.loading,
    required this.onTap,
    required this.c,
  });
  final bool          loading;
  final VoidCallback  onTap;
  final AppColors     c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: c.isDark ? const Color(0xFFF5F5F5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.bd2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(c.isDark ? 0.22 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(c.gold),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    width: 22, height: 22,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 24,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onTap,
    required this.c,
  });
  final String       label;
  final VoidCallback onTap;
  final AppColors    c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: c.goldGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: c.gold.withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
