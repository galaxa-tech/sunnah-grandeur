import 'package:shared_preferences/shared_preferences.dart';

/// Persists which calendar dates the user has marked as a fasting
/// ("Sawm") day. Follows the same static-methods / SharedPreferences
/// convention as TasbihService, extended to real per-date history
/// instead of the previous single-day-only toggle.
///
/// Keys:
///   fasting_completed_{yyyy-MM-dd} — bool, true if that date was
///                                    marked fasted.
///
/// Note on "streak": this app doesn't track a fixed daily fasting
/// obligation (it's voluntary/Sunnah fasting — e.g. Mondays/Thursdays,
/// Ayyam al-Bid — not a daily-continuity thing like Ramadan). A
/// "current streak" isn't a meaningful or honest concept for that
/// pattern, so we deliberately do NOT surface one here. The real,
/// unambiguous number worth showing is the lifetime total of days
/// fasted.
class FastingService {
  static const _prefix = 'fasting_completed';

  static String _dateKey(DateTime date) =>
      date.toIso8601String().substring(0, 10);
  static String _key(DateTime date) => '${_prefix}_${_dateKey(date)}';

  static Future<bool> isFastedOnDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(date)) ?? false;
  }

  static Future<void> setFasted(DateTime date, bool fasted) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(date);
    if (fasted) {
      await prefs.setBool(key, true);
    } else {
      await prefs.remove(key);
    }
  }

  /// Count of every date ever marked as fasted (the "days fasted" stat).
  static Future<int> getTotalDaysFasted() async {
    final prefs = await SharedPreferences.getInstance();
    var total = 0;
    for (final k in prefs.getKeys()) {
      if (k.startsWith(_prefix) && (prefs.getBool(k) ?? false)) {
        total++;
      }
    }
    return total;
  }

  /// Clears all fasting history.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
