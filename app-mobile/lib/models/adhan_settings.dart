import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';

// ── Sound options ─────────────────────────────────────────────────────────────

@immutable
class AdhanSoundOption {
  final String key;
  final String label;
  final String artist;
  final String assetPath;
  final String rawResource; // Android res/raw/ filename (no extension)

  const AdhanSoundOption({
    required this.key,
    required this.label,
    required this.artist,
    required this.assetPath,
    required this.rawResource,
  });
}

// Real, freely-licensed recordings (see assets/audio/README.md for exact
// source/license/attribution of each file) — no recording here is actually
// from Masjid Al-Haram or Masjid An-Nabawi, so labels don't claim that.
const kAdhanSounds = <AdhanSoundOption>[
  AdhanSoundOption(
    key:         'adhan_classic',
    label:       'Classic Adhan',
    artist:      'Traditional',
    assetPath:   'assets/audio/adhan.mp3',
    rawResource: 'adhan',
  ),
  AdhanSoundOption(
    key:         'adhan_makkah',
    label:       'Adhan — Sabah Fakhry',
    artist:      '1985 recording',
    assetPath:   'assets/audio/adhan_makkah.mp3',
    rawResource: 'adhan_makkah',
  ),
  AdhanSoundOption(
    key:         'adhan_madinah',
    label:       'Adhan — Aaqib Azeez',
    artist:      'Traditional recitation',
    assetPath:   'assets/audio/adhan_madinah.mp3',
    rawResource: 'adhan_madinah',
  ),
];

AdhanSoundOption soundByKey(String key) =>
    kAdhanSounds.firstWhere((s) => s.key == key,
        orElse: () => kAdhanSounds.first);

// ── Calculation method options ────────────────────────────────────────────────

@immutable
class CalcMethodOption {
  final String label;
  final String region;
  final CalculationParameters Function() getParams;
  const CalcMethodOption({
    required this.label,
    required this.region,
    required this.getParams,
  });
}

final kCalcMethods = <CalcMethodOption>[
  CalcMethodOption(
    label:     'Muslim World League',
    region:    'Global / Europe',
    getParams: () => CalculationMethod.muslim_world_league.getParameters(),
  ),
  CalcMethodOption(
    label:     'Umm Al-Qura (Makkah)',
    region:    'Saudi Arabia',
    getParams: () => CalculationMethod.umm_al_qura.getParameters(),
  ),
  CalcMethodOption(
    label:     'Egyptian Authority',
    region:    'Egypt / Africa',
    getParams: () => CalculationMethod.egyptian.getParameters(),
  ),
  CalcMethodOption(
    label:     'University of Karachi',
    region:    'Pakistan / Bangladesh',
    getParams: () => CalculationMethod.karachi.getParameters(),
  ),
  CalcMethodOption(
    label:     'ISNA (North America)',
    region:    'USA / Canada',
    getParams: () => CalculationMethod.north_america.getParameters(),
  ),
  CalcMethodOption(
    label:     'Kuwait',
    region:    'Kuwait',
    getParams: () => CalculationMethod.kuwait.getParameters(),
  ),
  CalcMethodOption(
    label:     'Qatar',
    region:    'Qatar',
    getParams: () => CalculationMethod.qatar.getParameters(),
  ),
  CalcMethodOption(
    label:     'Singapore',
    region:    'Southeast Asia',
    getParams: () => CalculationMethod.singapore.getParameters(),
  ),
];

// Compact abbreviation for [kCalcMethods], used anywhere space is tight
// (e.g. the Next Prayer card's badge). Falls back to the full label.
String calcMethodShortLabel(int index) {
  const short = <int, String>{
    0: 'MWL',
    1: 'Umm al-Qura',
    2: 'Egypt',
    3: 'Karachi',
    4: 'ISNA',
  };
  if (short.containsKey(index)) return short[index]!;
  if (index >= 0 && index < kCalcMethods.length) return kCalcMethods[index].label;
  return 'MWL';
}

// 0 = Hanafi, 1 = Shafi'i/Maliki/Hanbali — see AdhanSettings.madhabIndex.
String madhabShortLabel(int index) => index == 0 ? 'Hanafi' : "Shafi'i";

