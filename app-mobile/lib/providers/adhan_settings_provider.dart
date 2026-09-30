import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adhan_settings.dart';

/// Persists and exposes [AdhanSettings].
///
/// Any change to settings triggers [notifyListeners], which PrayerProvider
/// listens to for rescheduling alarms.
class AdhanSettingsProvider extends ChangeNotifier {
  static const _prefsKey = 'adhan_settings_v3';

  AdhanSettings _settings = AdhanSettings.defaults;
  bool          _loaded   = false;

  AdhanSettings get settings => _settings;
  bool          get loaded   => _loaded;

  AdhanSettingsProvider() {
    _loadFromPrefs();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        _settings = AdhanSettings.fromJsonString(raw);
        debugPrint('[AdhanSettingsProvider] loaded settings.');
      }
    } catch (e) {
      debugPrint('[AdhanSettingsProvider] load error: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _settings.toJsonString());
    } catch (e) {
      debugPrint('[AdhanSettingsProvider] save error: $e');
    }
  }

  // ── Mutation helpers ─────────────────────────────────────────────────────

  Future<void> update(AdhanSettings Function(AdhanSettings) fn) async {
    _settings = fn(_settings);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> setEnabled(bool v) =>
      update((s) => s.copyWith(enabled: v));

  Future<void> setPrayerEnabled(String prayer, bool v) => update((s) {
        final prayers = Map<String, bool>.from(s.prayers);
        prayers[prayer] = v;
        return s.copyWith(prayers: prayers);
      });

  Future<void> setSound(String key) =>
      update((s) => s.copyWith(soundKey: key));

  Future<void> setVolume(double v) =>
      update((s) => s.copyWith(volume: v));

  static const _userChoseKey = 'calc_method_user_set';

  Future<void> setCalcMethod(int index) async {
    await _markUserChoice();
    await update((s) => s.copyWith(calcMethodIndex: index));
  }

  Future<void> setMadhab(int index) async {
    await _markUserChoice();
    await update((s) => s.copyWith(madhabIndex: index));
  }

  Future<void> _markUserChoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userChoseKey, true);
    } catch (_) {}
  }

  /// Picks the calculation method + Asr madhab most used where the user is,
  /// unless they already chose one themselves. Called once location is known.
  ///
  ///   South Asia (BD/PK/IN)  → Karachi, Hanafi
  ///   Arabian Peninsula      → Umm al-Qura, Shafi'i (standard)
  ///   Egypt / North Africa   → Egyptian, Shafi'i
  ///   North America          → ISNA, Shafi'i
  ///   South-East Asia        → Singapore, Shafi'i
  ///   elsewhere              → Muslim World League, Shafi'i
  Future<void> applyRegionalDefaults(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_userChoseKey) ?? false) return;
    } catch (_) {}
    int method = 0; // MWL
    int madhab = 1; // Shafi'i / standard
    if (lng >= 60 && lng <= 97 && lat >= 5 && lat <= 37) {
      method = 3; madhab = 0; // Karachi, Hanafi
    } else if (lng >= 34 && lng < 60 && lat >= 12 && lat <= 32) {
      method = 1; // Umm al-Qura
    } else if (lng >= -18 && lng < 34 && lat >= 15 && lat <= 37) {
      method = 2; // Egyptian
    } else if (lng >= -170 && lng <= -50 && lat >= 15 && lat <= 72) {
      method = 4; // ISNA
    } else if (lng > 97 && lng <= 141 && lat >= -11 && lat <= 20) {
      method = 7; // Singapore
    }
    await update((s) => s.copyWith(calcMethodIndex: method, madhabIndex: madhab));
  }

  Future<void> setVibrate(bool v) =>
      update((s) => s.copyWith(vibrate: v));

  Future<void> setPreAdhanReminder(bool v) =>
      update((s) => s.copyWith(preAdhanReminder: v));
}
