// ─────────────────────────────────────────────────────────────────────────────
// PlacesService — wraps Google Places API (Legacy) for mosque discovery.
//
// Requires the following APIs enabled in Google Cloud Console
// for AIzaSyCL5BbPVeuzkFx_wiu1PTAUgDSVXicgE6A :
//   • Places API
//   • Maps JavaScript API (optional — handled by Maps SDK natively)
//
// Endpoints used:
//   Nearby Search : /nearbysearch/json?location=&radius=&type=mosque
//   Text Search   : /textsearch/json?query=mosque+{query}
//   Photo         : /photo?maxwidth=&photo_reference=
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/masjid_result.dart';

class PlacesService {
  PlacesService._();
  static final PlacesService instance = PlacesService._();

  // API key is injected at compile time via:
  //   flutter run --dart-define-from-file=api_keys.json
  // Never hardcode the key in source — see api_keys.template.json for setup.
  static String get _apiKey => ApiConfig.placesApiKey;
  static const _base = 'https://maps.googleapis.com/maps/api/place';

  // ── Nearby mosque search ──────────────────────────────────────────────────

  /// Returns mosques within [radius] metres of the given coordinates,
  /// sorted by distance ascending.
  Future<List<MasjidResult>> nearbyMosques(
    double lat,
    double lng, {
    int radius = 5000,
  }) async {
    ApiConfig.assertConfigured();
    final uri = Uri.parse(
      '$_base/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=$radius'
      '&type=mosque'
      '&key=$_apiKey',
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        debugPrint('[PlacesService] nearbyMosques HTTP ${res.statusCode}');
        return [];
      }

      final body   = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String?;

      if (status == 'REQUEST_DENIED') {
        debugPrint('[PlacesService] REQUEST_DENIED — check Places API is enabled '
            'for key $_apiKey | ${body['error_message']}');
        return [];
      }
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        debugPrint('[PlacesService] nearbyMosques status: $status');
        return [];
      }

      final results = _parseResults(body['results'] as List<dynamic>? ?? [], lat, lng);
      debugPrint('[PlacesService] nearby: ${results.length} mosques');
      return results;
    } catch (e) {
      debugPrint('[PlacesService] nearbyMosques error: $e');
      return [];
    }
  }

  // ── Text search ───────────────────────────────────────────────────────────

  /// Text search for mosques matching [query], biased toward [lat]/[lng].
  Future<List<MasjidResult>> searchMosques(
    String query,
    double lat,
    double lng,
  ) async {
    final q   = Uri.encodeComponent('mosque $query');
    final uri = Uri.parse(
      '$_base/textsearch/json'
      '?query=$q'
      '&location=$lat,$lng'
      '&radius=20000'
      '&key=$_apiKey',
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];

      final body   = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String?;

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        debugPrint('[PlacesService] searchMosques status: $status');
        return [];
      }

      final results = _parseResults(body['results'] as List<dynamic>? ?? [], lat, lng);
      debugPrint('[PlacesService] search "$query": ${results.length} results');
      return results;
    } catch (e) {
      debugPrint('[PlacesService] searchMosques error: $e');
      return [];
    }
  }

  // ── Photo URL ─────────────────────────────────────────────────────────────

  /// Returns a ready-to-use HTTPS URL for a Places photo.
  String photoUrl(String photoRef, {int maxWidth = 600}) =>
      '$_base/photo?maxwidth=$maxWidth&photo_reference=$photoRef&key=$_apiKey';

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<MasjidResult> _parseResults(
    List<dynamic> raw,
    double userLat,
    double userLng,
  ) {
    final results = raw
        .map((e) {
          try {
            return MasjidResult.fromJson(e as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<MasjidResult>()
        .toList();

    for (final r in results) {
      r.distanceKm =
          Geolocator.distanceBetween(userLat, userLng, r.lat, r.lng) / 1000;
    }

    results.sort((a, b) =>
        (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return results;
  }
}
