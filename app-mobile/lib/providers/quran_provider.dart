import 'package:flutter/foundation.dart';
import '../models/quran_model.dart';
import '../services/quran_api_service.dart';
import '../services/local/quran_bookmark_service.dart';

/// Provides the Quran surah list and individual surah text (Arabic +
/// English translation) for the "Read" tab of the Quran screen.
///
/// The surah list is cached in memory for the lifetime of this provider
/// (the app session) so navigating back to the list does not refetch it.
/// Individual surah text is cached per-surah-number for the same reason.
class QuranProvider extends ChangeNotifier {
  final _api = QuranApiService.instance;

  List<SurahMeta> _surahs = [];
  bool _loadingSurahs = false;
  String? _surahsError;

  final Map<int, SurahDetail> _surahCache = {};
  int? _loadingSurahNumber;
  String? _surahDetailError;

  QuranBookmark? _lastRead;
  bool _bookmarkLoaded = false;

  List<SurahMeta> get surahs => _surahs;
  bool get isLoadingSurahs => _loadingSurahs;
  String? get surahsError => _surahsError;

  bool get isLoadingSurahDetail => _loadingSurahNumber != null;
  String? get surahDetailError => _surahDetailError;

  QuranBookmark? get lastRead => _lastRead;
  bool get bookmarkLoaded => _bookmarkLoaded;

  /// Fetches the 114-surah list, unless already cached in memory.
  Future<void> loadSurahList({bool forceRefresh = false}) async {
    if (_surahs.isNotEmpty && !forceRefresh) return;
    _loadingSurahs = true;
    _surahsError = null;
    notifyListeners();
    try {
      final list = await _api.fetchSurahList();
      _surahs = list;
      _surahsError = null;
    } catch (e) {
      debugPrint('[QuranProvider] surah list: $e');
      _surahsError = 'Could not load the surah list. Check your connection '
          'and try again.';
    } finally {
      _loadingSurahs = false;
      notifyListeners();
    }
  }

  /// Returns a cached surah if present, else fetches and caches it.
  SurahDetail? cachedSurah(int number) => _surahCache[number];

  Future<void> loadSurah(int number, {bool forceRefresh = false}) async {
    if (!forceRefresh && _surahCache.containsKey(number)) return;
    _loadingSurahNumber = number;
    _surahDetailError = null;
    notifyListeners();
    try {
      final detail = await _api.fetchSurah(number);
      _surahCache[number] = detail;
      _surahDetailError = null;
    } catch (e) {
      debugPrint('[QuranProvider] surah $number: $e');
      _surahDetailError = 'Could not load this surah. Check your connection '
          'and try again.';
    } finally {
      _loadingSurahNumber = null;
      notifyListeners();
    }
  }

  Future<void> loadLastRead() async {
    _lastRead = await QuranBookmarkService.load();
    _bookmarkLoaded = true;
    notifyListeners();
  }

  Future<void> markLastRead({
    required int surahNumber,
    required String surahName,
    int ayahNumber = 1,
  }) async {
    await QuranBookmarkService.save(
      surahNumber: surahNumber,
      surahName: surahName,
      ayahNumber: ayahNumber,
    );
    _lastRead = QuranBookmark(
      surahNumber: surahNumber,
      surahName: surahName,
      ayahNumber: ayahNumber,
    );
    notifyListeners();
  }

  Future<void> updateLastReadAyah(int ayahNumber) async {
    if (_lastRead == null) return;
    await QuranBookmarkService.saveAyahPosition(ayahNumber);
    _lastRead = QuranBookmark(
      surahNumber: _lastRead!.surahNumber,
      surahName: _lastRead!.surahName,
      ayahNumber: ayahNumber,
    );
    // Scroll-position bookkeeping only — no need to rebuild listeners.
  }
}
