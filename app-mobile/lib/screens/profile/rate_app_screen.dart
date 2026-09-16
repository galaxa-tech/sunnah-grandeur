import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

// TODO: fill in once the App Store Connect listing exists (Apple assigns
// this numeric ID when the app record is created) — until then, iOS users
// who tap Submit just get the in-app "thank you" state with no store
// redirect, rather than a broken link.
const String _kAppStoreNumericId = '';
const String _kAndroidPackageId = 'com.sunnahgrandeur.app';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _rating = 0;
  bool _submitting = false;
  bool _submitted = false;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<LanguageProvider>().tr('tap_star_first'))),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      await FirebaseFirestore.instance.collection('app_feedback').add({
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'userId': auth.firebaseUser?.uid,
        'email': auth.firebaseUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      // Only send happy users on to leave a public store review — a common,
      // low-friction way to avoid a low rating turning into a public 1-star
      // review that a private feedback form could have caught instead.
      if (_rating >= 4) _openStoreListing();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.read<LanguageProvider>().tr('could_not_submit_feedback')}: $e')),
      );
    }
  }

  Future<void> _openStoreListing() async {
    if (kIsWeb) return;
    Uri? uri;
    if (defaultTargetPlatform == TargetPlatform.android) {
      uri = Uri.parse('market://details?id=$_kAndroidPackageId');
    } else if (defaultTargetPlatform == TargetPlatform.iOS &&
        _kAppStoreNumericId.isNotEmpty) {
      uri = Uri.parse(
          'https://apps.apple.com/app/id$_kAppStoreNumericId?action=write-review');
    }
    if (uri == null) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // market:// only resolves if the Play Store app is installed —
        // fall back to the plain web listing URL otherwise.
        if (defaultTargetPlatform == TargetPlatform.android) {
          await launchUrl(
            Uri.parse('https://play.google.com/store/apps/details?id=$_kAndroidPackageId'),
            mode: LaunchMode.externalApplication,
          );
        }
      }
    } catch (_) {
      // Best-effort only — the in-app "thank you" state already shown is a
      // fine outcome on its own if the store app/link isn't available.
    }
  }

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
                        Text(lang.tr('rate_app'), style: AppTextStyles.heading(c, fontSize: 19)),
                        Text(lang.tr('spread_the_khair_caps'), style: AppTextStyles.brandTag(c)),
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
                    const SizedBox(height: 20),
                    // Star icon header
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: c.goldSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.gold.withValues(alpha: 0.22)),
                      ),
                      child: Icon(Icons.star_outline_rounded, color: c.gold, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(lang.tr('enjoying_the_app'), style: AppTextStyles.displayMd(c).copyWith(fontSize: 26)),
                    const SizedBox(height: 10),
                    Text(
                      lang.tr('rating_helps_discover'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted(c, size: 13).copyWith(height: 1.65),
                    ),
                    const SizedBox(height: 28),

                    // Rating stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final isFilled = index < _rating;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(
                              isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                              color: isFilled ? c.gold : c.gold.withValues(alpha: 0.4),
                              size: 44,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),

                    // Review field
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.bd2),
                      ),
                      child: TextField(
                        controller: _reviewController,
                        enabled: !_submitted,
                        maxLines: 4,
                        minLines: 3,
                        style: AppTextStyles.body(c, size: 13),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                          hintText: lang.tr('rate_app_hint'),
                          hintStyle: AppTextStyles.bodyMuted(c, size: 12).copyWith(height: 1.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Action Button
                    GestureDetector(
                      onTap: (_submitting || _submitted) ? null : _submit,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: _submitted ? null : c.goldGradient,
                          color: _submitted ? c.surf : null,
                          borderRadius: BorderRadius.circular(16),
                          border: _submitted ? Border.all(color: c.bd2) : null,
                          boxShadow: _submitted ? null : [BoxShadow(color: c.gold.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: _submitting
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.gold))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_submitted ? Icons.check_rounded : Icons.thumb_up_rounded, color: _submitted ? c.gold : c.bg, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _submitted ? lang.tr('feedback_sent') : lang.tr('submit_feedback'),
                                    style: AppTextStyles.button(c).copyWith(color: _submitted ? c.gold : const Color(0xFF0D0D0F)),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _submitted ? lang.tr('jazakallah_khair') : lang.tr('feedback_goes_to_team'),
                      style: AppTextStyles.bodyMuted(c, size: 12),
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
