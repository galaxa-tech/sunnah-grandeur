import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _isLoading  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final lang  = context.read<LanguageProvider>();
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.tr('fill_fields'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth    = context.read<AuthProvider>();
    final success = await auth.signIn(email: email, password: pass);

    if (mounted) {
      if (success) {
        Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.tr('login_failed'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(lang.tr('app_name'), style: AppTextStyles.brand(c)),
              const SizedBox(height: 3),
              Text(lang.tr('tagline'), style: AppTextStyles.brandTag(c)),

              const SizedBox(height: 50),
              Text(lang.tr('welcome_back'), style: AppTextStyles.displayMd(c)),
              const SizedBox(height: 8),
              Text(lang.tr('login_subtitle'),
                style: AppTextStyles.italic(c, fontSize: 13),
                textAlign: TextAlign.center),

              const SizedBox(height: 40),

              _AuthField(
                label: lang.tr('email'),
                controller: _emailCtrl,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                c: c,
              ),
              const SizedBox(height: 16),

              _AuthField(
                label: lang.tr('password'),
                controller: _passCtrl,
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                c: c,
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: Text(lang.tr('forgot_password'),
                    style: AppTextStyles.bodyMuted(c, size: 12).copyWith(color: c.gold)),
                ),
              ),

              const SizedBox(height: 24),

              _isLoading
                ? const CircularProgressIndicator()
                : _GoldButton(label: lang.tr('login'), onTap: _handleLogin),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(lang.tr('no_account'), style: AppTextStyles.bodyMuted(c, size: 13)),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text(lang.tr('register_now'),
                      style: AppTextStyles.heading(c, fontSize: 13).copyWith(color: c.gold)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.label,
    required this.controller,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    required this.c,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final AppColors c;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label.toUpperCase(),
            style: AppTextStyles.brandTag(widget.c).copyWith(fontSize: 10)),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: widget.c.surf,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.c.bd2),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: widget.c.gold, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: widget.isPassword && _obscure,
                  keyboardType: widget.keyboardType,
                  style: AppTextStyles.body(widget.c, size: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.isPassword)
                GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: widget.c.t3, size: 18),
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
            BoxShadow(color: c.gold.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 4))
          ],
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.button(c)),
      ),
    );
  }
}
