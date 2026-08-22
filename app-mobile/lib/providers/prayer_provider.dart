import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/adhan_settings.dart';
import '../services/adhan_service.dart';
import '../services/notification_service.dart';

class PrayerProvider extends ChangeNotifier {
  PrayerTimes? _prayerTimes;
  Position?    _currentPosition;
  bool         _isLoading = true;
  String?      _locationError;
  DateTime?    _lastCalculatedDate;

  // Injected from AdhanSettingsProvider via ProxyProvider
  AdhanSettings _adhanSettings = AdhanSettings.defaults;

  // Override coordinates from LocationProvider
  double? _overrideLat;
  double? _overrideLng;

  PrayerTimes?  get prayerTimes     => _prayerTimes;
  Position?     get currentPosition => _currentPosition;
  bool          get isLoading       => _isLoading;
  String?       get locationError   => _locationError;
  AdhanSettings get adhanSettings   => _adhanSettings;

  PrayerProvider() {
    init();
  }

  // ── Dependency injection ──────────────────────────────────────────────────

  /// Called by ProxyProvider when AdhanSettingsProvider changes.
  void updateSettings(AdhanSettings settings) {
    if (_adhanSettings == settings) return;
    _adhanSettings = settings;
    _recalculate(DateTime.now()); // recalculate with new method/madhab
    _scheduleAll();
    notifyListeners();
  }

  /// Called by ProxyProvider when LocationProvider has coordinates.
  void updateCoordinates(double lat, double lng) {
    if (_overrideLat == lat && _overrideLng == lng) return;
    _overrideLat = lat;
    _overrideLng = lng;
    _recalculate(DateTime.now());
    _scheduleAll();
    notifyListeners();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    if (_overrideLat != null && _overrideLng != null) {
      _recalculate(DateTime.now());
    } else {
      try {
        _currentPosition = await _determinePosition();
        _recalculate(DateTime.now());
      } catch (e) {
        debugPrint('[PrayerProvider] init: $e');
        _recalculate(DateTime.now()); // uses fallback coords
      }
    }

    _isLoading = false;
    notifyListeners();
    await _scheduleAll();
  }

  // ── Prayer time calculation ───────────────────────────────────────────────

  void _recalculate(DateTime date) {
    final lat  = _overrideLat  ?? _currentPosition?.latitude  ?? 51.5074;
    final lng  = _overrideLng  ?? _currentPosition?.longitude ?? -0.1278;

    final coords = Coordinates(lat, lng);
    final params = _adhanSettings.calcParams;

    _prayerTimes        = PrayerTimes.today(coords, params);
    _lastCalculatedDate = date;

    debugPrint('[PrayerProvider] Prayer times recalculated for $date '
        '(method=${_adhanSettings.calcMethodIndex}, '
        'madhab=${_adhanSettings.madhabIndex})');
  }

  PrayerTimes? _timesForDate(DateTime date) {
    final lat  = _overrideLat  ?? _currentPosition?.latitude  ?? 51.5074;
    final lng  = _overrideLng  ?? _currentPosition?.longitude ?? -0.1278;
    try {
      final coords = Coordinates(lat, lng);
      final params = _adhanSettings.calcParams;
      return PrayerTimes(coords, DateComponents.from(date), params);
    } catch (e) {
      debugPrint('[PrayerProvider] timesForDate error: $e');
      return null;
    }
  }

  /// Returns prayer times for any given date (used by calendar views, etc.)
  PrayerTimes? timesForDate(DateTime date) => _timesForDate(date);

  // ── Scheduling ────────────────────────────────────────────────────────────

  /// Schedule Adhan alarms and foreground timer for the next 3 days.
  Future<void> _scheduleAll() async {
    if (_prayerTimes == null) return;

    final now       = DateTime.now();
    final prayerDefs = [
      (name: 'Fajr',    index: 0, fn: (PrayerTimes t) => t.fajr),
      (name: 'Dhuhr',   index: 1, fn: (PrayerTimes t) => t.dhuhr),
      (name: 'Asr',     index: 2, fn: (PrayerTimes t) => t.asr),
      (name: 'Maghrib', index: 3, fn: (PrayerTimes t) => t.maghrib),
      (name: 'Isha',    index: 4, fn: (PrayerTimes t) => t.isha),
    ];

    // Build multi-day alarm schedule (today + 2 more days)
    final prayersByDay = <int, List<PrayerAlarmEntry>>{};

    for (int day = 0; day < 3; day++) {
      final date  = now.add(Duration(days: day));
      final times = (day == 0) ? _prayerTimes! : (_timesForDate(date) ?? _prayerTimes!);

      prayersByDay[day] = prayerDefs
          .map((d) => PrayerAlarmEntry(
                name:  d.name,
                index: d.index,
                time:  d.fn(times),
              ))
          .toList();
    }

    // Schedule background notifications (work even when app is killed)
    await NotificationService.instance.scheduleAlarms(
      prayersByDay: prayersByDay,
      settings:     _adhanSettings,
    );

    // Schedule foreground timer for the next upcoming prayer (app open case)
    final nextTime = getNextPrayerTime();
    if (nextTime != null && _adhanSettings.enabled) {
      AdhanService.instance.scheduleForegroundAdhan(
        nextTime,
        soundKey: _adhanSettings.soundKey,
        volume:   _adhanSettings.volume,
      );
    } else {
      AdhanService.instance.cancelForegroundTimer();
    }

    debugPrint('[PrayerProvider] scheduling complete — '
        '${prayersByDay.values.expand((v) => v).length} entries across '
        '${prayersByDay.length} days.');
  }

  // ── Public API ────────────────────────────────────────────────────────────

  void refreshIfNewDay() {
    final today = DateTime.now();
    if (_lastCalculatedDate == null ||
        _lastCalculatedDate!.day != today.day) {
      _recalculate(today);
      _scheduleAll();
      notifyListeners();
    }
  }

  /// Re-schedule everything (e.g. after settings change, on app resume).
  Future<void> reschedule() async {
    _recalculate(DateTime.now());
    await _scheduleAll();
  }

  String getNextPrayerName() {
    if (_prayerTimes == null) return '---';
    return _formatPrayerName(_prayerTimes!.nextPrayer());
  }

  DateTime? getNextPrayerTime() {
    if (_prayerTimes == null) return null;
    final next = _prayerTimes!.nextPrayer();
    if (next == Prayer.none) return null;
    return _prayerTimes!.timeForPrayer(next);
  }

  String formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('h:mm a').format(dt);
  }

  String _formatPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:    return 'fajr';
      case Prayer.sunrise: return 'sunrise';
      case Prayer.dhuhr:   return 'dhuhr';
      case Prayer.asr:     return 'asr';
      case Prayer.maghrib: return 'maghrib';
      case Prayer.isha:    return 'isha';
      case Prayer.none:    return '---';
    }
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<Position?> _determinePosition() async {
    try {
      if (kIsWeb) {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _locationError = 'Location permission denied — using London fallback.';
          return null;
        }
        return await Geolocator.getCurrentPosition();
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Location services disabled.';
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError = 'Location permission denied.';
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _locationError = 'Location permission permanently denied.';
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      );
    } catch (e) {
      debugPrint('[PrayerProvider] location: $e');
      _locationError = 'Could not get location — using London fallback.';
      return null;
    }
  }
}
