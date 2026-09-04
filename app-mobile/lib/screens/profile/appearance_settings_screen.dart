import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  String _appIcon = 'Dark Gold';

  String textScaleLabel(double v) {
    if (v <= 0.90) return 'Small';
    if (v <= 1.05) return 'Default';
    if (v <= 1.20) return 'Large';
    return 'Extra Large';
  }

  @override
  Widget build(BuildContext context) {
    final c             = AppColors.of(context);
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark        = themeNotifier.isDark;
    final useSystem     = themeNotifier.mode == ThemeMode.system;
    final textScale     = themeNotifier.textScale;
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
                        Text('Appearance', style: AppTextStyles.heading(c, fontSize: 19)),
                        Text('THEME & DISPLAY', style: AppTextStyles.brandTag(c)),
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
                    _EyeRow(label: 'Theme Mode', c: c),

                    // Theme cards
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.read<ThemeNotifier>().setDark(true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (isDark && !useSystem) ? c.goldSurface : c.surf,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: (isDark && !useSystem) ? c.gold : c.bd, width: (isDark && !useSystem) ? 1.5 : 1),
                              ),
                              child: Column(
                                children: [
                                  // Mock Dark Screen
                                  Container(
                                    height: 70,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D0D0F),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF2E2E34)),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(top: 8, left: 8, width: 40, height: 6, child: Container(decoration: BoxDecoration(color: const Color(0xFF2E2E34), borderRadius: BorderRadius.circular(3)))),
                                        Positioned(top: 20, left: 8, width: 30, height: 4, child: Container(decoration: BoxDecoration(color: const Color(0xFF252528), borderRadius: BorderRadius.circular(2)))),
                                        Positioned(bottom: 10, left: 8, right: 8, height: 18, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [c.gold, c.gold3]), borderRadius: BorderRadius.circular(5)))),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 16, height: 16,
                                        decoration: BoxDecoration(
                                          color: (isDark && !useSystem) ? c.gold : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: (isDark && !useSystem) ? c.gold : c.bd2, width: 1.5),
                                        ),
                                        child: (isDark && !useSystem) ? Icon(Icons.check_rounded, size: 10, color: c.bg) : null,
                                      ),
                                      const SizedBox(width: 7),
                                      Text('Dark Mode', style: AppTextStyles.body(c, size: 12).copyWith(color: (isDark && !useSystem) ? c.gold : c.t3, fontWeight: (isDark && !useSystem) ? FontWeight.w500 : null)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.read<ThemeNotifier>().setDark(false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (!isDark && !useSystem) ? c.goldSurface : c.surf.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: (!isDark && !useSystem) ? c.gold : c.bd, width: (!isDark && !useSystem) ? 1.5 : 1),
                              ),
                              child: Column(
                                children: [
                                  // Mock Light Screen
                                  Container(
                                    height: 70,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F3EA),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFDDD4C0)),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(top: 8, left: 8, width: 40, height: 6, child: Container(decoration: BoxDecoration(color: const Color(0xFFDDD4C0), borderRadius: BorderRadius.circular(3)))),
                                        Positioned(top: 20, left: 8, width: 30, height: 4, child: Container(decoration: BoxDecoration(color: const Color(0xFFEDE7D8), borderRadius: BorderRadius.circular(2)))),
                                        Positioned(bottom: 10, left: 8, right: 8, height: 18, child: Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFA07828), Color(0xFF7A5A18)]), borderRadius: BorderRadius.circular(5)))),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 16, height: 16,
                                        decoration: BoxDecoration(
                                          color: (!isDark && !useSystem) ? c.gold : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: (!isDark && !useSystem) ? c.gold : c.bd2, width: 1.5),
                                        ),
                                        child: (!isDark && !useSystem) ? Icon(Icons.check_rounded, size: 10, color: c.bg) : null,
                                      ),
                                      const SizedBox(width: 7),
                                      Text('Light Mode', style: AppTextStyles.body(c, size: 12).copyWith(color: (!isDark && !useSystem) ? c.gold : c.t3, fontWeight: (!isDark && !useSystem) ? FontWeight.w500 : null)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // System default
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                            child: Icon(Icons.settings_system_daydream_rounded, color: c.gold, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Use System Default', style: AppTextStyles.body(c, size: 13)),
                                Text('Match device appearance', style: AppTextStyles.bodyMuted(c, size: 10)),
                              ],
                            ),
                          ),
                          _Toggle(
                            value: useSystem,
                            onChanged: (v) => v
                                ? context.read<ThemeNotifier>().setSystem()
                                : context.read<ThemeNotifier>().setDark(false),
                            c: c,
                          ),
                        ],
                      ),
                    ),

                    _EyeRow(label: 'Text Size', c: c),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: c.bd),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('A', style: AppTextStyles.bodyMuted(c, size: 10)),
                              Text(textScaleLabel(textScale),
                                  style: AppTextStyles.body(c, size: 14)),
                              Text('A', style: AppTextStyles.bodyMuted(c, size: 18)),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor:   c.gold,
                              inactiveTrackColor: c.bd2,
                              thumbColor:         c.gold,
                              overlayColor:       c.gold.withValues(alpha: 0.1),
                              trackHeight: 2.5,
                            ),
                            child: Slider(
                              value:    textScale,
                              min:      0.85,
                              max:      1.35,
                              divisions: 10,
                              onChanged: (v) => context.read<ThemeNotifier>().setTextScale(v),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _EyeRow(label: 'App Icon', c: c),

                    Row(
                      children: [
                        _AppIconCard(
                          name: 'Dark Gold',
                          isEq: _appIcon == 'Dark Gold',
                          onTap: () => setState(() => _appIcon = 'Dark Gold'),
                          mockIconBg: const LinearGradient(colors: [Color(0xFF1C1204), Color(0xFF0D0D0F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          iconColor: c.gold,
                          borderColor: c.gold.withValues(alpha: 0.3),
                          c: c,
                        ),
                        const SizedBox(width: 10),
                        _AppIconCard(
                          name: 'Light Sand',
                          isEq: _appIcon == 'Light Sand',
                          onTap: () => setState(() => _appIcon = 'Light Sand'),
                          mockIconBg: const LinearGradient(colors: [Color(0xFFF8F3EA), Color(0xFFEDE7D8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          iconColor: const Color(0xFFA07828),
                          borderColor: const Color(0xFFDDD4C0),
                          c: c,
                        ),
                        const SizedBox(width: 10),
                        _AppIconCard(
                          name: 'Emerald',
                          isEq: _appIcon == 'Emerald',
                          onTap: () => setState(() => _appIcon = 'Emerald'),
                          mockIconBg: const LinearGradient(colors: [Color(0xFF0D3520), Color(0xFF061510)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          iconColor: const Color(0xFF4CAF82),
                          borderColor: const Color(0xFF4CAF82).withValues(alpha: 0.2),
                          c: c,
                        ),
                      ],
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

class _AppIconCard extends StatelessWidget {
  const _AppIconCard({
    required this.name, required this.isEq, required this.onTap,
    required this.mockIconBg, required this.iconColor, required this.borderColor,
    required this.c,
  });
  final String name;
  final bool isEq;
  final VoidCallback onTap;
  final Gradient mockIconBg;
  final Color iconColor, borderColor;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEq ? c.goldSurface : c.surf.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isEq ? c.gold.withValues(alpha: 0.5) : c.bd, width: isEq ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Container(
                width: 40, height: 40,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: mockIconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.star_rounded, color: iconColor, size: 22),
              ),
              Text(name, style: AppTextStyles.body(c, color: isEq ? c.gold : c.t3, size: 10).copyWith(fontWeight: isEq ? FontWeight.w500 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged, required this.c});
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44, height: 24,
        decoration: BoxDecoration(color: value ? c.gold : c.bd2, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(width: 16, height: 16, decoration: BoxDecoration(color: value ? c.bg : c.t3, shape: BoxShape.circle)),
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
          Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [c.gold.withValues(alpha: 0.2), Colors.transparent])))),
        ],
      ),
    );
  }
}
