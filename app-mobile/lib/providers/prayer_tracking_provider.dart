import 'package:flutter/foundation.dart';
import '../services/local/prayer_tracking_service.dart';

/// Tracks which of today's 5 obligatory prayers the user has marked as
/// completed, plus the resulting all-time total and current streak.
///
/// This is intentionally a separate provider from PrayerProvider —
/// PrayerProvider owns prayer *time calculation* (location, calc method,
/// alarms/notifications); this one owns the user's own completion
/// record, which is independent, purely-local persisted state and has
/// no dependency on location/settings.
class PrayerTrackingProvider extends ChangeNotifier {
  Set<String> _todayCompleted = {};
  int _totalCompleted = 0;
  int _currentStreak = 0;
  bool _isLoading = true;

  Set<String> get todayCompleted => _todayCompleted;
  int get totalCompleted => _totalCompleted;
  int get currentStreak => _currentStreak;
  bool get isLoading => _isLoading;

  PrayerTrackingProvider() {
    _load();
  }

  bool isCompleted(String prayerKey) => _todayCompleted.contains(prayerKey);

  Future<void> _load() async {
    final today = DateTime.now();
    final completed = await PrayerTrackingService.getCompletedForDate(today);
    final total     = await PrayerTrackingService.getTotalPrayersCompleted();
    final streak    = await PrayerTrackingService.getCurrentStreak();

    _todayCompleted = completed;
    _totalCompleted = total;
    _currentStreak  = streak;
    _isLoading = false;
    notifyListeners();
  }

  /// Toggles a prayer's completion for today. Updates local state
  /// immediately (optimistic) then persists and refreshes the streak.
  Future<void> togglePrayer(String prayerKey) async {
    final today = DateTime.now();
    final wasCompleted = _todayCompleted.contains(prayerKey);
    final nowCompleted = !wasCompleted;

    // Optimistic local update so the UI reacts instantly.
    final updated = {..._todayCompleted};
    if (nowCompleted) {
      updated.add(prayerKey);
      _totalCompleted += 1;
    } else {
      updated.remove(prayerKey);
      _totalCompleted = _totalCompleted > 0 ? _totalCompleted - 1 : 0;
    }
    _todayCompleted = updated;
    notifyListeners();

    await PrayerTrackingService.setPrayerCompleted(
      today, prayerKey,
      completed: nowCompleted,
    );
    _currentStreak = await PrayerTrackingService.getCurrentStreak();
    notifyListeners();
  }

  /// Re-reads everything from storage (e.g. after a day rolls over).
  Future<void> refresh() => _load();
}
