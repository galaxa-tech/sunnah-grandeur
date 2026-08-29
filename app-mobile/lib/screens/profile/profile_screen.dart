import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/sg_pill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/prayer_tracking_provider.dart';
import '../../providers/profile_stats_provider.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import 'account_identity_screen.dart';
import '../prayer_tools/adhan_settings_screen.dart';
import 'location_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'language_settings_screen.dart';
import 'prayer_method_screen.dart';
import 'invite_friends_screen.dart';
import 'rate_app_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c             = AppColors.of(context);
    final lang          = context.watch<LanguageProvider>();
    final themeNotifier = context.watch<ThemeNotifier>();
    final auth          = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lang.tr('profile'), style: AppTextStyles.brand(c)),
                  Text(lang.tr('your_islamic_journey'), style: AppTextStyles.brandTag(c)),
                ]),
                _IconBtn(icon: Icons.settings_outlined, c: c),
              ]),
            ),

            // Profile card
            _ProfileCard(c: c, auth: auth, lang: lang),

            // Stats bar
            _StatsBar(c: c, lang: lang),

            // Guest upgrade banner
            if (auth.isGuest) _GuestBanner(c: c),

            EyeRow(label: lang.tr('settings')),

            _MenuSection(c: c, items: [
              _MenuItem(icon: Icons.person_outline_rounded,
                  label: lang.tr('account_identity'),
                  sub: lang.tr('account_sub'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountIdentityScreen())),
              ),
              _MenuItem(icon: Icons.notifications_outlined,
                  label: lang.tr('notifications'),
                  sub: lang.tr('notifications_sub'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdhanSettingsScreen())),
              ),
              _MenuItem(icon: Icons.location_on_outlined,
                  label: lang.tr('location'),
                  sub: lang.tr('location_default'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationSettingsScreen())),
              ),
            ]),

            EyeRow(label: lang.tr('preferences')),

            _MenuSection(c: c, items: [
              _MenuItem(
                icon:     Icons.wb_sunny_outlined,
                label:    lang.tr('appearance'),
                sub:      themeNotifier.isDark ? lang.tr('dark_mode') : lang.tr('light_mode'),
                trailing: _ThemeToggle(themeNotifier: themeNotifier, c: c),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen())),
              ),
              _MenuItem(icon: Icons.language_outlined,
                  label: lang.tr('language'),
                  sub:   lang.tr('language_english'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen())),
              ),
              _MenuItem(icon: Icons.calculate_outlined,
                  label: lang.tr('prayer_method'),
                  sub:   lang.tr('prayer_method_sub'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerMethodScreen())),
              ),
            ]),

            EyeRow(label: lang.tr('community')),

            _MenuSection(c: c, items: [
              _MenuItem(icon: Icons.share_outlined,
                  label: lang.tr('invite_friends'),
                  sub:   lang.tr('invite_friends_sub'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteFriendsScreen())),
              ),
              _MenuItem(icon: Icons.star_outline_rounded,
                  label: lang.tr('rate_app'),
                  sub:   lang.tr('rate_app_sub'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RateAppScreen())),
              ),
            ]),

            // Sign in / Sign out
            Container(
              margin: const EdgeInsets.fromLTRB(18, 6, 18, 20),
              child: auth.isGuest
                  ? GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: c.goldGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: c.gold.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Sign In / Create Account',
                              style: AppTextStyles.button(c),
                            ),
                          ],
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => auth.signOut(),
                      icon: Icon(Icons.logout_rounded, color: c.red, size: 16),
                      label: Text(lang.tr('sign_out'),
                          style: AppTextStyles.body(c, color: c.red, size: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.red.withValues(alpha: 0.22)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Guest Banner ──────────────────────────────────────────────────────────────
class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.goldSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.gold.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.person_outline_rounded, color: c.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re browsing as a guest',
                  style: GoogleFonts.inter(
                    color: c.t1,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sign in to sync your data across devices.',
                  style: GoogleFonts.inter(
                    color: c.t3,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: c.goldGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Join',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.c, required this.auth, required this.lang});
  final AppColors c;
  final AuthProvider auth;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: c.goldCardDecoration,
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.goldGradient),
          child: auth.isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Center(
                child: Text(
                  auth.userData?.name.isNotEmpty == true
                      ? auth.userData!.name[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.body(c, size: 20, color: Colors.white,
                      weight: FontWeight.w600),
                ),
              ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(auth.userData?.name ?? lang.tr('guest_user'),
                style: AppTextStyles.heading(c, fontSize: 19)),
            const SizedBox(height: 2),
            Text(
              auth.firebaseUser?.isAnonymous == true
                  ? lang.tr('anonymous_account')
                  : lang.tr('verified_member'),
              style: AppTextStyles.bodyMuted(c, size: 10),
            ),
            const SizedBox(height: 7),
            Row(children: [
              SgPill(label: lang.tr('pro_member'), variant: 'gold'),
              const SizedBox(width: 6),
              SgPill(label: lang.tr('active'), variant: 'green'),
            ]),
          ],
        )),
      ]),
    );
  }
}

// ── Stats Bar ─────────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.c, required this.lang});
  final AppColors c;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    // Real, locally-tracked stats — a brand new user with no history
    // simply sees 0s (both providers default their numbers to 0 while
    // their first async load is in flight, so there is no placeholder /
    // crash state to handle here).
    final tracking = context.watch<PrayerTrackingProvider>();
    final stats    = context.watch<ProfileStatsProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: c.surfaceCardDecoration,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _StatCell(c: c, value: '${tracking.totalCompleted}',
            label: lang.tr('prayers_stat')),
        Container(width: 1, height: 40, color: c.bd),
        _StatCell(c: c, value: '${tracking.currentStreak}',
            label: lang.tr('streak')),
        Container(width: 1, height: 40, color: c.bd),
        _StatCell(c: c, value: '${stats.daysFasted}',
            label: lang.tr('days_fasted')),
        Container(width: 1, height: 40, color: c.bd),
        _StatCell(c: c, value: '${stats.tasbihLifetime}',
            label: lang.tr('tasbeeh_stat')),
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.c, required this.value, required this.label});
  final AppColors c;
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: AppTextStyles.displaySm(c).copyWith(fontSize: 22)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.bodyMuted(c, size: 9)),
    ]);
  }
}

// ── Settings section ──────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.c, required this.items});
  final AppColors c;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      decoration: BoxDecoration(
        color: c.isDark ? c.surf : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.bd),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: items.indexed.map((t) {
        final (i, item) = t;
        return Column(children: [
          if (i != 0) Divider(height: 1, color: c.bd),
          item,
        ]);
      }).toList()),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon, required this.label, required this.sub,
    this.trailing, this.onTap,
  });
  final IconData icon;
  final String label, sub;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: c.goldSurface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: c.gold.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, color: c.gold, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.label(c, size: 12.5)),
              Text(sub,   style: AppTextStyles.bodyMuted(c, size: 10)),
            ],
          )),
          trailing ?? Icon(Icons.chevron_right_rounded, color: c.t3, size: 18),
        ]),
      ),
    );
  }
}

// ── Theme Toggle ──────────────────────────────────────────────────────────────
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.themeNotifier, required this.c});
  final ThemeNotifier themeNotifier;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: themeNotifier.toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 42, height: 24,
        decoration: BoxDecoration(
          color: themeNotifier.isDark ? c.gold : c.bd2,
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          alignment: themeNotifier.isDark
              ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Icon Btn ──────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.c});
  final IconData icon;
  final AppColors c;
  @override
  Widget build(BuildContext context) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.bd2)),
    child: Icon(icon, color: c.gold, size: 18),
  );
}
