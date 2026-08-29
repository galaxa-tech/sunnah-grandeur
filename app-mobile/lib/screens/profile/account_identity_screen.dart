import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
      showAppSnackbar(
        context,
        success ? 'Profile updated successfully' : 'Failed to update profile',
        type: success ? AppSnackbarType.success : AppSnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
                        Text('Account & Identity', style: AppTextStyles.heading(c, fontSize: 19)),
                        Text('PERSONAL INFORMATION', style: AppTextStyles.brandTag(c)),
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
                        : Text('Save', style: AppTextStyles.body(c, color: c.gold, size: 10).copyWith(fontWeight: FontWeight.w500)),
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
                          Stack(
                            alignment: Alignment.bottomRight,
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
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: c.gold,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: c.bg, width: 2),
                                ),
                                child: Icon(Icons.edit_rounded, color: c.bg, size: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(auth.userData?.name ?? 'Guest', style: AppTextStyles.displaySm(c).copyWith(fontSize: 18)),
                          const SizedBox(height: 3),
                          Text('Tap avatar to change photo', style: AppTextStyles.bodyMuted(c, size: 10)),
                        ],
                      ),
                    ),

                    _EyeRow(label: 'Personal Details', c: c),
                    const SizedBox(height: 10),

                    _FormField(label: 'Full Name', controller: _nameCtrl, c: c, isFocused: true),
                    _FormField(label: 'Email Address', controller: _emailCtrl, c: c, keyboardType: TextInputType.emailAddress),
                    _FormField(label: 'Phone Number', controller: _phoneCtrl, c: c, keyboardType: TextInputType.phone),

                    const SizedBox(height: 10),
                    _EyeRow(label: 'Security', c: c),
                    const SizedBox(height: 10),

                    _SettingsRow(
                      icon: Icons.password_rounded,
                      title: 'Change Password',
                      sub: 'Last changed 30 days ago',
                      c: c,
                    ),

                    const SizedBox(height: 10),
                    _EyeRow(label: 'Danger Zone', c: c),
                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () async {
                        final confirm = await showAppConfirmDialog(
                          context,
                          title: 'Delete Account',
                          message: 'Are you sure you want to permanently delete your account? This action cannot be undone.',
                          confirmLabel: 'Delete',
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
                              child: Text('Delete Account', style: AppTextStyles.body(c, color: c.red, size: 13)),
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
    required this.c,
  });
  final String label;
  final TextEditingController controller;
  final bool isFocused;
  final TextInputType keyboardType;
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
                  style: AppTextStyles.body(c, size: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Icon(Icons.edit_rounded, color: isFocused ? c.gold : c.t3, size: 14),
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
