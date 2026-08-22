import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String youtubeId;
  final String title;
  final String author;
  final String duration;
  final String views;
  final String description;
  final String thumbnail;
  final String category;
  final DateTime publishedAt;
  final bool isActive;

  VideoModel({
    required this.id,
    required this.youtubeId,
    required this.title,
    required this.author,
    required this.duration,
    required this.views,
    required this.description,
    required this.thumbnail,
    required this.category,
    required this.publishedAt,
    this.isActive = true,
  });

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$youtubeId';

  // Best-quality YouTube thumbnail — falls back down the quality chain.
  String get thumbnailHq =>
      thumbnail.isNotEmpty ? thumbnail : 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';

  factory VideoModel.fromMap(Map<String, dynamic> map, String docId) {
    return VideoModel(
      id:          docId,
      youtubeId:   map['youtubeId'] ?? '',
      title:       map['title']     ?? '',
      author:      map['author']    ?? 'Sunnah Grandeur',
      duration:    map['duration']  ?? '—',
      views:       map['views']     ?? '0',
      description: map['description'] ?? '',
      thumbnail:   map['thumbnail'] ??
          'https://img.youtube.com/vi/${map['youtubeId']}/hqdefault.jpg',
      category:    map['category']  ?? 'General',
      isActive:    map['isActive']  ?? true,
      publishedAt: map['publishedAt'] != null
          ? (map['publishedAt'] is String
              ? DateTime.parse(map['publishedAt'])
              : (map['publishedAt'] as Timestamp).toDate())
          : DateTime.now(),
    );
  }

  factory VideoModel.fromDoc(DocumentSnapshot doc) =>
      VideoModel.fromMap(doc.data()! as Map<String, dynamic>, doc.id);
}
