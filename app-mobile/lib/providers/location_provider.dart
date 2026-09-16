import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CityResult {
  final String city;
  final String country;
  final double lat;
  final double lng;
  /// IANA timezone name (e.g. 'Europe/London'). The `adhan` package always
  /// converts its calculation to whatever timezone the *device* is
  /// currently set to — correct only when the device happens to be in the
  /// same zone as these coordinates. Picking a city the device isn't
  /// physically in needs this to re-zone the result correctly.
  final String timezone;
  const CityResult(this.city, this.country, this.lat, this.lng, this.timezone);
  String get displayName => '$city, $country';
  String get coordLabel {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(1)}°$latDir ${lng.abs().toStringAsFixed(1)}°$lngDir';
  }
}

class LocationProvider extends ChangeNotifier {
  static const _keyLat  = 'loc_lat';
  static const _keyLng  = 'loc_lng';
  static const _keyCity = 'loc_city';
  static const _keyTz   = 'loc_tz';

  double? _lat;
  double? _lng;
  String  _cityName   = '';
  String? _timezone;
  bool    _isLoading  = false;
  String? _error;

  double? get lat       => _lat;
  double? get lng       => _lng;
  String  get cityName  => _cityName;
  bool    get isLoading => _isLoading;
  bool    get hasLocation => _lat != null && _lng != null;
  String? get error     => _error;

  /// The IANA timezone prayer times should be displayed in.
  ///
  /// Returns null when the coordinates came from the device's own GPS —
  /// in that case the device's system timezone already matches the
  /// location, and the `adhan` package's own (device-local) output is
  /// already correct as-is. Returns an explicit zone when a specific city
  /// was chosen (or none has been chosen yet, using the documented
  /// "London (default)" fallback) — cases where the device's own timezone
  /// has no reason to match the coordinates being shown.
  String? get displayTimezone {
    if (_timezone != null) return _timezone;
    if (!hasLocation) return 'Europe/London';
    return null;
  }

  String get locationLabel {
    if (_cityName.isNotEmpty) return _cityName;
    if (_lat != null && _lng != null) {
      final latDir = _lat! >= 0 ? 'N' : 'S';
      final lngDir = _lng! >= 0 ? 'E' : 'W';
      return '${_lat!.abs().toStringAsFixed(1)}°$latDir ${_lng!.abs().toStringAsFixed(1)}°$lngDir';
    }
    return 'London (default)';
  }

  String get coordLabel {
    if (_lat == null || _lng == null) return '51.5°N 0.1°W';
    final latDir = _lat! >= 0 ? 'N' : 'S';
    final lngDir = _lng! >= 0 ? 'E' : 'W';
    return '${_lat!.abs().toStringAsFixed(1)}°$latDir ${_lng!.abs().toStringAsFixed(1)}°$lngDir';
  }

