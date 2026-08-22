import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/adhan_settings.dart';
import '../../providers/adhan_settings_provider.dart';
import '../../services/adhan_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AdhanSettingsScreen extends StatefulWidget {
  const AdhanSettingsScreen({super.key});

  @override
  State<AdhanSettingsScreen> createState() => _AdhanSettingsScreenState();
}

class _AdhanSettingsScreenState extends State<AdhanSettingsScreen> {
  String? _previewingKey;

  @override
  void dispose() {
    AdhanService.instance.stopPreview();
    super.dispose();
  }

  Future<void> _previewSound(String key, double volume) async {
    await AdhanService.instance.stopPreview();
    setState(() => _previewingKey = key);
    await AdhanService.instance.previewSound(key, volume: volume);
    await Future.delayed(const Duration(seconds: 6));
    if (mounted) setState(() => _previewingKey = null);
  }

  Future<void> _requestPermissionsAndSave(AppColors c) async {
    await NotificationService.instance.requestPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adhan alarms activated.',
              style: AppTextStyles.body(c, size: 13, color: Colors.white)),
          backgroundColor: c.gold.withValues(alpha: 0.85),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c         = AppColors.of(context);
    final sp        = context.watch<AdhanSettingsProvider>();
    final settings  = sp.settings;

    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        slivers: [
          // ── Premium header ─────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(c, settings, sp)),

          // ── Master toggle ──────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildMasterToggle(c, settings, sp)),

          // ── Prayer toggles ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSection(
              c:     c,
              title: 'Prayer Alarms',
              icon:  Icons.access_alarm_rounded,
              child: _PrayerTogglesCard(c: c, settings: settings, sp: sp),
            ),
          ),

          // ── Sound selection ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSection(
              c:     c,
              title: 'Adhan Sound',
              icon:  Icons.music_note_rounded,
              child: _SoundPickerCard(
                c:             c,
                settings:      settings,
                sp:            sp,
                previewingKey: _previewingKey,
                onPreview:     (key) => _previewSound(key, settings.volume),
              ),
            ),
          ),

          // ── Volume ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSection(
              c:     c,
              title: 'Volume',
              icon:  Icons.volume_up_rounded,
              child: _VolumeCard(c: c, settings: settings, sp: sp),
            ),
          ),

          // ── Calculation method ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSection(
              c:     c,
              title: 'Calculation Method',
              icon:  Icons.calculate_rounded,
              child: _CalcMethodCard(c: c, settings: settings, sp: sp),
            ),
          ),

          // ── Madhab ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSection(
              c:     c,
              title: 'Madhab / School',
              icon:  Icons.menu_book_rounded,
              child: _MadhabCard(c: c, settings: settings, sp: sp),
            ),
          ),

          // ── Extra options ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSection(
              c:     c,
              title: 'Additional Options',
              icon:  Icons.tune_rounded,
              child: _ExtrasCard(c: c, settings: settings, sp: sp),
            ),
          ),

          // ── Save / Permissions button ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              child: _GoldButton(
                c:       c,
                label:   'Activate Adhan Alarms',
                icon:    Icons.notifications_active_rounded,
                onTap:   () => _requestPermissionsAndSave(c),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      AppColors c, AdhanSettings settings, AdhanSettingsProvider sp) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1206),
            const Color(0xFF2E1F08),
            c.gold.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          // Nav row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(children: [
              _BackBtn(c: c),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adhan Settings',
                        style: AppTextStyles.brandSmall(c)
                            .copyWith(color: Colors.white)),
                    Text('Prayer alarms & preferences',
                        style: AppTextStyles.brandTag(c)
                            .copyWith(color: Colors.white60)),
                  ],
                ),
              ),
              // Quick enable indicator
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: settings.enabled
                      ? c.gold.withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: settings.enabled
                        ? c.gold.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  settings.enabled ? 'ON' : 'OFF',
                  style: AppTextStyles.cinzelSm(c,
                      color: settings.enabled ? c.gold : Colors.white38,
                      size: 10),
                ),
              ),
            ]),
          ),

          // Mosque icon
          const SizedBox(height: 20),
          Icon(Icons.mosque_rounded,
              color: c.gold.withValues(alpha: 0.55), size: 52),
          const SizedBox(height: 6),
          Text('5 Daily Prayers',
              style: AppTextStyles.cinzelSm(c,
                  color: c.gold, size: 11)
                  .copyWith(letterSpacing: 2.5)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ── Master toggle ─────────────────────────────────────────────────────────

  Widget _buildMasterToggle(
      AppColors c, AdhanSettings settings, AdhanSettingsProvider sp) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: settings.enabled
            ? c.gold.withValues(alpha: 0.08)
            : c.surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: settings.enabled
              ? c.gold.withValues(alpha: 0.30)
              : c.bd,
        ),
      ),
      child: Row(children: [
        Icon(
          settings.enabled
              ? Icons.notifications_active_rounded
              : Icons.notifications_off_rounded,
          color: settings.enabled ? c.gold : c.t3,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Adhan Alarms',
                  style: AppTextStyles.heading(c, fontSize: 15)),
              Text(
                settings.enabled
                    ? 'Adhan will ring at each prayer time'
                    : 'Tap to enable Adhan notifications',
                style: AppTextStyles.bodyMuted(c, size: 11),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value:           settings.enabled,
          onChanged:       (v) => sp.setEnabled(v),
          activeThumbColor: c.gold,
          activeTrackColor: c.gold.withValues(alpha: 0.30),
        ),
      ]),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────

  Widget _buildSection({
    required AppColors c,
    required String    title,
    required IconData  icon,
    required Widget    child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: c.gold, size: 14),
            const SizedBox(width: 6),
            Text(title.toUpperCase(),
                style: AppTextStyles.cinzelSm(c, color: c.t2, size: 9)
                    .copyWith(letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ── Prayer toggles card ───────────────────────────────────────────────────────

class _PrayerTogglesCard extends StatelessWidget {
  final AppColors              c;
  final AdhanSettings          settings;
  final AdhanSettingsProvider  sp;
  const _PrayerTogglesCard(
      {required this.c, required this.settings, required this.sp});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        c.surf,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: c.bd),
      ),
      child: Column(
        children: kPrayerNames.map((name) {
          final isOn  = settings.prayerOn(name);
          final emoji = kPrayerEmojis[name] ?? '🕌';
          final isLast = name == kPrayerNames.last;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AppTextStyles.heading(c, fontSize: 14)),
                      Text(
                        isOn ? 'Alarm enabled' : 'Alarm disabled',
                        style: AppTextStyles.bodyMuted(c, size: 10),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value:     isOn,
                  onChanged: settings.enabled
                      ? (v) => sp.setPrayerEnabled(name, v)
                      : null,
                  activeThumbColor: c.gold,
                  activeTrackColor: c.gold.withValues(alpha: 0.28),
                ),
              ]),
            ),
            if (!isLast)
              Divider(height: 1, color: c.bd, indent: 16, endIndent: 16),
          ]);
        }).toList(),
      ),
    );
  }
}

