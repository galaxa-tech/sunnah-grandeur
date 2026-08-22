import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../services/adhan_service.dart';
import '../services/notification_service.dart';

class PrayerProvider extends ChangeNotifier {
  PrayerTimes? _prayerTimes;
  Position?    _currentPosition;
  bool         _isLoading = true;
  String?      _locationError;
  DateTime?    _lastCalculatedDate;

  // Override coordinates (set from LocationProvider via ProxyProvider)
  double? _overrideLat;
  double? _overrideLng;

  PrayerTimes? get prayerTimes     => _prayerTimes;
  Position?    get currentPosition => _currentPosition;
  bool         get isLoading       => _isLoading;
  String?      get locationError   => _locationError;

  PrayerProvider() {
    init();
  }

  /// Called by ProxyProvider when LocationProvider has coordinates.
  void updateCoordinates(double lat, double lng) {
    if (_overrideLat == lat && _overrideLng == lng) return;
    _overrideLat = lat;
    _overrideLng = lng;
    _recalculate(DateTime.now());
    _scheduleServices();
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // If we already have override coordinates from LocationProvider, use them.
    if (_overrideLat != null && _overrideLng != null) {
      _recalculate(DateTime.now());
    } else {
      try {
        _currentPosition = await _determinePosition();
        _recalculate(DateTime.now());
      } catch (e) {
        debugPrint('[PrayerProvider] init: $e');
        _recalculate(DateTime.now()); // recalculate with fallback coords
      }
    }

    _isLoading = false;
    notifyListeners();
    _scheduleServices();
  }

  void _recalculate(DateTime date) {
    final lat = _overrideLat ?? _currentPosition?.latitude  ?? 51.5074;
    final lng = _overrideLng ?? _currentPosition?.longitude ?? -0.1278;

    final coordinates = Coordinates(lat, lng);
    final params      = CalculationMethod.muslim_world_league.getParameters();
    params.madhab     = Madhab.hanafi;

    _prayerTimes        = PrayerTimes.today(coordinates, params);
    _lastCalculatedDate = date;
  }

  /// Schedules adhan timer and notification alerts for today's prayers.
  void _scheduleServices() {
    if (_prayerTimes == null) return;

    final nextTime = getNextPrayerTime();
    if (nextTime != null) {
      AdhanService.instance.scheduleAdhanAt(nextTime);
    }

    // Build prayer schedule for today
    final pt = _prayerTimes!;
    final schedule = <({String name, DateTime time})>[
      (name: 'Fajr',    time: pt.fajr),
      (name: 'Dhuhr',   time: pt.dhuhr),
      (name: 'Asr',     time: pt.asr),
      (name: 'Maghrib', time: pt.maghrib),
      (name: 'Isha',    time: pt.isha),
    ];

    NotificationService.instance.schedulePrayerAlerts(schedule);
  }

  /// Returns prayer times for any given date using the current position.
  PrayerTimes? timesForDate(DateTime date) {
    final lat = _overrideLat ?? _currentPosition?.latitude  ?? 51.5074;
    final lng = _overrideLng ?? _currentPosition?.longitude ?? -0.1278;

    try {
      final coordinates = Coordinates(lat, lng);
      final params      = CalculationMethod.muslim_world_league.getParameters();
      params.madhab     = Madhab.hanafi;
      return PrayerTimes(coordinates, DateComponents.from(date), params);
    } catch (e) {
      return null;
    }
  }

  void refreshIfNewDay() {
    final today = DateTime.now();
    if (_lastCalculatedDate == null ||
        _lastCalculatedDate!.day != today.day) {
      _recalculate(today);
      _scheduleServices();
      notifyListeners();
    }
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
      case Prayer.fajr:    return 'Fajr';
      case Prayer.sunrise: return 'Sunrise';
      case Prayer.dhuhr:   return 'Dhuhr';
      case Prayer.asr:     return 'Asr';
      case Prayer.maghrib: return 'Maghrib';
      case Prayer.isha:    return 'Isha';
      case Prayer.none:    return '---';
    }
  }

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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
    } catch (e) {
      debugPrint('[PrayerProvider] location: $e');
      _locationError = 'Could not get location — using London fallback.';
      return null;
    }
  }
}
