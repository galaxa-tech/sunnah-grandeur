import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hadith_model.dart';

class DawahProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  HadithModel? _dailyHadith;
  bool _isLoading = true;
  bool _hasError = false;

  HadithModel? get dailyHadith => _dailyHadith;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  static const int _hadithPoolSize = 1000;

  DawahProvider() {
    fetchDailyHadith();
  }

  int get _todayIndex {
    final epoch = DateTime(1970);
    final today = DateTime.now();
    final days = today.difference(epoch).inDays;
    return (days % _hadithPoolSize) + 1;
  }

  Future<void> fetchDailyHadith() async {
    _hasError = false;
    try {
      // Try rotating index first (new hadith collection)
      final snap = await _db.collection('hadith')
          .where('globalIndex', isEqualTo: _todayIndex)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        _dailyHadith = HadithModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
      } else {
        // Fallback: legacy hadith_posts collection
        final fallback = await _db.collection('hadith_posts')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (fallback.docs.isNotEmpty) {
          _dailyHadith = HadithModel.fromMap(fallback.docs.first.data(), fallback.docs.first.id);
        } else {
          _dailyHadith = null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching hadith: $e');
      _dailyHadith = null;
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<HadithModel>> fetchPage({
    String? book,
    int pageSize = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _db.collection('hadith').orderBy('globalIndex');
      if (book != null) query = query.where('book', isEqualTo: book);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc);
      query = query.limit(pageSize);

      final snap = await query.get();
      return snap.docs
          .map((d) => HadithModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching hadith page: $e');
      return [];
    }
  }
}
