import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

// The media shelf is admin-curated only, by explicit product decision: no
// algorithmic "up next," no YouTube-suggested content. Content enters only
// through the admin panel's Media Library, which writes to Firestore
// `/media` with `type` = 'video' (Islamic Videos) or 'ruqyah'.
//
// The Quran section is text + audio (see QuranScreen), not videos.
//
// Errors vs empty are kept distinct: `*Error` is set only when loading
// actually failed (show "Couldn't load · Retry"); an empty list with no
// error means nothing has been published yet (show an empty state).
class MediaProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<VideoModel> _videos      = [];
  List<VideoModel> _ruqyahMedia = [];

  bool _loadingVideos = true;
  bool _loadingRuqyah = true;

  bool _videosFailed = false;
  bool _ruqyahFailed = false;

  List<VideoModel> get videos      => _videos;
  List<VideoModel> get ruqyahMedia => _ruqyahMedia;
  bool get isLoadingVideos         => _loadingVideos;
  bool get isLoadingRuqyah         => _loadingRuqyah;
  bool get isLoading               => _loadingVideos || _loadingRuqyah;
  bool get videosFailed            => _videosFailed;
  bool get ruqyahFailed            => _ruqyahFailed;

  MediaProvider() { refreshAll(); }

  Future<void> refreshAll() =>
      Future.wait([_load('video'), _load('ruqyah')]);

  Future<void> refreshType(String type) => _load(type);

  Future<void> _load(String type) async {
    final isVideo = type == 'video';
    if (isVideo) {
      _loadingVideos = true;
    } else {
      _loadingRuqyah = true;
    }
    notifyListeners();

    List<VideoModel> items = const [];
    var failed = false;
    try {
      final snap = await _db
          .collection('media')
          .where('type', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(40)
          .get();
      items = snap.docs
          .map((d) => VideoModel.fromMap(d.data(), d.id))
          .where((v) => v.isActive && v.youtubeId.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[MediaProvider] $type: $e');
      failed = true;
    }

    if (isVideo) {
      _videos = items;
      _videosFailed = failed;
      _loadingVideos = false;
    } else {
      _ruqyahMedia = items;
      _ruqyahFailed = failed;
      _loadingRuqyah = false;
    }
    notifyListeners();
  }
}
