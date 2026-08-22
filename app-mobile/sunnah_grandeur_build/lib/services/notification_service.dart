import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// ── Native setup required ──────────────────────────────────────────────────────
// Android — android/app/src/main/AndroidManifest.xml:
//   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
//   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
//   Inside <application>:
//     <receiver android:exported="false"
//       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
//
// iOS — ios/Runner/Info.plist:
//   <key>UIBackgroundModes</key><array><string>fetch</string></array>
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final NotificationService _i = NotificationService._();
  static NotificationService get instance => _i;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId   = 'sg_prayer_channel';
  static const _channelName = 'Prayer Alerts';
  static const _channelDesc = 'Adhan & prayer time notifications';

  Future<void> init() async {
    if (kIsWeb) return; // Notifications not supported on web
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create notification channel (Android 8+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
          playSound: true,
        ));

    _initialized = true;
  }

  /// Requests notification permission (iOS / Android 13+).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? true;
  }

  /// Cancels all previously scheduled prayer notifications and schedules
  /// fresh ones for the next 3 days from [prayerSchedule].
  ///
  /// [prayerSchedule] is a list of (name, DateTime) pairs.
  Future<void> schedulePrayerAlerts(
      List<({String name, DateTime time})> prayers) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();

    final now = DateTime.now();
    int id = 1;

    for (final p in prayers) {
      if (p.time.isBefore(now)) continue;

      try {
        await _plugin.zonedSchedule(
          id++,
          'Prayer Time — ${p.name}',
          'It is time for ${p.name} prayer. Allahu Akbar!',
          tz.TZDateTime.from(p.time, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId, _channelName,
              channelDescription: _channelDesc,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('[NotificationService] schedule error: $e');
      }
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}
