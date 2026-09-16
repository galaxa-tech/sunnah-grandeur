import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/gold_button.dart';
import '../shop/shop_home_screen.dart';

/// A real support entry point, but honest about what "support" actually
/// means for a for-profit brand rather than a charity: buying from the shop
/// (genuinely funds the business) and sharing the app (genuinely grows it).
/// Deliberately does NOT fabricate a donation/payment flow with no real
/// backend behind it — that would collect goodwill under false pretenses.
class SupportUsScreen extends StatelessWidget {
  const SupportUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: c.surf,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: c.bd2),
                    ),
                    child: Icon(Icons.arrow_back_ios_rounded, color: c.gold, size: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.tr('support_us'), style: AppTextStyles.heading(c, fontSize: 19)),
                      Text(lang.tr('help_us_grow_caps'), style: AppTextStyles.brandTag(c)),
                    ],
                  ),
                ),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: c.goldSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.gold.withValues(alpha: 0.22)),
                      ),
                      child: Icon(Icons.volunteer_activism_outlined, color: c.gold, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text('${lang.tr('support_prefix')}${lang.tr('app_name')}',
                        style: AppTextStyles.displayMd(c).copyWith(fontSize: 24),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(
                      lang.tr('support_body'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted(c, size: 13).copyWith(height: 1.65),
                    ),
                    const SizedBox(height: 28),

                    _SupportCard(
                      c: c,
                      icon: Icons.storefront_outlined,
                      title: lang.tr('shop_with_us'),
                      subtitle: lang.tr('shop_with_us_sub'),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ShopHomeScreen())),
                    ),
                    const SizedBox(height: 12),
                    _SupportCard(
                      c: c,
                      icon: Icons.share_outlined,
                      title: lang.tr('share_the_app'),
                      subtitle: lang.tr('share_the_app_sub'),
                      onTap: () => Share.share(
                        '${lang.tr('share_message_prefix')}${lang.tr('app_name')}${lang.tr('share_message_suffix')}',
                        subject: lang.tr('app_name'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    GoldButton(
                      label: lang.tr('browse_the_shop'),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ShopHomeScreen())),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.c,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final AppColors c;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: c.surfaceCardDecoration,
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: c.goldSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.gold.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: c.gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label(c, size: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodyMuted(c, size: 10.5)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.t3, size: 18),
        ]),
      ),
    );
  }
}
