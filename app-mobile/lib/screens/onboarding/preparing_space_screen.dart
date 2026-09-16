import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_motion.dart';
import '../../widgets/illustrations/star_field.dart';
import '../../widgets/illustrations/mosque_silhouette.dart';
import 'welcome_screen.dart';

/// The one deliberate "thoughtful wait" screen in the first-run flow — shown
/// right after onboarding, before landing on WelcomeScreen. Gives the user
/// something to read (a rotating dhikr, same set as TasbeehScreen) while we
/// briefly settle, rather than dropping them straight from the alarm page to
/// a login screen with no transition at all.
class PreparingSpaceScreen extends StatefulWidget {
  const PreparingSpaceScreen({super.key});

  @override
  State<PreparingSpaceScreen> createState() => _PreparingSpaceScreenState();
}

class _PreparingSpaceScreenState extends State<PreparingSpaceScreen> {
  // Same set as TasbeehScreen, for one consistent dhikr vocabulary app-wide.
  static const _dhikrs = ['سبحان الله', 'الحمد لله', 'الله أكبر', 'أستغفر الله'];
  static const _dhikrsEn = ['SubhanAllah', 'Alhamdulillah', 'Allahu Akbar', 'Astaghfirullah'];

  int _dhikrIndex = 0;
  Timer? _rotateTimer;

  @override
  void initState() {
    super.initState();
    _rotateTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() => _dhikrIndex = (_dhikrIndex + 1) % _dhikrs.length);
    });
    Future.delayed(const Duration(milliseconds: 2200), _finish);
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    // Consumed once by ShellScreen on first Home arrival, then cleared —
    // see showOnboardingCelebration / widgets/onboarding_celebration_dialog.dart.
    await prefs.setBool('show_onboarding_celebration', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const c = AppColors.dark;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarField(starCount: 60)),
          const Positioned(
            left: 0, right: 0, bottom: 0, height: 220,
            child: MosqueSilhouette(opacity: 0.7),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44, height: 44,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: c.gold),
                ),
                const SizedBox(height: 28),
                Text('Preparing your space...',
                    style: AppTextStyles.displaySm(c).copyWith(color: c.t1)),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: AppMotion.base,
                  child: Column(
                    key: ValueKey(_dhikrIndex),
                    children: [
                      Text(_dhikrs[_dhikrIndex],
                          style: AppTextStyles.heading(c, fontSize: 20, color: c.gold)),
                      const SizedBox(height: 4),
                      Text(_dhikrsEn[_dhikrIndex], style: AppTextStyles.bodyMuted(c, size: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
