import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quran_model.dart';

/// Talks to the free, keyless Quran API at https://api.alquran.cloud/v1.
///
/// Endpoints used:
///   GET /surah                       — list of all 114 surahs (metadata only)
///   GET /surah/{number}/ar.alafasy   — Arabic text (Uthmani-script edition)
///   GET /surah/{number}/en.sahih     — Sahih International English translation
class QuranApiService {
  QuranApiService._();
  static final QuranApiService instance = QuranApiService._();

  static const _base = 'https://api.alquran.cloud/v1';
  static const _timeout = Duration(seconds: 15);

  Future<List<SurahMeta>> fetchSurahList() async {
    final uri = Uri.parse('$_base/surah');
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw QuranApiException(
          'Quran server returned status ${res.statusCode}.');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => SurahMeta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SurahDetail> fetchSurah(int number) async {
    final arabicUri = Uri.parse('$_base/surah/$number/ar.alafasy');
    final translationUri = Uri.parse('$_base/surah/$number/en.sahih');

    final responses = await Future.wait([
      http.get(arabicUri).timeout(_timeout),
      http.get(translationUri).timeout(_timeout),
    ]);

    final arabicRes = responses[0];
    final translationRes = responses[1];

    if (arabicRes.statusCode != 200 || translationRes.statusCode != 200) {
      throw QuranApiException('Failed to load surah $number from server.');
    }

    final arabicBody = jsonDecode(arabicRes.body) as Map<String, dynamic>;
    final translationBody =
        jsonDecode(translationRes.body) as Map<String, dynamic>;

    final arabicData = arabicBody['data'] as Map<String, dynamic>;
    final translationData = translationBody['data'] as Map<String, dynamic>;

    final meta = SurahMeta.fromJson(arabicData);

    final arabicAyahs = arabicData['ayahs'] as List<dynamic>? ?? [];
    final translationAyahs =
        translationData['ayahs'] as List<dynamic>? ?? [];

    // Pair by numberInSurah rather than by list index, in case the two
    // editions ever come back in a different order or with a mismatched
    // ayah count (e.g. Bismillah handling differs between editions).
    final translationByNumber = <int, String>{};
    for (final a in translationAyahs) {
      final m = a as Map<String, dynamic>;
      translationByNumber[m['numberInSurah'] as int] =
          m['text'] as String? ?? '';
    }

    final ayahs = <Ayah>[];
    for (final a in arabicAyahs) {
      final m = a as Map<String, dynamic>;
      final n = m['numberInSurah'] as int;
      ayahs.add(Ayah(
        numberInSurah: n,
        arabicText: m['text'] as String? ?? '',
        translationText: translationByNumber[n] ?? '',
      ));
    }

    if (ayahs.isEmpty) {
      throw QuranApiException('No ayahs returned for surah $number.');
    }

    return SurahDetail(meta: meta, ayahs: ayahs);
  }
}

class QuranApiException implements Exception {
  final String message;
  const QuranApiException(this.message);
  @override
  String toString() => message;
}
