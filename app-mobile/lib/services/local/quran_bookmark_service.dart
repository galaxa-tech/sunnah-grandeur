import 'package:shared_preferences/shared_preferences.dart';

/// Persists the reader's "last read" position (surah + ayah) to local
/// storage so a "Continue reading" entry point can be shown on return.
///
/// Keys:
///   quran_last_surah        — last opened surah number
///   quran_last_surah_name   — cached English name, for display without a refetch
///   quran_last_ayah         — last scrolled-to ayah number within that surah
class QuranBookmarkService {
  static const _surahKey     = 'quran_last_surah';
  static const _surahNameKey = 'quran_last_surah_name';
  static const _ayahKey      = 'quran_last_ayah';

  static Future<void> save({
    required int surahNumber,
    required String surahName,
    int ayahNumber = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_surahKey, surahNumber),
      prefs.setString(_surahNameKey, surahName),
      prefs.setInt(_ayahKey, ayahNumber),
    ]);
  }

  static Future<void> saveAyahPosition(int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ayahKey, ayahNumber);
  }

  static Future<QuranBookmark?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final surah = prefs.getInt(_surahKey);
    if (surah == null) return null;
    return QuranBookmark(
      surahNumber: surah,
      surahName: prefs.getString(_surahNameKey) ?? '',
      ayahNumber: prefs.getInt(_ayahKey) ?? 1,
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_surahKey),
      prefs.remove(_surahNameKey),
      prefs.remove(_ayahKey),
    ]);
  }
}

class QuranBookmark {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;

  const QuranBookmark({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
  });
}
