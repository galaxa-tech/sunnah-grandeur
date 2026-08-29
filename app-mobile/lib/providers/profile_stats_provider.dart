import 'package:flutter/foundation.dart';
import '../services/local/fasting_service.dart';
import '../services/local/tasbih_service.dart';

/// Aggregates the real lifetime stats shown on the Profile screen's
/// stats bar that don't already have a dedicated provider: total days
/// fasted and lifetime tasbih count. (Prayer totals/streak live on
/// PrayerTrackingProvider, since those need live per-prayer completion
/// state too.)
class ProfileStatsProvider extends ChangeNotifier {
  int _daysFasted = 0;
  int _tasbihLifetime = 0;
  bool _isLoading = true;

  int get daysFasted => _daysFasted;
  int get tasbihLifetime => _tasbihLifetime;
  bool get isLoading => _isLoading;

  ProfileStatsProvider() {
    refresh();
  }

  /// Re-reads both stats from local storage. Call this after the user
  /// marks a fasting day or increments their tasbih count elsewhere in
  /// the app, so the Profile screen reflects it next time it's seen.
  Future<void> refresh() async {
    final daysFasted     = await FastingService.getTotalDaysFasted();
    final tasbihLifetime = await TasbihService.getLifetimeTotal();

    _daysFasted = daysFasted;
    _tasbihLifetime = tasbihLifetime;
    _isLoading = false;
    notifyListeners();
  }
}
