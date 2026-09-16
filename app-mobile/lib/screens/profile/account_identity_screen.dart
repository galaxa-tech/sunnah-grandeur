import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_dialog.dart';

class AccountIdentityScreen extends StatefulWidget {
  const AccountIdentityScreen({super.key});

  @override
  State<AccountIdentityScreen> createState() => _AccountIdentityScreenState();
}

class _AccountIdentityScreenState extends State<AccountIdentityScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.userData;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
    );
    setState(() => _isSaving = false);

    if (mounted) {
      final lang = context.read<LanguageProvider>();
      showAppSnackbar(
        context,
        success ? lang.tr('profile_updated_success') : lang.tr('profile_update_failed'),
        type: success ? AppSnackbarType.success : AppSnackbarType.error,
      );
    }
  }

  Future<void> _handleChangePassword() async {
    final auth = context.read<AuthProvider>();
    final lang = context.read<LanguageProvider>();
    final email = auth.firebaseUser?.email;
    if (email == null) return;
    final confirm = await showAppConfirmDialog(
      context,
      title: lang.tr('change_password'),
      message: '${lang.tr('send_reset_link_to_prefix')}$email?',
      confirmLabel: lang.tr('send_link'),
    );
    if (confirm != true) return;
    final success = await auth.sendPasswordReset(email);
    if (!mounted) return;
    showAppSnackbar(
      context,
      success ? '${lang.tr('reset_link_sent_to_prefix')}$email' : lang.tr('failed_send_reset_link'),
      type: success ? AppSnackbarType.success : AppSnackbarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
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
                        Text(lang.tr('account_identity'), style: AppTextStyles.heading(c, fontSize: 19)),
                        Text(lang.tr('personal_information_caps'), style: AppTextStyles.brandTag(c)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSaving ? null : _handleSave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: c.goldSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.gold.withValues(alpha: 0.28)),
                      ),
                      child: _isSaving 
                        ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: c.gold, strokeWidth: 2))
                        : Text(lang.tr('save'), style: AppTextStyles.body(c, color: c.gold, size: 10).copyWith(fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    // Avatar
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 22),
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.goldSurface,
                              border: Border.all(color: c.gold.withValues(alpha: 0.28), width: 1.5),
                            ),
                            child: Icon(Icons.person_outline_rounded, color: c.gold, size: 34),
                          ),
                          const SizedBox(height: 12),
                          Text(auth.userData?.name ?? lang.tr('guest_label'), style: AppTextStyles.displaySm(c).copyWith(fontSize: 18)),
                        ],
                      ),
                    ),

                    _EyeRow(label: lang.tr('personal_details_caps'), c: c),
                    const SizedBox(height: 10),

                    _FormField(label: lang.tr('full_name'), controller: _nameCtrl, c: c, isFocused: true),
                    _FormField(label: lang.tr('email_address'), controller: _emailCtrl, c: c, keyboardType: TextInputType.emailAddress, enabled: false),
                    _FormField(label: lang.tr('phone_number'), controller: _phoneCtrl, c: c, keyboardType: TextInputType.phone),

                    const SizedBox(height: 10),
                    _EyeRow(label: lang.tr('security_caps'), c: c),
                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: _handleChangePassword,
                      child: _SettingsRow(
                        icon: Icons.password_rounded,
                        title: lang.tr('change_password'),
                        sub: auth.firebaseUser?.email != null
                            ? '${lang.tr('send_reset_link_to_prefix')}${auth.firebaseUser!.email}'
                            : lang.tr('no_email_on_account'),
                        c: c,
                      ),
                    ),

                    const SizedBox(height: 10),
                    _EyeRow(label: lang.tr('danger_zone_caps'), c: c),
                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () async {
                        final confirm = await showAppConfirmDialog(
                          context,
                          title: lang.tr('delete_account'),
                          message: lang.tr('delete_account_confirm_body'),
                          confirmLabel: lang.tr('delete'),
                          danger: true,
                        );
                        if (confirm == true) {
                          await auth.deleteAccount();
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: c.red.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: c.red.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: c.red.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: c.red.withValues(alpha: 0.18)),
                              ),
                              child: Icon(Icons.delete_outline_rounded, color: c.red, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(lang.tr('delete_account'), style: AppTextStyles.body(c, color: c.red, size: 13)),
                            ),
                            Icon(Icons.chevron_right_rounded, color: c.red, size: 18),
                          ],
                        ),
                      ),
                    ),
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

class _EyeRow extends StatelessWidget {
  const _EyeRow({required this.label, required this.c});
  final String label;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.brandTag(c)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.gold.withValues(alpha: 0.2), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.isFocused = false,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    required this.c,
  });
  final String label;
  final TextEditingController controller;
  final bool isFocused;
  final TextInputType keyboardType;
  final bool enabled;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.brandTag(c).copyWith(fontSize: 9)),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: c.surf,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isFocused ? c.gold : c.bd2),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  enabled: enabled,
                  style: AppTextStyles.body(c, size: 14).copyWith(color: enabled ? null : c.t3),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (enabled) Icon(Icons.edit_rounded, color: isFocused ? c.gold : c.t3, size: 14),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.c,
  });
  final IconData icon;
  final String title, sub;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: c.bd),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: c.goldSurface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: c.gold.withValues(alpha: 0.14)),
            ),
            child: Icon(icon, color: c.gold, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body(c, size: 13)),
                Text(sub, style: AppTextStyles.bodyMuted(c, size: 10)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.t3, size: 18),
        ],
      ),
    );
  }
}
