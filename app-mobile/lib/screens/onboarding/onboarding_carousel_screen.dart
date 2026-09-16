import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/adhan_settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_motion.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/illustrations/mosque_silhouette.dart';
import '../../widgets/illustrations/star_field.dart';
import 'preparing_space_screen.dart';

/// The app's real first-run experience: one swipeable carousel (language →
/// location → prayer alerts) over a single full-bleed illustrated
/// background, replacing three previously separate, independently-scaffolded
/// screens. Always rendered in the dark/gold palette regardless of the
/// user's eventual theme choice — a deliberate "premium at dusk" first
/// impression, matching the Pinterest onboarding reference but in this
/// app's own gold-on-charcoal tokens rather than navy.
///
/// IMPORTANT: prior to this, `LanguageOnboardingScreen` / `LocationOnboardingScreen`
/// / `AlarmOnboardingScreen` existed but were never reachable from any actual
/// navigation path in the app (every auth success handler went straight to
/// '/main') — this screen is what actually wires a first-run flow in for the
/// first time. See OnboardingGate in main.dart for how it's entered.
class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() => _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pageCount = 3;

  // ── Language page state ────────────────────────────────────────────────
  static const _langs = [
    {'name': 'English', 'native': 'English', 'code': 'en', 'flag': '🇬🇧'},
    {'name': 'Arabic',  'native': 'العربية',  'code': 'ar', 'flag': '🇸🇦'},
    {'name': 'Bangla',  'native': 'বাংলা',    'code': 'bn', 'flag': '🇧🇩'},
  ];
  int _selectedLang = 0;

  // ── Location page state ────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<CityResult> _suggestions = [];
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // Locale-aware default: pre-select the language matching the device's
    // region/language instead of forcing a manual pick first — the user can
    // still change it on this same page. Falls back to any already-saved
    // preference, then English.
    final saved = context.read<LanguageProvider>().langCode;
    final savedIdx = _langs.indexWhere((l) => l['code'] == saved);
    if (savedIdx >= 0) {
      _selectedLang = savedIdx;
    } else {
      final deviceLang = PlatformDispatcher.instance.locale.languageCode;
      final deviceIdx = _langs.indexWhere((l) => l['code'] == deviceLang);
      if (deviceIdx >= 0) _selectedLang = deviceIdx;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: AppMotion.slow,
      curve: AppMotion.curve,
    );
  }

  Future<void> _onPrimaryCta() async {
    if (_page == 0) {
      await context.read<LanguageProvider>().setLanguage(_langs[_selectedLang]['code']!);
      _goToPage(1);
      return;
    }
    if (_page == 1) {
      final loc = context.read<LocationProvider>();
      if (loc.hasLocation) {
        _goToPage(2);
        return;
      }
      final ok = await loc.useCurrentLocation();
      if (!mounted) return;
      if (ok) {
        _goToPage(2);
      } else if (loc.error != null) {
        showAppSnackbar(context, loc.error!,
            type: AppSnackbarType.error, duration: const Duration(seconds: 3));
      }
      return;
    }
    _finishOnboarding();
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PreparingSpaceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always the dark palette for onboarding, regardless of the user's
    // eventual theme choice (see class doc comment).
    const c = AppColors.dark;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarField(starCount: 50)),
          const Positioned(
            left: 0, right: 0, bottom: 0, height: 260,
            child: MosqueSilhouette(opacity: 0.9),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(c),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _buildLanguagePage(c),
                      _buildLocationPage(c),
                      _buildAlarmsPage(c),
                    ],
                  ),
                ),
                _buildBottomBar(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared chrome ──────────────────────────────────────────────────────

  Widget _buildTopBar(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _page > 0
              ? GestureDetector(
                  onTap: () => _goToPage(_page - 1),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: c.surf.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bd2),
                    ),
                    child: Icon(Icons.chevron_left_rounded, color: c.gold, size: 20),
                  ),
                )
              : const SizedBox(width: 34, height: 34),
          Row(
            children: List.generate(_pageCount, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: AppMotion.base,
                curve: AppMotion.curve,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? c.gold : c.bd2,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          TextButton(
            onPressed: _page == _pageCount - 1 ? null : () => _goToPage(_pageCount - 1),
            child: Opacity(
              opacity: _page == _pageCount - 1 ? 0 : 1,
              child: Text('Skip', style: AppTextStyles.bodyMuted(c, size: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppColors c) {
    final loc = context.watch<LocationProvider>();
    final isLoading = _page == 1 && loc.isLoading;

    String label;
    if (_page == 0) {
      label = '${context.watch<LanguageProvider>().tr('continue_with')} ${_langs[_selectedLang]['name']} →';
    } else if (_page == 1) {
      label = loc.hasLocation ? 'Continue →' : 'Enable Location Access →';
    } else {
      label = 'Get Started →';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GoldButton(
        label: label,
        onTap: isLoading ? null : _onPrimaryCta,
      ),
    );
  }

  Widget _pageHeading(AppColors c, String title, String subtitle) {
    return Column(
      children: [
        Text(title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMd(c).copyWith(color: c.t1)),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.italic(c, fontSize: 12.5, color: c.t2)),
      ],
    );
  }

  // ── Page 1: Language ───────────────────────────────────────────────────

  Widget _buildLanguagePage(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          _pageHeading(c, 'Choose Your Language',
              'You can always change this later in Settings'),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _langs.length,
              itemBuilder: (_, i) {
                final item = _langs[i];
                final isOn = _selectedLang == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLang = i),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isOn ? c.gold.withValues(alpha: 0.10) : c.surf.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isOn ? c.gold.withValues(alpha: 0.4) : c.bd),
                    ),
                    child: Row(children: [
                      Text(item['flag']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name']!, style: AppTextStyles.heading(c, fontSize: 16)),
                            Text(item['native']!, style: AppTextStyles.bodyMuted(c, size: 10)),
                          ],
                        ),
                      ),
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isOn ? c.gold : c.bd2, width: 1.4),
                        ),
                        child: isOn
                            ? Center(
                                child: Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.gold),
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
        ],
      ),
    );
  }

  // ── Page 2: Location ───────────────────────────────────────────────────

  Widget _buildLocationPage(AppColors c) {
    final loc = context.watch<LocationProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          _pageHeading(c, 'Accurate Prayer Times',
              'Grant location access for precise prayer\ntimes and Qibla direction.'),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: loc.isLoading ? null : () => context.read<LocationProvider>().useCurrentLocation(),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: c.surf.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: loc.hasLocation ? c.gold.withValues(alpha: 0.5) : c.bd),
              ),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: c.goldSurface, shape: BoxShape.circle,
                    border: Border.all(color: c.gold.withValues(alpha: 0.3)),
                  ),
                  child: loc.isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(9),
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.gold),
                        )
                      : Icon(Icons.my_location_rounded, color: c.gold, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use Current Location', style: AppTextStyles.label(c, size: 13)),
                      Text(
                        loc.hasLocation ? loc.locationLabel : 'Tap to detect via GPS',
                        style: AppTextStyles.bodyMuted(c, size: 10),
                      ),
                    ],
                  ),
                ),
                if (loc.hasLocation) Icon(Icons.check_circle_rounded, color: c.green, size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            duration: AppMotion.base,
            crossFadeState: _showSearch ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: GestureDetector(
              onTap: () => setState(() => _showSearch = true),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: c.surf.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.bd),
                ),
                child: Row(children: [
                  Icon(Icons.search_rounded, color: c.t3, size: 17),
                  const SizedBox(width: 10),
                  Text('Set City Manually', style: AppTextStyles.body(c, size: 12, color: c.t3)),
                ]),
              ),
            ),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.surf.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.search_rounded, color: c.gold, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        style: AppTextStyles.body(c, size: 13),
                        decoration: InputDecoration(
                          hintText: 'Search city...',
                          hintStyle: AppTextStyles.bodyMuted(c, size: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (q) => setState(() =>
                            _suggestions = context.read<LocationProvider>().searchCities(q)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _showSearch = false;
                        _suggestions = [];
                        _searchCtrl.clear();
                      }),
                      child: Icon(Icons.close_rounded, color: c.t3, size: 15),
                    ),
                  ]),
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: c.surf.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.bd),
                    ),
                    child: Column(
                      children: _suggestions.map((city) => GestureDetector(
                        onTap: () async {
                          await context.read<LocationProvider>().setManualLocation(
                              city.lat, city.lng, city.displayName, timezone: city.timezone);
                          if (!mounted) return;
                          _goToPage(2);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: c.bd, width: 0.5)),
                          ),
                          child: Row(children: [
                            Icon(Icons.location_city_outlined, color: c.t3, size: 14),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(city.city, style: AppTextStyles.body(c, size: 13)),
                                  Text('${city.country} · ${city.coordLabel}',
                                      style: AppTextStyles.bodyMuted(c, size: 10)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: c.t3, size: 16),
                          ]),
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 3: Prayer alerts ──────────────────────────────────────────────

  Widget _buildAlarmsPage(AppColors c) {
    final adhan = context.watch<AdhanSettingsProvider>();
    final settings = adhan.settings;
    final prayerNames = settings.prayers.keys.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          _pageHeading(c, 'Never Miss a Prayer',
              'Enable alerts so we can remind you at\neach prayer time.'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('All Prayer Alerts', style: AppTextStyles.label(c, size: 13)),
              _Toggle(
                value: settings.enabled,
                c: c,
                onChanged: (v) => context.read<AdhanSettingsProvider>().setEnabled(v),
              ),
            ],
          ),
          Divider(color: c.bd, height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: prayerNames.length,
              separatorBuilder: (_, __) => Divider(color: c.bd, height: 1),
              itemBuilder: (_, i) {
                final name = prayerNames[i];
                final val = settings.prayerOn(name) && settings.enabled;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: (val ? c.gold : c.t3).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: (val ? c.gold : c.t3).withValues(alpha: 0.18)),
                      ),
                      child: Icon(Icons.alarm_outlined, color: val ? c.gold : c.t3, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('$name Alert',
                          style: AppTextStyles.body(c, size: 13).copyWith(color: val ? c.t1 : c.t3)),
                    ),
                    _Toggle(
                      value: settings.prayerOn(name),
                      c: c,
                      onChanged: (v) =>
                          context.read<AdhanSettingsProvider>().setPrayerEnabled(name, v),
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated toggle (shared visual, kept local — trivial and single-use) ──
class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.c, required this.onChanged});
  final bool value;
  final AppColors c;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 42, height: 24,
        decoration: BoxDecoration(
          color: value ? c.gold : c.bd2,
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedAlign(
          duration: AppMotion.fast,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
