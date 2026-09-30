import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_model.dart';

/// Talks to the free, keyless Quran API at https://api.alquran.cloud/v1.
///
///   GET /surah                                        — 114 surah metadata
///   GET /surah/{n}/editions/quran-uthmani,{translation} — text + translation
///
/// `quran-uthmani` is the Tanzil Uthmani *text* edition (the previous code
/// used `ar.alafasy`, an audio edition, whose text carried extra recitation
/// marks that rendered as garbage without a Quranic font).
///
/// Every successful response is cached in SharedPreferences so a surah that
/// was opened once can be re-read offline.
class QuranApiService {
  QuranApiService._();
  static final QuranApiService instance = QuranApiService._();

  static const _base = 'https://api.alquran.cloud/v1';
  static const _timeout = Duration(seconds: 15);
  static const _cacheVersion = 'v2';

  /// Translation edition for an app language code.
  static String translationFor(String langCode) => switch (langCode) {
        'bn' => 'bn.bengali',
        _    => 'en.sahih',
      };

  /// Per-surah recitation audio (Mishary Alafasy, 128 kbps).
  static String audioUrl(int surah) =>
      'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$surah.mp3';

  Future<Map<String, dynamic>> _getJson(String path, String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quran_${_cacheVersion}_$cacheKey';
    try {
      final res = await http.get(Uri.parse('$_base$path')).timeout(_timeout);
      if (res.statusCode != 200) {
        throw QuranApiException('Quran server returned status ${res.statusCode}.');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      prefs.setString(key, res.body).ignore();
      return body;
    } catch (e) {
      final cached = prefs.getString(key);
      if (cached != null) {
        debugPrint('[QuranApi] offline, using cache for $cacheKey ($e)');
        return jsonDecode(cached) as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  Future<List<SurahMeta>> fetchSurahList() async {
    final body = await _getJson('/surah', 'list');
    final data = body['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => SurahMeta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SurahDetail> fetchSurah(int number, {String langCode = 'en'}) async {
    final translation = translationFor(langCode);
    final body = await _getJson(
      '/surah/$number/editions/quran-uthmani,$translation',
      's${number}_$translation',
    );
    final editions = body['data'] as List<dynamic>? ?? [];
    if (editions.length < 2) {
      throw QuranApiException('Failed to load surah $number from server.');
    }
    final arabicData = editions[0] as Map<String, dynamic>;
    final translationData = editions[1] as Map<String, dynamic>;
    final meta = SurahMeta.fromJson(arabicData);

    final translationByNumber = <int, String>{};
    for (final a in translationData['ayahs'] as List<dynamic>? ?? []) {
      final m = a as Map<String, dynamic>;
      translationByNumber[m['numberInSurah'] as int] = m['text'] as String? ?? '';
    }

    final ayahs = <Ayah>[];
    for (final a in arabicData['ayahs'] as List<dynamic>? ?? []) {
      final m = a as Map<String, dynamic>;
      final n = m['numberInSurah'] as int;
      var text = m['text'] as String? ?? '';
      // Tanzil prefixes ayah 1 of every surah (except Al-Fatiha, where it IS
      // ayah 1, and At-Tawbah, which has none) with the Bismillah. It's shown
      // once as a header instead, as in a printed mushaf.
      if (n == 1 && number != 1 && number != 9) {
        text = stripBismillah(text);
      }
      ayahs.add(Ayah(
        numberInSurah: n,
        arabicText: text,
        translationText: translationByNumber[n] ?? '',
      ));
    }

    if (ayahs.isEmpty) {
      throw QuranApiException('No ayahs returned for surah $number.');
    }
    return SurahDetail(meta: meta, ayahs: ayahs);
  }

  /// Removes a leading Bismillah (the first four words) from [text].
  @visibleForTesting
  static String stripBismillah(String text) {
    // The API's text sometimes starts with a BOM (U+FEFF).
    final words = text.replaceAll('﻿', '').trim().split(RegExp(r'\s+'));
    if (words.length > 4 && words.first.startsWith('بِسْمِ')) {
      return words.skip(4).join(' ');
    }
    return text;
  }
}

class QuranApiException implements Exception {
  final String message;
  const QuranApiException(this.message);
  @override
  String toString() => message;
}