  LocationProvider() {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _lat       = prefs.getDouble(_keyLat);
    _lng       = prefs.getDouble(_keyLng);
    _cityName  = prefs.getString(_keyCity) ?? '';
    _timezone  = prefs.getString(_keyTz);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lat != null) await prefs.setDouble(_keyLat, _lat!);
    if (_lng != null) await prefs.setDouble(_keyLng, _lng!);
    await prefs.setString(_keyCity, _cityName);
    if (_timezone != null) {
      await prefs.setString(_keyTz, _timezone!);
    } else {
      await prefs.remove(_keyTz);
    }
  }

  /// Requests GPS location and saves it. Returns true on success.
  Future<bool> useCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!kIsWeb) {
        final svcEnabled = await Geolocator.isLocationServiceEnabled();
        if (!svcEnabled) {
          _error = 'Location services are disabled. Please enable GPS.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _error = 'Location permission denied.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );

      _lat = pos.latitude;
      _lng = pos.longitude;
      _cityName = coordLabel;
      // GPS coordinates: the device is physically here, so its own system
      // timezone already matches — no explicit re-zoning needed.
      _timezone = null;
      await _persist();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[LocationProvider] GPS error: $e');
      _error = 'Could not get location. Check GPS permissions.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sets a manually chosen location and persists it. Pass the location's
  /// real IANA timezone whenever it's known (e.g. from [searchCities]) so
  /// prayer times display correctly regardless of the device's own zone.
  Future<void> setManualLocation(double lat, double lng, String city, {String? timezone}) async {
    _lat = lat;
    _lng = lng;
    _cityName = city;
    _timezone = timezone;
    _error = null;
    await _persist();
    notifyListeners();
  }

  /// Mock city search — returns up to 6 matching results.
  List<CityResult> searchCities(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    return _cities
        .where((c) =>
            c.city.toLowerCase().startsWith(q) ||
            c.country.toLowerCase().startsWith(q) ||
            c.displayName.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  static const List<CityResult> _cities = [
    CityResult('Mecca', 'Saudi Arabia', 21.3891, 39.8579, 'Asia/Riyadh'),
    CityResult('Medina', 'Saudi Arabia', 24.5247, 39.5692, 'Asia/Riyadh'),
    CityResult('Riyadh', 'Saudi Arabia', 24.7136, 46.6753, 'Asia/Riyadh'),
    CityResult('Jeddah', 'Saudi Arabia', 21.4858, 39.1925, 'Asia/Riyadh'),
    CityResult('Dubai', 'UAE', 25.2048, 55.2708, 'Asia/Dubai'),
    CityResult('Abu Dhabi', 'UAE', 24.4539, 54.3773, 'Asia/Dubai'),
    CityResult('London', 'UK', 51.5074, -0.1278, 'Europe/London'),
    CityResult('Birmingham', 'UK', 52.4862, -1.8904, 'Europe/London'),
    CityResult('Manchester', 'UK', 53.4808, -2.2426, 'Europe/London'),
    CityResult('New York', 'USA', 40.7128, -74.0060, 'America/New_York'),
    CityResult('Chicago', 'USA', 41.8781, -87.6298, 'America/Chicago'),
    CityResult('Los Angeles', 'USA', 34.0522, -118.2437, 'America/Los_Angeles'),
    CityResult('Houston', 'USA', 29.7604, -95.3698, 'America/Chicago'),
    CityResult('Toronto', 'Canada', 43.6532, -79.3832, 'America/Toronto'),
    CityResult('Vancouver', 'Canada', 49.2827, -123.1207, 'America/Vancouver'),
    CityResult('Dhaka', 'Bangladesh', 23.8103, 90.4125, 'Asia/Dhaka'),
    CityResult('Chittagong', 'Bangladesh', 22.3569, 91.7832, 'Asia/Dhaka'),
    CityResult('Sylhet', 'Bangladesh', 24.8949, 91.8687, 'Asia/Dhaka'),
    CityResult('Karachi', 'Pakistan', 24.8607, 67.0011, 'Asia/Karachi'),
    CityResult('Islamabad', 'Pakistan', 33.6844, 73.0479, 'Asia/Karachi'),
    CityResult('Lahore', 'Pakistan', 31.5204, 74.3587, 'Asia/Karachi'),
    CityResult('Peshawar', 'Pakistan', 34.0151, 71.5249, 'Asia/Karachi'),
    CityResult('Cairo', 'Egypt', 30.0444, 31.2357, 'Africa/Cairo'),
    CityResult('Alexandria', 'Egypt', 31.2001, 29.9187, 'Africa/Cairo'),
    CityResult('Istanbul', 'Turkey', 41.0082, 28.9784, 'Europe/Istanbul'),
    CityResult('Ankara', 'Turkey', 39.9334, 32.8597, 'Europe/Istanbul'),
    CityResult('Kuala Lumpur', 'Malaysia', 3.1390, 101.6869, 'Asia/Kuala_Lumpur'),
    CityResult('Jakarta', 'Indonesia', -6.2088, 106.8456, 'Asia/Jakarta'),
    CityResult('Surabaya', 'Indonesia', -7.2575, 112.7521, 'Asia/Jakarta'),
    CityResult('Lagos', 'Nigeria', 6.5244, 3.3792, 'Africa/Lagos'),
    CityResult('Kano', 'Nigeria', 12.0022, 8.5920, 'Africa/Lagos'),
    CityResult('Nairobi', 'Kenya', -1.2921, 36.8219, 'Africa/Nairobi'),
    CityResult('Tehran', 'Iran', 35.6892, 51.3890, 'Asia/Tehran'),
    CityResult('Baghdad', 'Iraq', 33.3152, 44.3661, 'Asia/Baghdad'),
    CityResult('Amman', 'Jordan', 31.9454, 35.9284, 'Asia/Amman'),
    CityResult('Damascus', 'Syria', 33.5138, 36.2765, 'Asia/Damascus'),
    CityResult('Beirut', 'Lebanon', 33.8938, 35.5018, 'Asia/Beirut'),
    CityResult('Casablanca', 'Morocco', 33.5731, -7.5898, 'Africa/Casablanca'),
    CityResult('Tunis', 'Tunisia', 36.8065, 10.1815, 'Africa/Tunis'),
    CityResult('Algiers', 'Algeria', 36.7372, 3.0864, 'Africa/Algiers'),
    CityResult('Kabul', 'Afghanistan', 34.5553, 69.2075, 'Asia/Kabul'),
    CityResult('Colombo', 'Sri Lanka', 6.9271, 79.8612, 'Asia/Colombo'),
    CityResult('Mumbai', 'India', 19.0760, 72.8777, 'Asia/Kolkata'),
    CityResult('Delhi', 'India', 28.6139, 77.2090, 'Asia/Kolkata'),
    CityResult('Hyderabad', 'India', 17.3850, 78.4867, 'Asia/Kolkata'),
    CityResult('Paris', 'France', 48.8566, 2.3522, 'Europe/Paris'),
    CityResult('Berlin', 'Germany', 52.5200, 13.4050, 'Europe/Berlin'),
    CityResult('Amsterdam', 'Netherlands', 52.3676, 4.9041, 'Europe/Amsterdam'),
    CityResult('Sydney', 'Australia', -33.8688, 151.2093, 'Australia/Sydney'),
    CityResult('Melbourne', 'Australia', -37.8136, 144.9631, 'Australia/Melbourne'),
  ];
}
