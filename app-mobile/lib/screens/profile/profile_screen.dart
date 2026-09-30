import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/net_image.dart';
import '../../config/app_info.dart';
import '../../models/adhan_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/adhan_settings_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/location_provider.dart';
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
import 'support_us_screen.dart';
import '../store/order_history_screen.dart';

/// Opens a page of the public storefront (policies, support) in the browser.
/// Store review requires these to be reachable from inside the app.
Future<void> _openSitePage(String path) =>
    launchUrl(Uri.parse('https://sunnahgrandeur.com$path'),
        mode: LaunchMode.externalApplication);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final c = AppColors.of(context);
    final lang = context.read<LanguageProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.elev,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(lang.tr('sign_out_q'), style: AppTextStyles.heading(c, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.tr('cancel'), style: TextStyle(color: c.t2)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.tr('sign_out')),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil('/welcome', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c             = AppColors.of(context);
    final lang          = context.watch<LanguageProvider>();
    final themeNotifier = context.watch<ThemeNotifier>();
    final auth          = context.watch<AuthProvider>();
    final adhanSettings = context.watch<AdhanSettingsProvider>().settings;
    final location       = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lang.tr('profile'), style: AppTextStyles.brand(c)),
                Text(lang.tr('your_islamic_journey'), style: AppTextStyles.brandTag(c)),
              ]),
            ),

            // Profile card
            _ProfileCard(c: c, auth: auth, lang: lang),

            // Stats bar
            _StatsBar(c: c, lang: lang),

            // Guest upgrade card
            if (auth.isGuest) const _GuestCta(),

            EyeRow(label: lang.tr('settings')),

            _MenuSection(c: c, items: [
              if (auth.hasAccount)
                _MenuItem(icon: Icons.receipt_long_outlined,
                    label: lang.tr('my_orders'),
                    sub: lang.tr('my_orders_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                ),
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
                  sub: location.hasLocation ? location.locationLabel : lang.tr('location_default'),
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
                  sub:   _languageDisplayName(lang.langCode),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen())),
              ),
              _MenuItem(icon: Icons.calculate_outlined,
                  label: lang.tr('prayer_method'),
                  sub:   '${calcMethodShortLabel(adhanSettings.calcMethodIndex)} · ${madhabShortLabel(adhanSettings.madhabIndex)}',
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
              _MenuItem(icon: Icons.volunteer_activism_outlined,
                  label: lang.tr('support_us'),
                  sub:   lang.tr('support_us_sub'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportUsScreen())),
              ),
            ]),

            EyeRow(label: lang.tr('legal_help')),

            _MenuSection(c: c, items: [
              _MenuItem(icon: Icons.help_outline_rounded,
                  label: lang.tr('help_support'),
                  sub:   lang.tr('help_support_sub'),
                  onTap: () => _openSitePage('/support'),
              ),
              _MenuItem(icon: Icons.privacy_tip_outlined,
                  label: lang.tr('privacy_policy'),
                  sub:   lang.tr('privacy_policy_sub'),
                  onTap: () => _openSitePage('/privacy-policy'),
              ),
              _MenuItem(icon: Icons.description_outlined,
                  label: lang.tr('terms_of_service'),
                  sub:   lang.tr('terms_of_service_sub'),
                  onTap: () => _openSitePage('/terms-of-service'),
              ),
              _MenuItem(icon: Icons.no_accounts_outlined,
                  label: lang.tr('delete_account_info'),
                  sub:   lang.tr('delete_account_info_sub'),
                  onTap: () => _openSitePage('/account-deletion'),
              ),
            ]),

            // Sign in / Sign out
            Container(
              margin: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              width: double.infinity,
              child: auth.isGuest
                  ? AuthPrimaryButton(
                      label: lang.tr('sign_in_create_account'),
                      icon: Icons.login_rounded,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen())),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context),
                      icon: Icon(Icons.logout_rounded, color: c.red, size: 16),
                      label: Text(lang.tr('sign_out'),
                          style: AppTextStyles.body(c, color: c.red, size: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.red.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
            ),

            // Version footer
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Column(children: [
                Image.asset('assets/images/logo.png', width: 36, height: 36),
                const SizedBox(height: 6),
                Text('${lang.tr('app_name')} v$kAppVersion',
                    style: AppTextStyles.bodyMuted(c, size: 11)),
                Text(lang.tr('by_sunnah_grandeur'),
                    style: AppTextStyles.bodyMuted(c, size: 10)),
              ]),
            ),
          ]),
        ),
      ),
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

