// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      showAppSnackbar(context, 'Please enter your email',
          type: AppSnackbarType.error);
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.sendPasswordReset(email);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        showAppSnackbar(context, 'Password reset link sent to your email',
            type: AppSnackbarType.success);
        Navigator.pop(context);
      } else {
        showAppSnackbar(context, 'Failed to send reset link. Please try again.',
            type: AppSnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Brand
              Text('Sunnah Grandeur', style: AppTextStyles.brand(c)),
              const SizedBox(height: 40),
              
              Text('Reset Password', style: AppTextStyles.displayMd(c)),
              const SizedBox(height: 8),
              Text('Enter your email to receive a password reset link', 
                style: AppTextStyles.italic(c, fontSize: 13),
                textAlign: TextAlign.center),

              const SizedBox(height: 40),
              
              _AuthField(
                label: 'Email',
                controller: _emailCtrl,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                c: c,
              ),

              const SizedBox(height: 30),
              
              _isLoading
                ? CircularProgressIndicator(color: c.gold)
                : _GoldButton(
                    label: 'Send Reset Link',
                    onTap: _handleReset,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// Re-using the same localized widgets for consistency
class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    required this.c,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.brandTag(c).copyWith(fontSize: 10)),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: c.surf,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.bd2),
          ),
          child: Row(
            children: [
              Icon(icon, color: c.gold, size: 18),
              const SizedBox(width: 12),
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
            ],
          ),
        ),
      ],
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: c.goldGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: c.gold.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 4))
          ],
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.button(c)),
      ),
    );
  }
}
