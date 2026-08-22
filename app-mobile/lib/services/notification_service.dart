import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/adhan_settings.dart';

// ── Platform setup required ───────────────────────────────────────────────────
//
// ANDROID — android/app/src/main/AndroidManifest.xml:
//   Add BEFORE <application>:
//     <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
//     <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
//     <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
//     <uses-permission android:name="android.permission.WAKE_LOCK"/>
//     <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
//     <uses-permission android:name="android.permission.VIBRATE"/>
//     <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
//     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//
//   Add INSIDE <application>:
//     <receiver android:exported="true"
//       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver">
//       <intent-filter>
//         <action android:name="android.intent.action.BOOT_COMPLETED"/>
//         <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
//       </intent-filter>
//     </receiver>
//     <receiver android:exported="false"
//       android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver"/>
//
// ANDROID — Put Adhan audio files in:
//   android/app/src/main/res/raw/adhan.mp3
//   android/app/src/main/res/raw/adhan_makkah.mp3  (etc.)
//   These play AUTOMATICALLY when the alarm notification fires — even if the app is closed.
//
// iOS — ios/Runner/Info.plist:
//   <key>UIBackgroundModes</key>
//   <array>
//     <string>audio</string>
//     <string>fetch</string>
//     <string>remote-notification</string>
//   </array>
//
// iOS — Put Adhan audio files in:
//   ios/Runner/adhan.mp3
//   ios/Runner/adhan_makkah.mp3  (etc.)
//
// ─────────────────────────────────────────────────────────────────────────────

// Top-level background handler — MUST be a top-level function, not a method.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint('[NotificationService] background: ${response.payload}');
}

/// Prayer entry passed to the scheduler.
class PrayerAlarmEntry {
  final String   name;
  final int      index; // 0=Fajr … 4=Isha
  final DateTime time;
  const PrayerAlarmEntry({
    required this.name,
    required this.index,
    required this.time,
  });
}

class NotificationService {
  NotificationService._();
  static final NotificationService _i = NotificationService._();
  static NotificationService get instance => _i;

  final _plugin     = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Channel IDs ───────────────────────────────────────────────────────────

  static const _alarmChannelId   = 'sg_adhan_alarm_v2';
  static const _alarmChannelName = 'Adhan Alarm';
  static const _alarmChannelDesc = 'Full-screen Adhan alarm for prayer times';

  static const _reminderChannelId   = 'sg_prayer_reminder_v2';
  static const _reminderChannelName = 'Prayer Reminder';
  static const _reminderChannelDesc = '10-minute pre-prayer reminder';

  // ── Notification ID layout ────────────────────────────────────────────────
  // Alarm:    prayer_index + (day * 10)   → 0–49
  // Reminder: prayer_index + (day * 10) + 100 → 100–149

