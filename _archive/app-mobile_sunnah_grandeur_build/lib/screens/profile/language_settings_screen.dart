import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late String _selectedCode;

  static const _langs = [
    {'name': 'English', 'native': 'English · United States', 'code': 'en', 'flag': '🇺🇸'},
    {'name': 'Arabic',  'native': 'Arabic · Saudi Arabia',   'code': 'ar', 'flag': '🇸🇦'},
    {'name': 'Bangla',  'native': 'Bangla · Bangladesh',     'code': 'bn', 'flag': '🇧🇩'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCode = context.read<LanguageProvider>().langCode;
  }

  Future<void> _apply() async {
    await context.read<LanguageProvider>().setLanguage(_selectedCode);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.read<LanguageProvider>().tr('language_updated')),
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
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
                      child: Icon(Icons.arrow_back_ios_rounded,
                          color: c.gold, size: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.tr('language'),
                            style: AppTextStyles.heading(c, fontSize: 19)),
                        Text(lang.tr('interface_language'),
                            style: AppTextStyles.brandTag(c)),
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
                    _EyeRow(label: lang.tr('select_language'), c: c),

                    Column(
                      children: _langs.map((item) {
                        final isAct = _selectedCode == item['code'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCode = item['code']!),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                            decoration: BoxDecoration(
                              color: isAct ? c.goldSurface : c.surf,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isAct
                                    ? c.gold.withOpacity(0.5)
                                    : c.bd2,
                                width: isAct ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(item['flag']!,
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name']!,
                                          style: AppTextStyles.heading(c,
                                                  fontSize: 16)
                                              .copyWith(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                      const SizedBox(height: 1),
                                      Text(item['native']!,
                                          style: AppTextStyles.body(c,
                                              color: isAct
                                                  ? c.gold
                                                  : c.t3,
                                              size: 10.5)),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAct
                                        ? const Color(0xFF4CAF82)
                                        : Colors.transparent,
                                    border: isAct
                                        ? null
                                        : Border.all(
                                            color: c.bd2, width: 1.5),
                                  ),
                                  child: isAct
                                      ? const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 16)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: _apply,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: c.goldGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: c.gold.withValues(alpha: 0.22),
                                blurRadius: 20,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(lang.tr('apply'),
                            style: AppTextStyles.button(c).copyWith(
                                color: const Color(0xFF0D0D0F))),
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
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  c.gold.withOpacity(0.2),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
