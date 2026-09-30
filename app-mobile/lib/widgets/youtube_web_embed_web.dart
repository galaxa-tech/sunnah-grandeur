import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Plays a YouTube video on Flutter web through YouTube's own privacy-
/// enhanced iframe player (youtube_player_flutter is WebView-based and does
/// not run on web).
class YoutubeWebEmbed extends StatefulWidget {
  const YoutubeWebEmbed({super.key, required this.videoId});
  final String videoId;

  @override
  State<YoutubeWebEmbed> createState() => _YoutubeWebEmbedState();
}

class _YoutubeWebEmbedState extends State<YoutubeWebEmbed> {
  static final Set<String> _registered = {};
  late final String _viewType = 'yt-embed-${widget.videoId}';

  @override
  void initState() {
    super.initState();
    if (_registered.add(_viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
        final iframe = web.HTMLIFrameElement()
          ..src = 'https://www.youtube-nocookie.com/embed/${widget.videoId}'
              '?autoplay=1&rel=0&modestbranding=1&playsinline=1'
          ..allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen'
          ..allowFullscreen = true;
        iframe.style
          ..border = '0'
          ..width = '100%'
          ..height = '100%';
        return iframe;
      });
    }
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
