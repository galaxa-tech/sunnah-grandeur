import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

// The media shelf is admin-curated only, by explicit product decision: no
// algorithmic "up next," no YouTube-suggested content. Content enters only
// through the admin panel's Media Library, which writes to Firestore
// `/media`. Do not reintroduce YouTubeApiService as a content source here.
class MediaProvider extends ChangeNotifier {
  final FirebaseFirestore _db  = FirebaseFirestore.instance;

  List<VideoModel> _videos      = [];
  List<VideoModel> _quranMedia  = [];
  List<VideoModel> _ruqyahMedia = [];
  bool _isLoading               = true;

  bool _loadingVideos  = true;
  bool _loadingQuran   = true;
  bool _loadingRuqyah  = true;

  String? _videosError;
  String? _quranError;
  String? _ruqyahError;

  List<VideoModel> get videos       => _videos;
  List<VideoModel> get quranMedia   => _quranMedia;
  List<VideoModel> get ruqyahMedia  => _ruqyahMedia;
  bool get isLoading                => _isLoading;
  bool get isLoadingVideos          => _loadingVideos;
  bool get isLoadingQuran           => _loadingQuran;
  bool get isLoadingRuqyah          => _loadingRuqyah;
  String? get videosError           => _videosError;
  String? get quranError            => _quranError;
  String? get ruqyahError           => _ruqyahError;

  MediaProvider() { refreshAll(); }

  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([_loadLectures(), _loadQuran(), _loadRuqyah()]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshType(String type) async {
    switch (type) {
      case 'video':  await _loadLectures(); break;
      case 'quran':  await _loadQuran();    break;
      case 'ruqyah': await _loadRuqyah();   break;
    }
  }

  Future<void> _loadLectures() async {
    _loadingVideos = true;
    _videosError   = null;
    notifyListeners();
    try {
      _videos = await _firestoreFetch('video');
      _videosError = _videos.isEmpty ? 'No videos added yet.' : null;
    } catch (e) {
      debugPrint('[MediaProvider] lectures: $e');
      _videos      = [];
      _videosError = 'Could not load videos.';
    } finally {
      _loadingVideos = false;
      notifyListeners();
    }
  }

  Future<void> _loadQuran() async {
    _loadingQuran = true;
    _quranError   = null;
    notifyListeners();
    try {
      _quranMedia = await _firestoreFetch('quran');
      _quranError = _quranMedia.isEmpty ? 'No Quran media added yet.' : null;
    } catch (e) {
      debugPrint('[MediaProvider] quran: $e');
      _quranMedia = [];
      _quranError = 'Could not load Quran.';
    } finally {
      _loadingQuran = false;
      notifyListeners();
    }
  }

  Future<void> _loadRuqyah() async {
    _loadingRuqyah = true;
    _ruqyahError   = null;
    notifyListeners();
    try {
      _ruqyahMedia = await _firestoreFetch('ruqyah');
      _ruqyahError = _ruqyahMedia.isEmpty ? 'No Ruqyah media added yet.' : null;
    } catch (e) {
      debugPrint('[MediaProvider] ruqyah: $e');
      _ruqyahMedia = [];
      _ruqyahError = 'Could not load Ruqyah.';
    } finally {
      _loadingRuqyah = false;
      notifyListeners();
    }
  }

  Future<List<VideoModel>> _firestoreFetch(String type) async {
    try {
      final snap = await _db
          .collection('media')
          .where('type', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(20)
          .get();
      return snap.docs
          .map((d) => VideoModel.fromMap(d.data(), d.id))
          .where((v) => v.isActive)
          .toList();
    } catch (e) {
      debugPrint('[MediaProvider] Firestore ($type): $e');
      return [];
    }
  }
}
