import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final lang  = context.read<LanguageProvider>();
    final name  = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass  = _passCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.tr('fill_fields'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth    = context.read<AuthProvider>();
    final success = await auth.register(
      name: name, email: email, phone: phone, password: pass,
    );

    if (mounted) {
      if (success) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.tr('register_failed'))),
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
              const SizedBox(height: 40),
              Text(lang.tr('app_name'), style: AppTextStyles.brand(c)),
              const SizedBox(height: 30),

              Text(lang.tr('create_account'), style: AppTextStyles.displayMd(c)),
              const SizedBox(height: 8),
              Text(lang.tr('register_subtitle'),
                style: AppTextStyles.italic(c, fontSize: 13),
                textAlign: TextAlign.center),

              const SizedBox(height: 30),

              _AuthField(label: lang.tr('name'), controller: _nameCtrl, icon: Icons.person_outline_rounded, c: c),
              const SizedBox(height: 16),
              _AuthField(label: lang.tr('email'), controller: _emailCtrl, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, c: c),
              const SizedBox(height: 16),
              _AuthField(label: 'Phone', controller: _phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone, c: c),
              const SizedBox(height: 16),
              _AuthField(label: lang.tr('password'), controller: _passCtrl, icon: Icons.lock_outline_rounded, isPassword: true, c: c),

              const SizedBox(height: 30),

              _isLoading
                ? const CircularProgressIndicator()
                : _GoldButton(label: lang.tr('register'), onTap: _handleRegister),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(lang.tr('already_account'), style: AppTextStyles.bodyMuted(c, size: 13)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(lang.tr('sign_in'),
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

// Re-using local widgets from login_screen if they are private, or I could move them to a shared widgets folder.
// For simplicity in this single task execution, I'll redefine them or I'll assume I should separate them next time.
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
        Text(widget.label.toUpperCase(), style: AppTextStyles.brandTag(widget.c).copyWith(fontSize: 10)),
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
                  child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, 
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
