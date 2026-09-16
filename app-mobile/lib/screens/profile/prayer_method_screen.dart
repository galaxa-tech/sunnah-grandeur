import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/adhan_settings_provider.dart';
import '../../providers/language_provider.dart';

// Maps this screen's method labels to AdhanSettings.calcMethodIndex, which
// indexes into kCalcMethods (see models/adhan_settings.dart).
const _methodIndexByKey = <String, int>{
  'MWL': 0,
  'UmmAlQura': 1,
  'Egypt': 2,
  'Karachi': 3,
  'ISNA': 4,
};
const _methodKeyByIndex = <int, String>{
  0: 'MWL',
  1: 'UmmAlQura',
  2: 'Egypt',
  3: 'Karachi',
  4: 'ISNA',
};

// AdhanSettings.madhabIndex: 0 = Hanafi, 1 = Shafi'i (see model doc comment).
String _madhabKeyFromIndex(int i) => i == 0 ? 'Hanafi' : "Shafi'i";
int _madhabIndexFromKey(String k) => k == 'Hanafi' ? 0 : 1;

const _methodLabels = <String, String>{
  'ISNA': 'ISNA',
  'MWL': 'MWL',
  'Egypt': 'Egyptian Authority',
  'UmmAlQura': 'Umm al-Qura',
  'Karachi': 'Karachi',
};
String _methodLabel(String key) => _methodLabels[key] ?? key;

class PrayerMethodScreen extends StatefulWidget {
  const PrayerMethodScreen({super.key});

  @override
  State<PrayerMethodScreen> createState() => _PrayerMethodScreenState();
}

class _PrayerMethodScreenState extends State<PrayerMethodScreen> {
  late String _calcMethod;
  late String _asrMadhab;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AdhanSettingsProvider>().settings;
    _calcMethod = _methodKeyByIndex[settings.calcMethodIndex] ?? 'ISNA';
    _asrMadhab = _madhabKeyFromIndex(settings.madhabIndex);
  }

  Future<void> _save() async {
    final provider = context.read<AdhanSettingsProvider>();
    await provider.setCalcMethod(_methodIndexByKey[_calcMethod] ?? 4);
    await provider.setMadhab(_madhabIndexFromKey(_asrMadhab));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<LanguageProvider>().tr('prayer_method_saved')), duration: const Duration(seconds: 2)),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) Navigator.pop(context);
    });
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
                        Text(lang.tr('prayer_method'), style: AppTextStyles.heading(c, fontSize: 19)),
                        Text(lang.tr('calculation_madhab_caps'), style: AppTextStyles.brandTag(c)),
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
                    // Info card
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.goldSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.gold.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${lang.tr('current_prefix')}${_methodLabel(_calcMethod)} · $_asrMadhab', style: AppTextStyles.heading(c, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(lang.tr('affects_asr_twilight'), style: AppTextStyles.bodyMuted(c, size: 10.5).copyWith(height: 1.5)),
                        ],
                      ),
                    ),

                    _EyeRow(label: lang.tr('calculation_method'), c: c),

                    Column(
                      children: [
                        _MethodRow(title: 'ISNA', sub: 'Islamic Society of North America', isEq: _calcMethod == 'ISNA', onTap: () => setState(() => _calcMethod = 'ISNA'), c: c),
                        _MethodRow(title: 'Muslim World League', sub: 'MWL, Makkah-based', isEq: _calcMethod == 'MWL', onTap: () => setState(() => _calcMethod = 'MWL'), c: c),
                        _MethodRow(title: 'Egyptian General Authority', sub: 'Egypt / African regions', isEq: _calcMethod == 'Egypt', onTap: () => setState(() => _calcMethod = 'Egypt'), c: c),
                        _MethodRow(title: 'Umm al-Qura (Makkah)', sub: 'Saudi Arabia official', isEq: _calcMethod == 'UmmAlQura', onTap: () => setState(() => _calcMethod = 'UmmAlQura'), c: c),
                        _MethodRow(title: 'Karachi (HEC)', sub: 'Pakistan / South Asia', isEq: _calcMethod == 'Karachi', onTap: () => setState(() => _calcMethod = 'Karachi'), c: c),
                      ],
                    ),

                    _EyeRow(label: lang.tr('asr_madhab_caps'), c: c),
                    
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _asrMadhab = "Shafi'i"),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _asrMadhab == "Shafi'i" ? c.goldSurface : c.surf,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: _asrMadhab == "Shafi'i" ? c.gold.withValues(alpha: 0.35) : c.bd, width: _asrMadhab == "Shafi'i" ? 1.5 : 1),
                              ),
                              child: Row(
                                children: [
                                  _Radio(isActive: _asrMadhab == "Shafi'i", c: c),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Shafi'i", style: AppTextStyles.body(c, size: 12).copyWith(fontWeight: _asrMadhab == "Shafi'i" ? FontWeight.w500 : FontWeight.normal)),
                                        Text(lang.tr('earlier_asr'), style: AppTextStyles.bodyMuted(c, size: 9.5)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _asrMadhab = "Hanafi"),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _asrMadhab == "Hanafi" ? c.goldSurface : c.surf,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: _asrMadhab == "Hanafi" ? c.gold.withValues(alpha: 0.35) : c.bd, width: _asrMadhab == "Hanafi" ? 1.5 : 1),
                              ),
                              child: Row(
                                children: [
                                  _Radio(isActive: _asrMadhab == "Hanafi", c: c),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Hanafi", style: AppTextStyles.body(c, size: 12).copyWith(fontWeight: _asrMadhab == "Hanafi" ? FontWeight.w500 : FontWeight.normal)),
                                        Text(lang.tr('later_asr'), style: AppTextStyles.bodyMuted(c, size: 9.5)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: c.goldGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: c.gold.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: Text(lang.tr('save_prayer_method'), style: AppTextStyles.button(c).copyWith(color: const Color(0xFF0D0D0F))),
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

class _MethodRow extends StatelessWidget {
  const _MethodRow({required this.title, required this.sub, required this.isEq, required this.onTap, required this.c});
  final String title, sub;
  final bool isEq;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isEq ? c.goldSurface : c.surf,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: isEq ? c.gold.withValues(alpha: 0.35) : c.bd, width: isEq ? 1.5 : 1),
        ),
        child: Row(
          children: [
            _Radio(isActive: isEq, c: c),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body(c, size: 13).copyWith(fontWeight: isEq ? FontWeight.w500 : FontWeight.normal)),
                  const SizedBox(height: 1),
                  Text(sub, style: AppTextStyles.bodyMuted(c, size: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.isActive, required this.c});
  final bool isActive;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: isActive ? c.gold : c.bd2, width: 1.5),
      ),
      child: isActive 
        ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: c.gold, shape: BoxShape.circle))) 
        : null,
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
