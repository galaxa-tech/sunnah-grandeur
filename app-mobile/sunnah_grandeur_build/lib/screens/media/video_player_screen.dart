import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/video_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.video.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Column(
        children: [
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: c.bg,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.video.author, style: AppTextStyles.brandTag(c)),
                  const SizedBox(height: 8),
                  Text(widget.video.title, style: AppTextStyles.heading(c, fontSize: 20)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('${widget.video.views} views', style: AppTextStyles.bodyMuted(c, size: 12)),
                      const SizedBox(width: 10),
                      Text(widget.video.category, style: AppTextStyles.body(c, color: c.gold, size: 12)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'In this video, ${widget.video.author} explores the depths of Islamic knowledge regarding ${widget.video.title.toLowerCase()}. A must-watch for seekers of truth.',
                    style: AppTextStyles.body(c, size: 14).copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
