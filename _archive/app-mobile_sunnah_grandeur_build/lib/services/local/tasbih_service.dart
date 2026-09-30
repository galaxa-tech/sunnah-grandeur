import 'package:shared_preferences/shared_preferences.dart';

/// Persists tasbih counter state to local storage.
/// Data is keyed per dhikr so each zikr has its own lifetime count and rounds.
///
/// Keys:
///   tasbih_count_{dhikr}    — running total taps for this dhikr (all time)
///   tasbih_rounds_{dhikr}   — completed rounds (target reached)
///   tasbih_today_{dhikr}    — today's tap count (resets at midnight)
///   tasbih_today_date       — ISO date string for midnight-reset logic
class TasbihService {
  static const _prefix       = 'tasbih';
  static const _todayDateKey = '${_prefix}_today_date';

  static String _countKey(String dhikr)  => '${_prefix}_count_$dhikr';
  static String _roundsKey(String dhikr) => '${_prefix}_rounds_$dhikr';
  static String _todayKey(String dhikr)  => '${_prefix}_today_$dhikr';

  /// Loads the full persisted state for a given dhikr.
  static Future<TasbihState> load(String dhikr) async {
    final prefs = await SharedPreferences.getInstance();
    _resetTodayCountIfNeeded(prefs, dhikr);

    return TasbihState(
      dhikr:      dhikr,
      totalCount: prefs.getInt(_countKey(dhikr))  ?? 0,
      rounds:     prefs.getInt(_roundsKey(dhikr)) ?? 0,
      todayCount: prefs.getInt(_todayKey(dhikr))  ?? 0,
    );
  }

  /// Increments the tap count by 1 and handles round completion.
  /// Returns the updated state.
  static Future<TasbihState> increment(
    String dhikr, {
    required int target,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _resetTodayCountIfNeeded(prefs, dhikr);

    final total = (prefs.getInt(_countKey(dhikr))  ?? 0) + 1;
    final today = (prefs.getInt(_todayKey(dhikr))  ?? 0) + 1;
    int rounds  =  prefs.getInt(_roundsKey(dhikr)) ?? 0;

    if (total % target == 0) rounds++;

    await Future.wait([
      prefs.setInt(_countKey(dhikr),  total),
      prefs.setInt(_todayKey(dhikr),  today),
      prefs.setInt(_roundsKey(dhikr), rounds),
    ]);

    return TasbihState(
      dhikr:      dhikr,
      totalCount: total,
      rounds:     rounds,
      todayCount: today,
    );
  }

  /// Resets the session counter for a dhikr (not the lifetime total).
  static Future<void> resetSession(String dhikr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_roundsKey(dhikr), 0);
  }

  /// Clears all tasbih data across all dhikrs.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys  = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) await prefs.remove(k);
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  static void _resetTodayCountIfNeeded(SharedPreferences prefs, String dhikr) {
    final today    = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_todayDateKey);
    if (lastDate != today) {
      prefs.setString(_todayDateKey, today);
      prefs.setInt(_todayKey(dhikr), 0);
    }
  }
}

// ── State object ─────────────────────────────────────────────────────────────

class TasbihState {
  final String dhikr;
  final int    totalCount;
  final int    rounds;
  final int    todayCount;

  const TasbihState({
    required this.dhikr,
    required this.totalCount,
    required this.rounds,
    required this.todayCount,
  });

  TasbihState copyWith({int? totalCount, int? rounds, int? todayCount}) =>
      TasbihState(
        dhikr:      dhikr,
        totalCount: totalCount ?? this.totalCount,
        rounds:     rounds     ?? this.rounds,
        todayCount: todayCount ?? this.todayCount,
      );
}
