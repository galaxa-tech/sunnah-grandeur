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

  Future<void> setCalcMethod(int index) =>
      update((s) => s.copyWith(calcMethodIndex: index));

  Future<void> setMadhab(int index) =>
      update((s) => s.copyWith(madhabIndex: index));

  Future<void> setVibrate(bool v) =>
      update((s) => s.copyWith(vibrate: v));

  Future<void> setPreAdhanReminder(bool v) =>
      update((s) => s.copyWith(preAdhanReminder: v));
}
