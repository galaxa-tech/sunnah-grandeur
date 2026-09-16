import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_motion.dart';
import 'gold_button.dart';

/// One-time "you're all set" payoff shown right after a first-time user
/// finishes onboarding and lands on Home — closes the setup loop the
/// reviewed competitor app also closes with a congratulations + share
/// moment, which this app previously had no equivalent of.
Future<void> showOnboardingCelebration(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Onboarding complete',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: AppMotion.slow,
    pageBuilder: (_, __, ___) => const _CelebrationContent(),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.85 + 0.15 * curved.value, child: child),
      );
    },
  );
}

class _CelebrationContent extends StatelessWidget {
  const _CelebrationContent();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.gold.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: c.gold.withValues(alpha: 0.15), blurRadius: 32, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: c.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: c.gold.withValues(alpha: 0.4), blurRadius: 20),
                  ],
                ),
                child: Icon(Icons.check_rounded,
                    color: c.isDark ? c.bg : Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              Text("You're All Set!",
                  style: AppTextStyles.displaySm(c).copyWith(fontSize: 22)),
              const SizedBox(height: 8),
              Text(
                'Your prayer times, Qibla direction, and alerts are ready. '
                'Welcome to ${lang.tr('app_name')}.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted(c, size: 13).copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
              GoldButton(
                label: "Let's Go",
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Share.share(
                    'I just started using ${lang.tr('app_name')} for prayer times, '
                    'Qibla, and daily reminders — check it out!',
                    subject: lang.tr('app_name'),
                  );
                },
                icon: Icon(Icons.share_outlined, color: c.t2, size: 16),
                label: Text('Share with a friend', style: AppTextStyles.bodyMuted(c, size: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
