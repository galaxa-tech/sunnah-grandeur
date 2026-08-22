import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

// ── Asset setup ───────────────────────────────────────────────────────────────
// Add your audio files to assets/audio/ and declare in pubspec.yaml:
//   assets:
//     - assets/audio/
//
// Required files:
//   assets/audio/adhan.mp3   — full adhan recitation
//   assets/audio/click.mp3   — short UI tap sound (optional)
// ─────────────────────────────────────────────────────────────────────────────

class AdhanService {
  AdhanService._();
  static final AdhanService _i = AdhanService._();
  static AdhanService get instance => _i;

  final AudioPlayer _adhanPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();

  bool _adhanLoaded = false;
  bool _clickLoaded = false;
  Timer? _prayerTimer;

  Future<void> init() async {
    if (kIsWeb) return;
    await _tryLoadAdhan();
    await _tryLoadClick();
  }

  Future<void> _tryLoadAdhan() async {
    try {
      // Check if asset exists before loading
      await rootBundle.load('assets/audio/adhan.mp3');
      await _adhanPlayer.setAsset('assets/audio/adhan.mp3');
      _adhanLoaded = true;
    } catch (_) {
      debugPrint('[AdhanService] adhan.mp3 not found in assets/audio/. '
          'Add the file to enable adhan sound.');
    }
  }

  Future<void> _tryLoadClick() async {
    try {
      await rootBundle.load('assets/audio/click.mp3');
      await _clickPlayer.setAsset('assets/audio/click.mp3');
      _clickLoaded = true;
    } catch (_) {
      // click.mp3 is optional — HapticFeedback handles it as fallback
    }
  }

  /// Play the adhan sound (no-op if asset missing or on web).
  Future<void> playAdhan() async {
    if (kIsWeb || !_adhanLoaded) return;
    try {
      await _adhanPlayer.seek(Duration.zero);
      await _adhanPlayer.play();
    } catch (e) {
      debugPrint('[AdhanService] playAdhan error: $e');
    }
  }

  /// Play a short UI click sound. Falls back to HapticFeedback if no asset.
  Future<void> playClick() async {
    if (kIsWeb) return;
    if (_clickLoaded) {
      try {
        await _clickPlayer.seek(Duration.zero);
        await _clickPlayer.play();
        return;
      } catch (_) {}
    }
    // Fallback: system haptic
    HapticFeedback.lightImpact();
  }

  /// Schedules adhan to fire at [prayerTime]. Cancels any previous timer.
  void scheduleAdhanAt(DateTime prayerTime) {
    if (kIsWeb) return;
    _prayerTimer?.cancel();
    final delay = prayerTime.difference(DateTime.now());
    if (delay.isNegative) return;
    _prayerTimer = Timer(delay, playAdhan);
  }

  Future<void> stopAdhan() async {
    await _adhanPlayer.stop();
  }

  void dispose() {
    _prayerTimer?.cancel();
    _adhanPlayer.dispose();
    _clickPlayer.dispose();
  }
}
