import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/brand_lockup.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isLoading) return;
    final lang = context.read<LanguageProvider>();

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.sendPasswordReset(_emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      showAppSnackbar(context, lang.tr('reset_link_sent'),
          type: AppSnackbarType.success, duration: const Duration(seconds: 4));
      Navigator.pop(context);
    } else {
      showAppSnackbar(context, auth.error ?? lang.tr('reset_link_failed'),
          type: AppSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.t2, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandLockup(logoSize: 72, wordmarkSize: 24),
                    const SizedBox(height: 24),
                    Text(lang.tr('reset_password_title'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSerif(
                            fontSize: 23, fontWeight: FontWeight.w600, color: c.t1)),
                    const SizedBox(height: 8),
                    Text(lang.tr('reset_password_sub'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13.5, color: c.t2, height: 1.45)),
                    const SizedBox(height: 28),
                    AuthTextField(
                      label: lang.tr('email'),
                      controller: _emailCtrl,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      onFieldSubmitted: (_) => _handleReset(),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return lang.tr('email_required');
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
                          return lang.tr('email_invalid');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    AuthPrimaryButton(
                      label: lang.tr('send_reset_link'),
                      loading: _isLoading,
                      onTap: _handleReset,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