// ── Sound picker card ─────────────────────────────────────────────────────────

class _SoundPickerCard extends StatelessWidget {
  final AppColors              c;
  final AdhanSettings          settings;
  final AdhanSettingsProvider  sp;
  final String?                previewingKey;
  final void Function(String)  onPreview;

  const _SoundPickerCard({
    required this.c,
    required this.settings,
    required this.sp,
    required this.previewingKey,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        c.surf,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: c.bd),
      ),
      child: Column(
        children: kAdhanSounds.map((sound) {
          final selected = settings.soundKey == sound.key;
          final previewing = previewingKey == sound.key;
          final isLast = sound == kAdhanSounds.last;
          return Column(children: [
            InkWell(
              onTap: () => sp.setSound(sound.key),
              borderRadius: BorderRadius.circular(selected && isLast
                  ? 16
                  : selected
                      ? 0
                      : 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(children: [
                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? c.gold
                          : c.bg,
                      border: Border.all(
                        color: selected ? c.gold : c.bd2,
                        width: selected ? 0 : 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 12)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sound.label,
                            style: AppTextStyles.heading(c,
                                fontSize: 13,
                                color: selected ? c.gold : null)),
                        Text(sound.artist,
                            style: AppTextStyles.bodyMuted(c, size: 10)),
                      ],
                    ),
                  ),
                  // Preview button
                  GestureDetector(
                    onTap: () => onPreview(sound.key),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape:  BoxShape.circle,
                        color:  previewing
                            ? c.gold.withValues(alpha: 0.18)
                            : c.bg,
                        border: Border.all(color: c.bd2),
                      ),
                      child: Icon(
                        previewing
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color:  previewing ? c.gold : c.t3,
                        size:   16,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            if (!isLast)
              Divider(height: 1, color: c.bd, indent: 16, endIndent: 16),
          ]);
        }).toList(),
      ),
    );
  }
}

// ── Volume card ───────────────────────────────────────────────────────────────

class _VolumeCard extends StatelessWidget {
  final AppColors             c;
  final AdhanSettings         settings;
  final AdhanSettingsProvider sp;
  const _VolumeCard(
      {required this.c, required this.settings, required this.sp});

  static IconData _volumeIcon(double v) {
    if (v == 0)   return Icons.volume_off_rounded;
    if (v < 0.4)  return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color:        c.surf,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: c.bd),
      ),
      child: Row(children: [
        Icon(_volumeIcon(settings.volume), color: c.t3, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor:   c.gold,
              inactiveTrackColor: c.bd2,
              thumbColor:         c.gold,
              overlayColor:       c.gold.withValues(alpha: 0.18),
              trackHeight:        3.0,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value:    settings.volume,
              min:      0.0,
              max:      1.0,
              divisions: 10,
              onChanged: (v) => sp.setVolume(v),
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(settings.volume * 100).round()}%',
            style: AppTextStyles.bodyMuted(c, size: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ]),
    );
  }
}

