// ─────────────────────────────────────────────────────────────────────────────
// MetalPricesService — live gold/silver spot price for the Zakat calculator,
// via our own metalPrices Cloud Function (same server-side-proxy pattern as
// PlacesService — see backend/functions/src/domains/zakat/index.js).
// Best-effort only: callers should keep their own sensible default and treat
// a failure here as "couldn't refresh," not a hard error.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MetalPrices {
  const MetalPrices({required this.goldUsdPerGram, required this.silverUsdPerGram});
  final double goldUsdPerGram;
  final double silverUsdPerGram;
}

class MetalPricesService {
  MetalPricesService._();
  static final MetalPricesService instance = MetalPricesService._();

  static const _base = 'https://us-central1-sunnah-grandeur.cloudfunctions.net';

  Future<MetalPrices?> fetchLivePrices() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/metalPrices'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        debugPrint('[MetalPricesService] HTTP ${res.statusCode}: ${res.body}');
        return null;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final gold = (body['goldUsdPerGram'] as num?)?.toDouble();
      final silver = (body['silverUsdPerGram'] as num?)?.toDouble();
      if (gold == null || silver == null) return null;
      return MetalPrices(goldUsdPerGram: gold, silverUsdPerGram: silver);
    } catch (e) {
      debugPrint('[MetalPricesService] fetch failed: $e');
      return null;
    }
  }
}
