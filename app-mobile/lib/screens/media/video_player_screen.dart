import 'dart:async';
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
  YoutubePlayerController? _ctrl;
  bool _started  = false;
  bool _ready    = false;
  bool _hasError = false;
  Timer? _readyTimeout;

  @override
  void dispose() {
    _readyTimeout?.cancel();
    _ctrl?.removeListener(_onCtrlChange);
    _ctrl?.dispose();
    super.dispose();
  }

  void _startPlayer() {
    if (widget.video.youtubeId.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    final ctrl = YoutubePlayerController(
      initialVideoId: widget.video.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay:        true,
        mute:            false,
        enableCaption:   false,
        forceHD:         false,
        hideThumbnail:   true,
        loop:            false,
        disableDragSeek: false,
      ),
    )..addListener(_onCtrlChange);

    // If player doesn't become ready in 20 seconds, show error
    _readyTimeout = Timer(const Duration(seconds: 20), () {
      if (mounted && !_ready) setState(() => _hasError = true);
    });

    setState(() { _ctrl = ctrl; _started = true; });
  }

  void _onCtrlChange() {
    if (!mounted || _ctrl == null) return;
    final v = _ctrl!.value;
    if (!_ready && v.isReady) setState(() => _ready = true);
    if (!_hasError && v.hasError) setState(() => _hasError = true);
  }

  void _retry() {
    _readyTimeout?.cancel();
    _ctrl?.removeListener(_onCtrlChange);
    _ctrl?.dispose();
    setState(() {
      _ctrl      = null;
      _started   = false;
      _ready     = false;
      _hasError  = false;
    });
  }

  // ── Thumbnail (shown before player starts) ────────────────────────────────

  Widget _buildThumbnail(AppColors c) => AspectRatio(
        aspectRatio: 16 / 9,
        child: GestureDetector(
          onTap: _startPlayer,
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(
              child: Image.network(
                'https://img.youtube.com/vi/${widget.video.youtubeId}/hqdefault.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black87),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.28)),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55), width: 2),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 36),
            ),
            if (widget.video.duration != '—')
              Positioned(
                bottom: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(widget.video.duration,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                ),
              ),
          ]),
        ),
      );

  // ── Meta panel (scrollable info below player) ─────────────────────────────

  Widget _buildMeta(AppColors c, BuildContext ctx) => Expanded(
        child: Container(
          width: double.infinity,
          color: c.bg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Row(children: [
                    Icon(Icons.arrow_back_ios_new_rounded,
                        size: 14, color: c.t3),
                    const SizedBox(width: 6),
                    Text('Back', style: AppTextStyles.bodyMuted(c, size: 12)),
                  ]),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.goldSurface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: c.gold.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    widget.video.category.toUpperCase(),
                    style: AppTextStyles.cinzelSm(c, color: c.gold, size: 8),
                  ),
                ),
                const SizedBox(height: 10),

                Text(widget.video.title,
                    style: AppTextStyles.heading(c, fontSize: 19)),
                const SizedBox(height: 8),

                Row(children: [
                  Icon(Icons.person_outline_rounded, size: 13, color: c.t3),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(widget.video.author,
                        style:
                            AppTextStyles.body(c, size: 12, color: c.t2),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility_outlined, size: 13, color: c.t3),
                  const SizedBox(width: 4),
                  Text('${widget.video.views} views',
                      style: AppTextStyles.bodyMuted(c, size: 12)),
                  if (widget.video.duration != '—') ...[
                    const SizedBox(width: 16),
                    Icon(Icons.schedule_rounded, size: 13, color: c.t3),
                    const SizedBox(width: 4),
                    Text(widget.video.duration,
                        style: AppTextStyles.bodyMuted(c, size: 12)),
                  ],
                ]),

                const SizedBox(height: 16),
                Container(height: 1, color: c.bd),
                const SizedBox(height: 16),

                Text(
                  widget.video.description.isNotEmpty
                      ? widget.video.description
                      : 'A carefully curated piece of Islamic content from '
                          '${widget.video.author}. Watch in-app for the full experience.',
                  style: AppTextStyles.body(c, size: 13.5, color: c.t2)
                      .copyWith(height: 1.6),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    // Before player starts: show thumbnail
    if (!_started) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Column(children: [
          _buildThumbnail(c),
          _buildMeta(c, context),
        ]),
      );
    }

    // YoutubePlayerBuilder MUST be the root widget — handles fullscreen correctly.
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ctrl!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: c.gold,
        progressColors: ProgressBarColors(
          playedColor:     c.gold,
          handleColor:     c.gold2,
          bufferedColor:   c.gold.withValues(alpha: 0.30),
          backgroundColor: Colors.white.withValues(alpha: 0.10),
        ),
        bufferIndicator: const Center(
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5),
        ),
      ),
      builder: (ctx, player) => Scaffold(
        backgroundColor: Colors.black,
        body: Column(children: [
          // Error overlay replaces player area
          if (_hasError)
            _ErrorTile(c: c, onRetry: _retry)
          else
            // Overlay a loading screen until WebView is ready
            Stack(children: [
              player,
              if (!_ready)
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    child: Stack(children: [
                      Positioned.fill(
                        child: Image.network(
                          'https://img.youtube.com/vi/${widget.video.youtubeId}/hqdefault.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.black87),
                        ),
                      ),
                      Container(color: Colors.black.withValues(alpha: 0.55)),
                      const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      ),
                    ]),
                  ),
                ),
            ]),
          _buildMeta(c, ctx),
        ]),
      ),
    );
  }
}

// ── Error tile ────────────────────────────────────────────────────────────────

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.c, required this.onRetry});
  final AppColors c;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 36),
            const SizedBox(height: 10),
            const Text('Video unavailable',
                style: TextStyle(color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            const Text(
              'This video may be restricted or unavailable.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: c.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.gold.withValues(alpha: 0.35)),
                ),
                child: Text('Retry',
                    style: TextStyle(color: c.gold, fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
