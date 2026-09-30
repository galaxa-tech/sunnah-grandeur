import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

class MediaProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<VideoModel> _videos = [];
  List<VideoModel> _quranMedia = [];
  List<VideoModel> _ruqyahMedia = [];
  bool _isLoading = true;

  List<VideoModel> get videos => _videos;
  List<VideoModel> get quranMedia => _quranMedia;
  List<VideoModel> get ruqyahMedia => _ruqyahMedia;
  bool get isLoading => _isLoading;

  MediaProvider() {
    refreshAll();
  }

  Future<void> _fetchMedia(String type) async {
    try {
      final snap = await _db.collection('media')
          .where('type', isEqualTo: type)
          .orderBy('publishedAt', descending: true)
          .limit(50)
          .get();

      final docs = snap.docs
          .map((d) => VideoModel.fromMap(d.data(), d.id))
          .where((v) => v.isActive)
          .toList();
      
      if (type == 'video') _videos = docs;
      else if (type == 'quran') _quranMedia = docs;
      else if (type == 'ruqyah') _ruqyahMedia = docs;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching $type media: $e');
    }
  }

  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();
    
    await Future.wait([
      _fetchMedia('video'),
      _fetchMedia('quran'),
      _fetchMedia('ruqyah'),
    ]);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshType(String type) async {
    _isLoading = true;
    notifyListeners();
    await _fetchMedia(type);
    _isLoading = false;
    notifyListeners();
  }
}