// ── Prayer index helpers ──────────────────────────────────────────────────────

const kPrayerNames = <String>['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

const kPrayerEmojis = <String, String>{
  'Fajr':    '🌙',
  'Dhuhr':   '☀️',
  'Asr':     '🌤️',
  'Maghrib': '🌅',
  'Isha':    '🌃',
};

// ── AdhanSettings ─────────────────────────────────────────────────────────────

@immutable
class AdhanSettings {
  /// Master Adhan alarm switch.
  final bool enabled;

  /// Per-prayer alarm switches. Keys from [kPrayerNames].
  final Map<String, bool> prayers;

  /// Selected sound key from [kAdhanSounds].
  final String soundKey;

  /// Playback volume (0.0–1.0).
  final double volume;

  /// Index into [kCalcMethods].
  final int calcMethodIndex;

  /// 0 = Hanafi, 1 = Shafi / Maliki / Hanbali.
  final int madhabIndex;

  /// Enable device vibration when alarm fires.
  final bool vibrate;

  /// Show a 10-minute pre-prayer reminder notification.
  final bool preAdhanReminder;

  const AdhanSettings({
    this.enabled          = true,
    required this.prayers,
    this.soundKey         = 'adhan_classic',
    this.volume           = 1.0,
    this.calcMethodIndex  = 0,
    this.madhabIndex      = 0,
    this.vibrate          = true,
    this.preAdhanReminder = false,
  });

  static AdhanSettings get defaults => const AdhanSettings(
        prayers: {
          'Fajr':    true,
          'Dhuhr':   true,
          'Asr':     true,
          'Maghrib': true,
          'Isha':    true,
        },
      );

  bool prayerOn(String name) => prayers[name] ?? true;

  CalculationParameters get calcParams {
    final method =
        kCalcMethods[calcMethodIndex.clamp(0, kCalcMethods.length - 1)];
    final params = method.getParams();
    params.madhab = madhabIndex == 0 ? Madhab.hanafi : Madhab.shafi;
    return params;
  }

  AdhanSettings copyWith({
    bool?              enabled,
    Map<String, bool>? prayers,
    String?            soundKey,
    double?            volume,
    int?               calcMethodIndex,
    int?               madhabIndex,
    bool?              vibrate,
    bool?              preAdhanReminder,
  }) =>
      AdhanSettings(
        enabled:          enabled          ?? this.enabled,
        prayers:          prayers          ?? Map<String, bool>.from(this.prayers),
        soundKey:         soundKey         ?? this.soundKey,
        volume:           volume           ?? this.volume,
        calcMethodIndex:  calcMethodIndex  ?? this.calcMethodIndex,
        madhabIndex:      madhabIndex      ?? this.madhabIndex,
        vibrate:          vibrate          ?? this.vibrate,
        preAdhanReminder: preAdhanReminder ?? this.preAdhanReminder,
      );

  Map<String, dynamic> toJson() => {
        'enabled':          enabled,
        'prayers':          prayers,
        'soundKey':         soundKey,
        'volume':           volume,
        'calcMethodIndex':  calcMethodIndex,
        'madhabIndex':      madhabIndex,
        'vibrate':          vibrate,
        'preAdhanReminder': preAdhanReminder,
      };

  factory AdhanSettings.fromJson(Map<String, dynamic> j) {
    final rawPrayers = (j['prayers'] as Map<String, dynamic>?) ?? {};
    final prayers = {
      for (final k in kPrayerNames) k: (rawPrayers[k] as bool?) ?? true,
    };
    return AdhanSettings(
      enabled:          (j['enabled']          as bool?)   ?? true,
      prayers:          prayers,
      soundKey:         (j['soundKey']         as String?) ?? 'adhan_classic',
      volume:           (j['volume']           as num?)?.toDouble() ?? 1.0,
      calcMethodIndex:  (j['calcMethodIndex']  as int?)    ?? 0,
      madhabIndex:      (j['madhabIndex']      as int?)    ?? 0,
      vibrate:          (j['vibrate']          as bool?)   ?? true,
      preAdhanReminder: (j['preAdhanReminder'] as bool?)   ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static AdhanSettings fromJsonString(String s) {
    try {
      return AdhanSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return AdhanSettings.defaults;
    }
  }
}
