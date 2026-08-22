import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';
import '../services/youtube_api_service.dart';

class MediaProvider extends ChangeNotifier {
  final FirebaseFirestore _db  = FirebaseFirestore.instance;
  final _api                   = YouTubeApiService.instance;

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
      final result = await _api.fetchLectures();
      if (result.videos.isNotEmpty) {
        _videos      = result.videos;
        _videosError = null;
      } else {
        _videos = await _firestoreFetch('video');
        if (_videos.isEmpty) {
          _videosError = result.status == ApiFetchStatus.empty
              ? 'No videos available — playlist may be empty or private.'
              : 'Failed to load videos. Check your connection.';
        }
      }
    } catch (e) {
      debugPrint('[MediaProvider] lectures: $e');
      _videos      = await _firestoreFetch('video');
      _videosError = _videos.isEmpty ? 'Could not load videos.' : null;
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
      final result = await _api.fetchQuran();
      if (result.videos.isNotEmpty) {
        _quranMedia = result.videos;
        _quranError = null;
      } else {
        _quranMedia = await _firestoreFetch('quran');
        if (_quranMedia.isEmpty) {
          _quranError = result.status == ApiFetchStatus.empty
              ? 'No Quran videos available — playlist may be empty or private.'
              : 'Failed to load Quran. Check your connection.';
        }
      }
    } catch (e) {
      debugPrint('[MediaProvider] quran: $e');
      _quranMedia = await _firestoreFetch('quran');
      _quranError = _quranMedia.isEmpty ? 'Could not load Quran.' : null;
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
      final result = await _api.fetchRuqyah();
      if (result.videos.isNotEmpty) {
        _ruqyahMedia = result.videos;
        _ruqyahError = null;
      } else {
        _ruqyahMedia = await _firestoreFetch('ruqyah');
        if (_ruqyahMedia.isEmpty) {
          _ruqyahError = result.status == ApiFetchStatus.empty
              ? 'No Ruqyah videos available — playlist may be empty or private.'
              : 'Failed to load Ruqyah. Check your connection.';
        }
      }
    } catch (e) {
      debugPrint('[MediaProvider] ruqyah: $e');
      _ruqyahMedia = await _firestoreFetch('ruqyah');
      _ruqyahError = _ruqyahMedia.isEmpty ? 'Could not load Ruqyah.' : null;
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
