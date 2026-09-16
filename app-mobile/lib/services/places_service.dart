// ─────────────────────────────────────────────────────────────────────────────
// PlacesService — mosque discovery via our own masjidNearby/masjidSearch
// Cloud Functions, which proxy Google Places API (Legacy) server-side.
//
// WHY A PROXY: the Places Web Service does not send CORS headers, so a
// browser calling it directly is blocked by the browser's own CORS policy —
// this app is deployed as a web app, so a direct call never worked here (it
// would only work on a native Android/iOS build, which has no CORS). Routing
// through our backend also keeps the API key out of the client bundle.
// See backend/functions/src/domains/masjid/index.js.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/masjid_result.dart';

class PlacesService {
  PlacesService._();
  static final PlacesService instance = PlacesService._();

  static const _base = 'https://us-central1-sunnah-grandeur.cloudfunctions.net';

  // ── Nearby mosque search ──────────────────────────────────────────────────

  /// Returns mosques within [radius] metres of the given coordinates,
  /// sorted by distance ascending.
  Future<List<MasjidResult>> nearbyMosques(
    double lat,
    double lng, {
    int radius = 5000,
  }) async {
    final uri = Uri.parse(
      '$_base/masjidNearby'
      '?lat=$lat&lng=$lng&radius=$radius',
    );

    // Deliberately does NOT swallow errors to an empty list — a config or
    // network failure must not be indistinguishable from "0 mosques nearby".
    // MasjidProvider._loadNearby() catches and surfaces this as a real error.
    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    final body   = jsonDecode(res.body) as Map<String, dynamic>;
    final status = body['status'] as String?;

    if (res.statusCode != 200) {
      debugPrint('[PlacesService] masjidNearby HTTP ${res.statusCode} | ${body['error_message']}');
      throw Exception(body['error_message'] ?? 'Places lookup failed (HTTP ${res.statusCode})');
    }
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Places API status: $status');
    }

    final results = _parseResults(body['results'] as List<dynamic>? ?? [], lat, lng);
    debugPrint('[PlacesService] nearby: ${results.length} mosques');
    return results;
  }

  // ── Text search ───────────────────────────────────────────────────────────

  /// Text search for mosques matching [query], biased toward [lat]/[lng].
  Future<List<MasjidResult>> searchMosques(
    String query,
    double lat,
    double lng,
  ) async {
    final uri = Uri.parse(
      '$_base/masjidSearch'
      '?query=${Uri.encodeComponent(query)}&lat=$lat&lng=$lng',
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    final body   = jsonDecode(res.body) as Map<String, dynamic>;
    final status = body['status'] as String?;

    if (res.statusCode != 200) {
      throw Exception(body['error_message'] ?? 'Places search failed (HTTP ${res.statusCode})');
    }
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Places API status: $status');
    }

    final results = _parseResults(body['results'] as List<dynamic>? ?? [], lat, lng);
    debugPrint('[PlacesService] search "$query": ${results.length} results');
    return results;
  }

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
