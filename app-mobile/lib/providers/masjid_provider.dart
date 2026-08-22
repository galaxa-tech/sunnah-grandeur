import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/masjid_result.dart';
import '../services/places_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MasjidStatus — represents every possible state of the Masjid Finder.
// ─────────────────────────────────────────────────────────────────────────────
enum MasjidStatus {
  initial,   // not yet started
  locating,  // requesting GPS permission / getting position
  loading,   // Places API call in flight
  loaded,    // data available (may be empty)
  error,     // unrecoverable error — errorMessage has the reason
}

// ─────────────────────────────────────────────────────────────────────────────
// MasjidProvider — owns ALL data logic for the Masjid Finder.
//
// The screen is pure UI: it reads from this provider and calls its methods.
// GoogleMapController stays in the widget (lifecycle-tied); everything
// else lives here.
// ─────────────────────────────────────────────────────────────────────────────
class MasjidProvider extends ChangeNotifier {
  final PlacesService _places;

  MasjidStatus        _status       = MasjidStatus.initial;
  Position?           _position;
  List<MasjidResult>  _masjids      = [];
  MasjidResult?       _selected;
  String?             _errorMessage;
  StreamSubscription<Position>? _posSub;

  MasjidProvider({PlacesService? places})
      : _places = places ?? PlacesService.instance;

  // ── Getters ───────────────────────────────────────────────────────────────

  MasjidStatus       get status       => _status;
  Position?          get position      => _position;
  List<MasjidResult> get masjids       => _masjids;
  MasjidResult?      get selected      => _selected;
  String?            get errorMessage  => _errorMessage;

  bool get isInitial  => _status == MasjidStatus.initial;
  bool get isLocating => _status == MasjidStatus.locating;
  bool get isLoading  => _status == MasjidStatus.loading;
  bool get isBusy     => isLocating || isLoading;
  bool get isLoaded   => _status == MasjidStatus.loaded;
  bool get hasError   => _status == MasjidStatus.error;
  bool get hasData    => _masjids.isNotEmpty;

  /// Current map centre — user's GPS position or Mecca as fallback.
  LatLng get center => _position != null
      ? LatLng(_position!.latitude, _position!.longitude)
      : const LatLng(21.3891, 39.8579);

  // ── Public actions ────────────────────────────────────────────────────────

  /// Full initialisation: permission → GPS → mosque fetch → live stream.
  /// Safe to call multiple times; subsequent calls while busy are no-ops.
  Future<void> init() async {
    if (_status == MasjidStatus.locating || _status == MasjidStatus.loading) return;

    _set(MasjidStatus.locating);

    try {
      // ── 1. Location services ─────────────────────────────────────────────
      final svcOn = await Geolocator.isLocationServiceEnabled();
      if (!svcOn) {
        _setError(
          'Location services are off.\n'
          'Please enable GPS to find nearby mosques.',
        );
        return;
      }

      // ── 2. Permission ────────────────────────────────────────────────────
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        _setError(
          'Location permission denied.\n'
          'Grant permission to discover nearby mosques.',
        );
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        _setError(
          'Location permission is permanently denied.\n'
          'Open Settings → Sunnah Grandeur → Location and allow access.',
        );
        return;
      }

      // ── 3. First fix (high accuracy for initial camera position) ─────────
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _position = pos;
      notifyListeners(); // map can now move to real position

      // ── 4. Fetch nearby mosques ──────────────────────────────────────────
      await _loadNearby();

      // ── 5. Stream subsequent position updates (medium accuracy, 100m) ────
      _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy:       LocationAccuracy.medium,
          distanceFilter: 100,
        ),
      ).listen((p) {
        _position = p;
        notifyListeners();
      });
    } catch (e) {
      _setError('Could not access location: ${_clean(e)}');
    }
  }

  /// Re-fetch nearby mosques using the current position (pull-to-refresh).
  Future<void> refresh() => _loadNearby();

  /// Text search for mosques matching [query], biased toward current position.
  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      await _loadNearby();
      return;
    }

    _set(MasjidStatus.loading);

    final lat = _position?.latitude  ?? center.latitude;
    final lng = _position?.longitude ?? center.longitude;

    try {
      final results = await _places.searchMosques(q, lat, lng);
      _masjids  = results;
      _selected = null;
      _set(MasjidStatus.loaded);
    } catch (e) {
      _setError('Search failed: ${_clean(e)}');
    }
  }

  /// Select (highlight) a masjid from the list or map.
  void select(MasjidResult? m) {
    _selected = m;
    notifyListeners();
  }

  /// Retry after an error — re-runs the full init flow.
  void retry() => init();

  /// Dismiss the current error without retrying.
  void clearError() {
    _errorMessage = null;
    _set(MasjidStatus.initial);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _loadNearby() async {
    if (_position == null) return;
    _set(MasjidStatus.loading);

    try {
      final results = await _places.nearbyMosques(
        _position!.latitude,
        _position!.longitude,
        radius: 5000,
      );
      _masjids  = results;
      _selected = null;
      _set(MasjidStatus.loaded);
      debugPrint('[MasjidProvider] loaded ${results.length} mosques');
    } catch (e) {
      // Keep any previously loaded data — just log the refresh error.
      debugPrint('[MasjidProvider] _loadNearby error: $e');
      if (_masjids.isEmpty) {
        _setError('Could not load nearby mosques. Check your connection.');
      } else {
        _set(MasjidStatus.loaded); // show stale data rather than error screen
      }
    }
  }

  void _set(MasjidStatus s) {
    _status       = s;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status       = MasjidStatus.error;
    _errorMessage = msg;
    notifyListeners();
    debugPrint('[MasjidProvider] error: $msg');
  }

  String _clean(Object e) => e.toString().split('\n').first;

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }
}
