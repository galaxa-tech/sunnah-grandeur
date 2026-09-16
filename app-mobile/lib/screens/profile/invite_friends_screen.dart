import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_snackbar.dart';
import '../../providers/language_provider.dart';

// The app has no per-user referral-code system yet — every user shares the
// same real, live link rather than a fabricated personalized one.
const _shareLink = 'https://sunnah-grandeur-app.web.app';
String _shareMsg(LanguageProvider lang) => '${lang.tr('share_msg_body')}\n$_shareLink';

Future<void> _openShareUrl(BuildContext context, Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    showAppSnackbar(context, context.read<LanguageProvider>().tr('could_not_open_app'), type: AppSnackbarType.error);
  }
}

class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Row(
                children: [
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
                        Text(lang.tr('invite_friends'), style: AppTextStyles.heading(c, fontSize: 19)),
                        Text(lang.tr('share_sunnah_grandeur_caps'), style: AppTextStyles.brandTag(c)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    // Illustration card
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 14),
                      padding: const EdgeInsets.all(24),
                      decoration: c.goldCardDecoration.copyWith(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.gold.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AvatarCircle(idx: 0, c: c),
                              _AvatarCircle(idx: 1, c: c),
                              _AvatarCircle(idx: 2, c: c),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(lang.tr('spread_the_khair'), style: AppTextStyles.displayMd(c).copyWith(fontSize: 22)),
                          const SizedBox(height: 8),
                          Text(lang.tr('spread_khair_body'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(c, size: 12).copyWith(height: 1.6),
                          ),
                        ],
                      ),
                    ),

                    _EyeRow(label: lang.tr('your_invite_link_caps'), c: c),

                    // Referral link
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: c.surf,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: c.bd2),
                            ),
                            child: Text(_shareLink, style: AppTextStyles.bodyMuted(c, size: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(const ClipboardData(text: _shareLink));
                            showAppSnackbar(context, lang.tr('link_copied'),
                                type: AppSnackbarType.success,
                                duration: const Duration(seconds: 1));
                          },
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: c.goldSurface,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: c.gold.withValues(alpha: 0.22)),
                            ),
                            child: Icon(Icons.copy_rounded, color: c.gold, size: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    _EyeRow(label: lang.tr('share_via_caps'), c: c),

                    // Share options
                    Row(
                      children: [
                        _ShareOption(
                          emoji: '💬', label: 'WhatsApp', c: c,
                          onTap: () => _openShareUrl(context,
                              Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_shareMsg(lang))}')),
                        ),
                        const SizedBox(width: 8),
                        _ShareOption(
                          emoji: '✈️', label: 'Telegram', c: c,
                          onTap: () => _openShareUrl(context,
                              Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent(_shareLink)}&text=${Uri.encodeComponent(lang.tr('share_msg_body'))}')),
                        ),
                        const SizedBox(width: 8),
                        _ShareOption(
                          emoji: '📧', label: 'Email', c: c,
                          onTap: () => _openShareUrl(context,
                              Uri(scheme: 'mailto', queryParameters: {
                                'subject': lang.tr('sunnah_grandeur_app_label'),
                                'body': _shareMsg(lang),
                              })),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Share Button
                    GestureDetector(
                      onTap: () => Share.share(_shareMsg(lang), subject: lang.tr('sunnah_grandeur_app_label')),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: c.goldGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: c.gold.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_rounded, color: c.bg, size: 18),
                            const SizedBox(width: 8),
                            Text(lang.tr('share_app_link'), style: AppTextStyles.button(c).copyWith(color: const Color(0xFF0D0D0F))),
                          ],
                        ),
                      ),
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

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.idx, required this.c});
  final int idx;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    // Slight overlap
    return Container(
      width: 44, height: 44,
      margin: EdgeInsets.only(right: idx < 2 ? -8 : 0),
      decoration: BoxDecoration(
        color: idx == 0 ? c.surf : idx == 1 ? c.elev : const Color(0xFF1C1C20),
        shape: BoxShape.circle,
        border: Border.all(color: c.bg, width: 2),
      ),
      child: Center(
        child: Icon(Icons.person_outline_rounded, 
          color: idx == 0 ? c.gold : idx == 1 ? c.t3 : const Color(0xFF52504C), 
          size: 20
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({required this.emoji, required this.label, required this.c, required this.onTap});
  final String emoji, label;
  final AppColors c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: c.surf,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.bd),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.bodyMuted(c, size: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EyeRow extends StatelessWidget {
  const _EyeRow({required this.label, required this.c});
  final String label;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.brandTag(c)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [c.gold.withValues(alpha: 0.2), Colors.transparent])))),
        ],
      ),
    );
  }
}
