import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../models/adhan_settings.dart';

// ── Asset setup ───────────────────────────────────────────────────────────────
//
// Required audio files (place in assets/audio/):
//   adhan.mp3          — Classic/default Adhan
//   adhan_makkah.mp3   — Makkah Adhan (optional)
//   adhan_madinah.mp3  — Madinah Adhan (optional)
//   adhan_fajr.mp3     — Fajr-specific Adhan (optional)
//
// Also copy each .mp3 to:
//   android/app/src/main/res/raw/   (for notification sound)
//   ios/Runner/                      (for notification sound)
//
// The file in assets/audio/ is used for in-app playback via just_audio.
// The file in res/raw/ / ios/Runner/ is used for the automatic alarm sound
// that plays when the notification fires — even when the app is closed.
// ─────────────────────────────────────────────────────────────────────────────

class AdhanService {
  AdhanService._();
  static final AdhanService _i = AdhanService._();
  static AdhanService get instance => _i;

  final AudioPlayer _player    = AudioPlayer();
  final AudioPlayer _preview   = AudioPlayer(); // separate player for previews
  String?           _loadedKey;
  bool              _isReady   = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init({String soundKey = 'adhan_classic'}) async {
    if (kIsWeb) return;
    await _loadSound(soundKey);
  }

  Future<void> _loadSound(String key) async {
    if (_loadedKey == key && _isReady) return;
    final sound = soundByKey(key);
    try {
      await rootBundle.load(sound.assetPath); // throws if file missing
      await _player.setAsset(sound.assetPath);
      _loadedKey = key;
      _isReady   = true;
      debugPrint('[AdhanService] loaded: ${sound.assetPath}');
    } catch (e) {
      _isReady = false;
      debugPrint('[AdhanService] "${sound.assetPath}" not found. '
          'Add the .mp3 file to assets/audio/ to enable playback.');
    }
  }

  // ── Playback ──────────────────────────────────────────────────────────────

  /// Plays the full Adhan. Call this when the alarm fires and app is open.
  Future<void> playAdhan({
    String soundKey = 'adhan_classic',
    double volume   = 1.0,
  }) async {
    if (kIsWeb) return;
    if (_loadedKey != soundKey || !_isReady) await _loadSound(soundKey);
    if (!_isReady) return;
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
      await _player.seek(Duration.zero);
      await _player.play();
      debugPrint('[AdhanService] playing Adhan ($soundKey, vol=$volume)');
    } catch (e) {
      debugPrint('[AdhanService] playAdhan error: $e');
    }
  }

  /// Preview a sound in the settings screen (uses separate player).
  Future<void> previewSound(String soundKey, {double volume = 1.0}) async {
    if (kIsWeb) return;
    final sound = soundByKey(soundKey);
    try {
      await rootBundle.load(sound.assetPath);
      await _preview.setAsset(sound.assetPath);
      await _preview.setVolume(volume.clamp(0.0, 1.0));
      await _preview.seek(Duration.zero);
      // Play only first 6 seconds for preview
      await _preview.play();
      Future.delayed(const Duration(seconds: 6), stopPreview);
    } catch (e) {
      debugPrint('[AdhanService] previewSound "${sound.assetPath}" '
          'not found — file missing from assets/audio/');
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> stopPreview() async => _preview.stop();

  Future<void> stopAdhan() async {
    await _player.stop();
    debugPrint('[AdhanService] Adhan stopped.');
  }

  bool get isPlaying => _player.playing;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // ── Timer-based scheduling (foreground only) ──────────────────────────────
  //
  // This schedules a timer for when the app is open/foreground.
  // For background/killed state, use NotificationService which plays
  // the sound automatically via the notification channel sound.

  Timer? _fgTimer;

  void scheduleForegroundAdhan(DateTime prayerTime,
      {String soundKey = 'adhan_classic', double volume = 1.0}) {
    if (kIsWeb) return;
    _fgTimer?.cancel();
    final delay = prayerTime.difference(DateTime.now());
    if (delay.isNegative || delay.inHours > 12) return;
    _fgTimer = Timer(delay, () {
      playAdhan(soundKey: soundKey, volume: volume);
      debugPrint('[AdhanService] foreground timer fired for $prayerTime');
    });
    debugPrint('[AdhanService] foreground timer set: $delay until $prayerTime');
  }

  void cancelForegroundTimer() {
    _fgTimer?.cancel();
    _fgTimer = null;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    _fgTimer?.cancel();
    await _player.dispose();
    await _preview.dispose();
  }
}