// ── Calculation method card ───────────────────────────────────────────────────

class _CalcMethodCard extends StatelessWidget {
  final AppColors             c;
  final AdhanSettings         settings;
  final AdhanSettingsProvider sp;
  const _CalcMethodCard(
      {required this.c, required this.settings, required this.sp});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        c.surf,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: c.bd),
      ),
      child: Column(
        children: List.generate(kCalcMethods.length, (i) {
          final m        = kCalcMethods[i];
          final selected = settings.calcMethodIndex == i;
          final isLast   = i == kCalcMethods.length - 1;
          return Column(children: [
            InkWell(
              onTap: () => sp.setCalcMethod(i),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:  selected ? c.gold : c.bg,
                      border: Border.all(
                        color: selected ? c.gold : c.bd2,
                        width: selected ? 0 : 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 10)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.label,
                            style: AppTextStyles.body(c,
                                size: 13,
                                color: selected ? c.gold : null)),
                        Text(m.region,
                            style: AppTextStyles.bodyMuted(c, size: 10)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            if (!isLast)
              Divider(height: 1, color: c.bd, indent: 16, endIndent: 16),
          ]);
        }),
      ),
    );
  }
}

// ── Madhab card ───────────────────────────────────────────────────────────────

class _MadhabCard extends StatelessWidget {
  final AppColors             c;
  final AdhanSettings         settings;
  final AdhanSettingsProvider sp;
  const _MadhabCard(
      {required this.c, required this.settings, required this.sp});

  static const _options = [
    (label: 'Hanafi', sub: 'Later Asr time'),
    (label: 'Shafi / Maliki / Hanbali', sub: 'Earlier Asr time'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        c.surf,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: c.bd),
      ),
      child: Column(
        children: List.generate(_options.length, (i) {
          final selected = settings.madhabIndex == i;
          final isLast   = i == _options.length - 1;
          final opt      = _options[i];
          return Column(children: [
            InkWell(
              onTap: () => sp.setMadhab(i),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:  selected ? c.gold : c.bg,
                      border: Border.all(
                        color: selected ? c.gold : c.bd2,
                        width: selected ? 0 : 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 10)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt.label,
                            style: AppTextStyles.body(c,
                                size: 13,
                                color: selected ? c.gold : null)),
                        Text(opt.sub,
                            style: AppTextStyles.bodyMuted(c, size: 10)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            if (!isLast)
              Divider(height: 1, color: c.bd, indent: 16, endIndent: 16),
          ]);
        }),
      ),
    );
  }
}

// ── Extras card ───────────────────────────────────────────────────────────────

class _ExtrasCard extends StatelessWidget {
  final AppColors             c;
  final AdhanSettings         settings;
  final AdhanSettingsProvider sp;
  const _ExtrasCard(
      {required this.c, required this.settings, required this.sp});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        c.surf,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: c.bd),
      ),
      child: Column(children: [
        _OptionRow(
          c:       c,
          icon:    Icons.vibration_rounded,
          label:   'Vibration',
          sub:     'Vibrate device when alarm fires',
          value:   settings.vibrate,
          onChanged: sp.setVibrate,
        ),
        Divider(height: 1, color: c.bd, indent: 16, endIndent: 16),
        _OptionRow(
          c:        c,
          icon:     Icons.alarm_rounded,
          label:    'Pre-Prayer Reminder',
          sub:      'Notification 10 minutes before each prayer',
          value:    settings.preAdhanReminder,
          onChanged: sp.setPreAdhanReminder,
        ),
      ]),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final AppColors       c;
  final IconData        icon;
  final String          label;
  final String          sub;
  final bool            value;
  final void Function(bool) onChanged;

  const _OptionRow({
    required this.c,
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: c.t3, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.heading(c, fontSize: 13)),
              Text(sub,   style: AppTextStyles.bodyMuted(c, size: 10)),
            ],
          ),
        ),
        Switch.adaptive(
          value:           value,
          onChanged:       onChanged,
          activeThumbColor: c.gold,
          activeTrackColor: c.gold.withValues(alpha: 0.28),
        ),
      ]),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _GoldButton extends StatelessWidget {
  final AppColors    c;
  final String       label;
  final IconData     icon;
  final VoidCallback onTap;
  const _GoldButton({
    required this.c,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              c.gold,
              c.gold.withValues(alpha: 0.80),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:      c.gold.withValues(alpha: 0.28),
              blurRadius: 16,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.cinzelSm(c,
                  color: Colors.black87, size: 12)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  final AppColors c;
  const _BackBtn({required this.c});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color:        Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
            border:       Border.all(
                color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: const Icon(Icons.chevron_left_rounded,
              color: Colors.white70, size: 20),
        ),
      );
}
