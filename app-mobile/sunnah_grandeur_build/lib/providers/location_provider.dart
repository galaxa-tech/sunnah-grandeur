import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CityResult {
  final String city;
  final String country;
  final double lat;
  final double lng;
  const CityResult(this.city, this.country, this.lat, this.lng);
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

  double? _lat;
  double? _lng;
  String  _cityName   = '';
  bool    _isLoading  = false;
  String? _error;

  double? get lat       => _lat;
  double? get lng       => _lng;
  String  get cityName  => _cityName;
  bool    get isLoading => _isLoading;
  bool    get hasLocation => _lat != null && _lng != null;
  String? get error     => _error;

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
    _lat      = prefs.getDouble(_keyLat);
    _lng      = prefs.getDouble(_keyLng);
    _cityName = prefs.getString(_keyCity) ?? '';
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lat != null) await prefs.setDouble(_keyLat, _lat!);
    if (_lng != null) await prefs.setDouble(_keyLng, _lng!);
    await prefs.setString(_keyCity, _cityName);
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

  /// Sets a manually chosen location and persists it.
  Future<void> setManualLocation(double lat, double lng, String city) async {
    _lat = lat;
    _lng = lng;
    _cityName = city;
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
    CityResult('Mecca', 'Saudi Arabia', 21.3891, 39.8579),
    CityResult('Medina', 'Saudi Arabia', 24.5247, 39.5692),
    CityResult('Riyadh', 'Saudi Arabia', 24.7136, 46.6753),
    CityResult('Jeddah', 'Saudi Arabia', 21.4858, 39.1925),
    CityResult('Dubai', 'UAE', 25.2048, 55.2708),
    CityResult('Abu Dhabi', 'UAE', 24.4539, 54.3773),
    CityResult('London', 'UK', 51.5074, -0.1278),
    CityResult('Birmingham', 'UK', 52.4862, -1.8904),
    CityResult('Manchester', 'UK', 53.4808, -2.2426),
    CityResult('New York', 'USA', 40.7128, -74.0060),
    CityResult('Chicago', 'USA', 41.8781, -87.6298),
    CityResult('Los Angeles', 'USA', 34.0522, -118.2437),
    CityResult('Houston', 'USA', 29.7604, -95.3698),
    CityResult('Toronto', 'Canada', 43.6532, -79.3832),
    CityResult('Vancouver', 'Canada', 49.2827, -123.1207),
    CityResult('Dhaka', 'Bangladesh', 23.8103, 90.4125),
    CityResult('Chittagong', 'Bangladesh', 22.3569, 91.7832),
    CityResult('Sylhet', 'Bangladesh', 24.8949, 91.8687),
    CityResult('Karachi', 'Pakistan', 24.8607, 67.0011),
    CityResult('Islamabad', 'Pakistan', 33.6844, 73.0479),
    CityResult('Lahore', 'Pakistan', 31.5204, 74.3587),
    CityResult('Peshawar', 'Pakistan', 34.0151, 71.5249),
    CityResult('Cairo', 'Egypt', 30.0444, 31.2357),
    CityResult('Alexandria', 'Egypt', 31.2001, 29.9187),
    CityResult('Istanbul', 'Turkey', 41.0082, 28.9784),
    CityResult('Ankara', 'Turkey', 39.9334, 32.8597),
    CityResult('Kuala Lumpur', 'Malaysia', 3.1390, 101.6869),
    CityResult('Jakarta', 'Indonesia', -6.2088, 106.8456),
    CityResult('Surabaya', 'Indonesia', -7.2575, 112.7521),
    CityResult('Lagos', 'Nigeria', 6.5244, 3.3792),
    CityResult('Kano', 'Nigeria', 12.0022, 8.5920),
    CityResult('Nairobi', 'Kenya', -1.2921, 36.8219),
    CityResult('Tehran', 'Iran', 35.6892, 51.3890),
    CityResult('Baghdad', 'Iraq', 33.3152, 44.3661),
    CityResult('Amman', 'Jordan', 31.9454, 35.9284),
    CityResult('Damascus', 'Syria', 33.5138, 36.2765),
    CityResult('Beirut', 'Lebanon', 33.8938, 35.5018),
    CityResult('Casablanca', 'Morocco', 33.5731, -7.5898),
    CityResult('Tunis', 'Tunisia', 36.8065, 10.1815),
    CityResult('Algiers', 'Algeria', 36.7372, 3.0864),
    CityResult('Kabul', 'Afghanistan', 34.5553, 69.2075),
    CityResult('Colombo', 'Sri Lanka', 6.9271, 79.8612),
    CityResult('Mumbai', 'India', 19.0760, 72.8777),
    CityResult('Delhi', 'India', 28.6139, 77.2090),
    CityResult('Hyderabad', 'India', 17.3850, 78.4867),
    CityResult('Paris', 'France', 48.8566, 2.3522),
    CityResult('Berlin', 'Germany', 52.5200, 13.4050),
    CityResult('Amsterdam', 'Netherlands', 52.3676, 4.9041),
    CityResult('Sydney', 'Australia', -33.8688, 151.2093),
    CityResult('Melbourne', 'Australia', -37.8136, 144.9631),
  ];
}