// Real current language name — matches the codes used by LanguageProvider
// and LanguageSettingsScreen ('en' / 'ar' / 'bn').
String _languageDisplayName(String code) {
  switch (code) {
    case 'ar': return 'Arabic';
    case 'bn': return 'Bangla';
    default:   return 'English';
  }
}

// ── Profile header card ──────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.c, required this.auth, required this.lang});
  final AppColors c;
  final AuthProvider auth;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    final user = auth.firebaseUser;
    final guest = auth.isGuest || user == null;
    final name = guest
        ? lang.tr('guest_user')
        : (auth.userData?.name.isNotEmpty == true
            ? auth.userData!.name
            : (user.displayName ?? user.email?.split('@').first ?? ''));
    final email = guest ? '' : (user.email ?? auth.userData?.email ?? '');
    final photo = guest ? null : user.photoURL;
    final since = user?.metadata.creationTime;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1C05), Color(0xFF5A4012), Color(0xFF8B6824)],
        ),
        border: Border.all(color: c.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: c.gold.withValues(alpha: c.isDark ? 0.18 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFFF3DE9B), Color(0xFFC9A84C)]),
          ),
          child: ClipOval(
            child: Container(
              color: const Color(0xFF1A1206),
              alignment: Alignment.center,
              child: auth.isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE6C364)))
                  : photo != null && photo.isNotEmpty
                      ? NetImage(photo, width: 65, height: 65)
                      : guest || initials.isEmpty
                          ? const Icon(Icons.person_rounded, color: Color(0xFFE6C364), size: 34)
                          : Text(initials,
                              style: GoogleFonts.cormorantGaramond(
                                  fontSize: 28, fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF3DE9B))),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSerif(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(guest ? Icons.explore_outlined : Icons.verified_rounded,
                    size: 13, color: guest ? Colors.white70 : const Color(0xFF7DD4A8)),
                const SizedBox(width: 5),
                Text(
                  guest
                      ? lang.tr('guest_label')
                      : since != null
                          ? '${lang.tr('member_since')} ${since.year}'
                          : lang.tr('verified_member'),
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Guest call-to-action ─────────────────────────────────────────────────────
class _GuestCta extends StatefulWidget {
  const _GuestCta();

  @override
  State<_GuestCta> createState() => _GuestCtaState();
}

class _GuestCtaState extends State<_GuestCta> {
  bool _loading = false;

  Future<void> _google() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    final msg = auth.error ?? '';
    if (!ok && msg.isNotEmpty) {
      showAppSnackbar(context, msg, type: AppSnackbarType.error);
    } else if (ok) {
      showAppSnackbar(context, context.read<LanguageProvider>().tr('signed_in_welcome'),
          type: AppSnackbarType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    Widget perk(IconData i, String k) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Icon(i, size: 16, color: c.gold),
            const SizedBox(width: 8),
            Expanded(child: Text(lang.tr(k), style: AppTextStyles.body(c, size: 12.5, color: c.t2))),
          ]),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.gold.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(lang.tr('guest_cta_title'),
            style: GoogleFonts.notoSerif(fontSize: 16, fontWeight: FontWeight.w700, color: c.t1)),
        const SizedBox(height: 10),
        perk(Icons.shopping_bag_outlined, 'guest_perk_orders'),
        perk(Icons.sync_rounded, 'guest_perk_sync'),
        perk(Icons.bookmark_outline_rounded, 'guest_perk_bookmarks'),
        const SizedBox(height: 8),
        AuthSocialButton(
          kind: AuthProviderKind.google,
          label: lang.tr('continue_with_google'),
          loading: _loading,
          onTap: _google,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: Text(lang.tr('create_account_with_email'),
              style: AppTextStyles.body(c, size: 13, color: c.gold, weight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
