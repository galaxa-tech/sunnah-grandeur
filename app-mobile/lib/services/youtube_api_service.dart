import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';

enum ApiFetchStatus { ok, empty, apiError, networkError }

class ApiResult {
  const ApiResult(this.videos, this.status, {this.errorMessage});
  final List<VideoModel> videos;
  final ApiFetchStatus status;
  final String? errorMessage;
}

class YouTubeApiService {
  YouTubeApiService._();
  static final YouTubeApiService instance = YouTubeApiService._();

  static const _apiKey = 'AIzaSyAT0zEIqpH_DeXk1E168u7_OJMKcjAKD5w';
  static const _base = 'https://www.googleapis.com/youtube/v3';
  static const _perList = 8;
  static const _max = 10;

  // Islamic Lectures
  static const _lecturesPlaylists = <String>[
    'PLwNeHLk_z0aRSjMz2ynLMuykKYQMzsHPy',
    'PLRaPMa31r1pcGTIkbIXFb7KABFHgM5ThM',
  ];

  // Quran Recitation
  static const _quranPlaylists = <String>[
    'PLU-KD5_azXnzXFkYDArkZU_dMHgVetbDI',
    'PL9DE754DA1ABF407F',
  ];

  // Ruqyah & Healing
  static const _ruqyahPlaylists = <String>[
    'PLA3EBBAB6741A8190',
    'PL8PEVr6UUaQkDFnbxFzsQWlPNU6WOH8mW',
  ];

  Future<ApiResult> fetchLectures() => _fromPlaylists(_lecturesPlaylists, 'Lectures');
  Future<ApiResult> fetchQuran() => _fromPlaylists(_quranPlaylists, 'Quran');
  Future<ApiResult> fetchRuqyah() => _fromPlaylists(_ruqyahPlaylists, 'Ruqyah');

  Future<ApiResult> _fromPlaylists(List<String> ids, String category) async {
    final validIds = ids.where((id) {
      if (!id.startsWith('PL')) {
        debugPrint('Invalid playlist ID: $id - must start with PL');
        return false;
      }
      return true;
    }).toList();

    if (validIds.isEmpty) {
      return const ApiResult([], ApiFetchStatus.empty, errorMessage: 'No valid playlist IDs');
    }

    final batches = await Future.wait(validIds.map((id) => _fetchPlaylist(id, category)));

    final seen = <String>{};
    final merged = batches
        .expand((b) => b)
        .where((v) => v.youtubeId.isNotEmpty && seen.add(v.youtubeId))
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    if (merged.isEmpty) {
      return const ApiResult([], ApiFetchStatus.empty);
    }

    return ApiResult(merged.take(_max).toList(), ApiFetchStatus.ok);
  }

  Future<List<VideoModel>> _fetchPlaylist(String playlistId, String category) async {
    final uri = Uri.parse('$_base/playlistItems').replace(queryParameters: {
      'part': 'snippet',
      'maxResults': '$_perList',
      'playlistId': playlistId,
      'key': _apiKey,
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('YouTube playlistItems failed for $playlistId: ${response.statusCode}');
        return [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (body['items'] as List?) ?? [];

      if (items.isEmpty) return [];

      final result = <VideoModel>[];
      for (final item in items) {
        final snippet = item['snippet'] as Map<String, dynamic>?;
        final resourceId = snippet?['resourceId'] as Map<String, dynamic>?;
        final videoId = resourceId?['videoId'] as String?;

        if (snippet == null || videoId == null || videoId.isEmpty) continue;

        final thumbs = (snippet['thumbnails'] as Map<String, dynamic>?) ?? {};
        final thumbUrl = (thumbs['maxres'] as Map?)?['url'] as String? ??
            (thumbs['high'] as Map?)?['url'] as String? ??
            (thumbs['medium'] as Map?)?['url'] as String? ??
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

        result.add(VideoModel(
          id: videoId,
          youtubeId: videoId,
          title: (snippet['title'] ?? 'Untitled') as String,
          author: (snippet['channelTitle'] ?? '') as String,
          duration: '—',
          views: '—',
          description: (snippet['description'] ?? '') as String,
          thumbnail: thumbUrl,
          category: category,
          publishedAt: DateTime.tryParse((snippet['publishedAt'] ?? '') as String) ?? DateTime.now(),
        ));
      }
      return result;
    } catch (e) {
      debugPrint('Error fetching playlist $playlistId: $e');
      return [];
    }
  }
}