  static int _alarmId(int prayerIdx, int day)    => prayerIdx + (day * 10);
  static int _reminderId(int prayerIdx, int day)  => prayerIdx + (day * 10) + 100;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (kIsWeb)        return;
    if (_initialized)  return;

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
        iOS:     iosSettings,
      ),
      onDidReceiveNotificationResponse:           _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
    );

    await _createChannels();
    _initialized = true;
    debugPrint('[NotificationService] initialized.');
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // Alarm channel — max priority, custom Adhan sound, vibration
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        _alarmChannelId,
        _alarmChannelName,
        description:      _alarmChannelDesc,
        importance:       Importance.max,
        playSound:        true,
        // 'adhan' refers to android/app/src/main/res/raw/adhan.mp3
        sound:            const RawResourceAndroidNotificationSound('adhan'),
        enableVibration:  true,
        vibrationPattern: Int64List.fromList([0, 800, 200, 600, 200, 800]),
        showBadge:        true,
        enableLights:     true,
        ledColor:         const Color(0xFFD4A843),
      ),
    );

    // Reminder channel — high priority, default sound
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        _reminderChannelName,
        description:  _reminderChannelDesc,
        importance:   Importance.high,
        playSound:    true,
        showBadge:    false,
      ),
    );
  }

  void _onForegroundResponse(NotificationResponse response) {
    debugPrint('[NotificationService] foreground tap: ${response.payload}');
    // Route handling happens in main.dart via getInitialNotificationAction
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  // ── Scheduling ────────────────────────────────────────────────────────────

  /// Schedule Adhan alarms for [days] days.
  ///
  /// [prayersByDay] is a map of day-offset → prayer list for that day.
  /// Day 0 = today, 1 = tomorrow, 2 = day after.
  Future<void> scheduleAlarms({
    required Map<int, List<PrayerAlarmEntry>> prayersByDay,
    required AdhanSettings settings,
  }) async {
    if (kIsWeb || !_initialized) return;

    await _plugin.cancelAll();

    if (!settings.enabled) {
      debugPrint('[NotificationService] alarms disabled — cancelled all.');
      return;
    }

    final now       = DateTime.now();
    final sound     = soundByKey(settings.soundKey);
    final vibration = settings.vibrate
        ? Int64List.fromList([0, 800, 200, 600, 200, 800])
        : null;

    for (final entry in prayersByDay.entries) {
      final day     = entry.key;
      final prayers = entry.value;

      for (final p in prayers) {
        if (!(settings.prayerOn(p.name))) continue;
        if (p.time.isBefore(now)) continue;

        final tzTime  = tz.TZDateTime.from(p.time, tz.local);
        final notifId = _alarmId(p.index, day);
        final emoji   = kPrayerEmojis[p.name] ?? '🕌';

        // ── Main alarm ────────────────────────────────────────────────────
        try {
          await _plugin.zonedSchedule(
            notifId,
            '$emoji  ${p.name} Prayer',
            'Time for ${p.name}. Rise and answer the call of Allah. Allahu Akbar!',
            tzTime,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _alarmChannelId,
                _alarmChannelName,
                channelDescription: _alarmChannelDesc,
                importance:         Importance.max,
                priority:           Priority.max,
                category:           AndroidNotificationCategory.alarm,
                visibility:         NotificationVisibility.public,
                fullScreenIntent:   true,        // shows over lock screen
                ongoing:            false,
                autoCancel:         true,
                icon:               '@mipmap/ic_launcher',
                // Sound from res/raw/ — plays automatically when alarm fires
                sound:              RawResourceAndroidNotificationSound(
                                        sound.rawResource),
                playSound:          true,
                enableVibration:    settings.vibrate,
                vibrationPattern:   vibration,
                styleInformation:   BigTextStyleInformation(
                  'It is time for ${p.name} prayer. '
                  'Rise and answer the call of Allah.',
                  summaryText: p.name,
                ),
                actions: [
                  const AndroidNotificationAction(
                    'dismiss',
                    'Dismiss',
                    cancelNotification: true,
                  ),
                ],
              ),
              iOS: DarwinNotificationDetails(
                presentAlert:      true,
                presentBadge:      true,
                presentSound:      true,
                sound:             '${sound.rawResource}.mp3', // from ios/Runner/
                interruptionLevel: InterruptionLevel.timeSensitive,
                categoryIdentifier: 'prayer_alarm',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'prayer:${p.name}:${p.time.toIso8601String()}',
          );
          debugPrint('[NotificationService] ✓ Alarm set: ${p.name} @ ${p.time} (id=$notifId)');
        } catch (e) {
          debugPrint('[NotificationService] alarm error (${p.name}): $e');
        }

        // ── 10-minute pre-prayer reminder ─────────────────────────────────
        if (settings.preAdhanReminder) {
          final reminderTime = p.time.subtract(const Duration(minutes: 10));
          if (reminderTime.isAfter(now)) {
            try {
              await _plugin.zonedSchedule(
                _reminderId(p.index, day),
                '$emoji  ${p.name} in 10 minutes',
                'Time to prepare for ${p.name} prayer.',
                tz.TZDateTime.from(reminderTime, tz.local),
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    _reminderChannelId,
                    _reminderChannelName,
                    channelDescription: _reminderChannelDesc,
                    importance: Importance.high,
                    priority:   Priority.high,
                    autoCancel: true,
                  ),
                  iOS: DarwinNotificationDetails(
                    presentAlert: true,
                    presentSound: true,
                    interruptionLevel: InterruptionLevel.timeSensitive,
                  ),
                ),
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
                payload: 'reminder:${p.name}',
              );
              debugPrint('[NotificationService] ✓ Reminder set: ${p.name} @ $reminderTime');
            } catch (e) {
              debugPrint('[NotificationService] reminder error (${p.name}): $e');
            }
          }
        }
      }
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
    debugPrint('[NotificationService] all notifications cancelled.');
  }
}
