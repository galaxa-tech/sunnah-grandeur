import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LanguageOnboardingScreen extends StatefulWidget {
  const LanguageOnboardingScreen({super.key});

  @override
  State<LanguageOnboardingScreen> createState() =>
      _LanguageOnboardingScreenState();
}

class _LanguageOnboardingScreenState extends State<LanguageOnboardingScreen> {
  int _selected = 0;

  static const _langs = [
    {'name': 'English', 'native': 'English', 'code': 'en', 'flag': '🇬🇧'},
    {'name': 'Arabic',  'native': 'العربية',  'code': 'ar', 'flag': '🇸🇦'},
    {'name': 'Bangla',  'native': 'বাংলা',    'code': 'bn', 'flag': '🇧🇩'},
  ];

  @override
  void initState() {
    super.initState();
    final saved = context.read<LanguageProvider>().langCode;
    final idx = _langs.indexWhere((l) => l['code'] == saved);
    if (idx >= 0) _selected = idx;
  }

  Future<void> _onContinue() async {
    await context.read<LanguageProvider>().setLanguage(_langs[_selected]['code']!);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboard/location');
  }

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            const SizedBox(height: 30),
            Text('Sunnah Grandeur', style: AppTextStyles.brand(c)),
            const SizedBox(height: 3),
            Text('Living the Prophetic Way', style: AppTextStyles.brandTag(c)),

            const SizedBox(height: 28),

            _GlobeIllustration(c: c),

            const SizedBox(height: 20),
            Text(lang.tr('select_lang'),
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMd(c)),
            const SizedBox(height: 5),
            Text(lang.tr('select_lang_sub'),
                style: AppTextStyles.italic(c, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: _langs.length,
                itemBuilder: (_, i) {
                  final item = _langs[i];
                  final isOn = _selected == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: isOn ? c.gold.withValues(alpha: 0.07) : c.surf,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOn ? c.gold.withValues(alpha: 0.28) : c.bd,
                        ),
                      ),
                      child: Row(children: [
                        Text(item['flag']!,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name']!,
                                style: AppTextStyles.heading(c, fontSize: 16)),
                            Text(item['native']!,
                                style: AppTextStyles.bodyMuted(c, size: 10)),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOn ? c.goldSurface : c.elev,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: isOn
                                    ? c.gold.withValues(alpha: 0.22)
                                    : c.bd2),
                          ),
                          child: Text(item['code']!.toUpperCase(),
                              style: AppTextStyles.cinzelSm(c,
                                  color: isOn ? c.gold : c.t3, size: 9)),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isOn ? c.gold : c.bd2, width: 1.4,
                            ),
                          ),
                          child: isOn
                              ? Center(
                                  child: Container(
                                    width: 10, height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c.gold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            _GoldButton(
              label: '${lang.tr('continue_with')} ${_langs[_selected]['name']} →',
              onTap: _onContinue,
            ),

            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

class _GlobeIllustration extends StatelessWidget {
  const _GlobeIllustration({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: CustomPaint(
        size: const Size(90, 90),
        painter: _GlobePainter(c: c),
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  const _GlobePainter({required this.c});
  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.40;

    canvas.drawCircle(Offset(cx, cy), r,
        Paint()
          ..color = c.gold.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()
          ..color = c.gold.withValues(alpha: 0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);

    final linePaint = Paint()
      ..color = c.gold.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final angle in [-40.0, 0.0, 40.0]) {
      final rad = angle * math.pi / 180;
      final ex = cx + r * math.sin(rad);
      canvas.drawLine(Offset(ex, cy - r * math.cos(rad)),
          Offset(cx, cy + r), linePaint);
    }

    for (final frac in [0.35, 0.65]) {
      final ry = (2 * frac - 1) * r;
      final rx = math.sqrt(math.max(0, r * r - ry * ry));
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + ry),
            width: rx * 1.6,
            height: rx * 0.45),
        linePaint,
      );
    }

    for (var i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5 - math.pi / 2;
      final dx = cx + (r + 10) * math.cos(angle);
      final dy = cy + (r + 10) * math.sin(angle);
      canvas.drawCircle(
          Offset(dx, dy), 2.5, Paint()..color = c.gold.withValues(alpha: 0.38));
    }
  }

  @override
  bool shouldRepaint(_) => false;
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
        height: 48,
        decoration: BoxDecoration(
          gradient: c.goldGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: c.gold.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.button(c)),
      ),
    );
  }
}
