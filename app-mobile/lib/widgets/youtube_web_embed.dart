// Web-only YouTube embed. On native platforms this stub is used and never
// rendered (VideoPlayerScreen uses youtube_player_flutter there).
export 'youtube_web_embed_stub.dart'
    if (dart.library.js_interop) 'youtube_web_embed_web.dart';
