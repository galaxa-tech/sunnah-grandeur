import 'package:shared_preferences/shared_preferences.dart';

/// Persists which of the 5 daily obligatory prayers the user has marked
/// as completed, per calendar date. Follows the same static-methods /
/// SharedPreferences convention as TasbihService.
///
/// Keys:
///   prayer_tracking_completed_{yyyy-MM-dd} — StringList of completed
///                                             prayer keys for that date
///                                             (e.g. ['fajr', 'dhuhr'])
///
/// Streak rule (documented here since it is genuinely non-obvious):
///   A calendar day only counts toward the streak once ALL 5 prayers are
///   marked done for it. Crucially, *today* is never treated as breaking
///   the streak just because Isha (or any later prayer) hasn't happened
///   yet — an in-progress day is simply not counted yet, it is not a
///   broken streak. So getCurrentStreak() walks backward from today:
///     • if today is already fully completed, it is included in the
///       count and we keep walking backward from yesterday;
///     • if today is not (yet) fully completed, we don't count it and
///       don't penalise it either — we just start walking backward from
///       yesterday.
///   The walk stops at the first day (looking backward) that is not
///   fully completed.
class PrayerTrackingService {
  static const _prefix = 'prayer_tracking_completed';

  /// The 5 obligatory daily prayers tracked for completion (sunrise is
  /// excluded — it isn't a prayer that gets "completed").
  static const List<String> allPrayers = [
    'fajr', 'dhuhr', 'asr', 'maghrib', 'isha',
  ];

  static String _dateKey(DateTime date) =>
      date.toIso8601String().substring(0, 10);
  static String _key(DateTime date) => '${_prefix}_${_dateKey(date)}';

  /// Returns the set of prayer keys marked completed for [date].
  static Future<Set<String>> getCompletedForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(date)) ?? const <String>[]).toSet();
  }

  /// Marks a single prayer done/undone for [date]. Returns the resulting
  /// completed-prayers set for that date.
  static Future<Set<String>> setPrayerCompleted(
    DateTime date,
    String prayerKey, {
    required bool completed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(date);
    final current = (prefs.getStringList(key) ?? const <String>[]).toSet();

    if (completed) {
      current.add(prayerKey);
    } else {
      current.remove(prayerKey);
    }

    if (current.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setStringList(key, current.toList());
    }
    return current;
  }

  /// True if all 5 obligatory prayers are marked done for [date].
  static Future<bool> isDayFullyCompleted(DateTime date) async {
    final completed = await getCompletedForDate(date);
    return allPrayers.every(completed.contains);
  }

  /// Sum of every individual prayer ever marked completed, across every
  /// date ever recorded. This is the "total prayers completed" stat.
  static Future<int> getTotalPrayersCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    var total = 0;
    for (final k in prefs.getKeys()) {
      if (k.startsWith(_prefix)) {
        total += (prefs.getStringList(k) ?? const <String>[]).length;
      }
    }
    return total;
  }

  /// Current consecutive-day streak of fully-completed prayer days.
  /// See the class doc comment above for the exact rule.
  static Future<int> getCurrentStreak() async {
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    var streak = 0;

    if (await isDayFullyCompleted(cursor)) {
      streak = 1;
    }
    cursor = cursor.subtract(const Duration(days: 1));

    while (await isDayFullyCompleted(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Clears all prayer completion data.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
