import 'dart:typed_data';
import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/medical_profile_model.dart';

/// Manages both the persistent medical lock-screen notification and
/// the audible station arrival alerts.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _medicalNotifId = 1001;
  static const int _alertNotifId   = 1002;

  // Medical: silent, persistent, lock-screen public
  static const String _medChannelId   = 'medical_emergency';
  static const String _medChannelName = 'Emergency Medical Info';
  static const String _medChannelDesc =
      'Shows your medical details on the lock screen for first responders';

  // Station alert: MAX importance so Android forces sound+vibration even on locked screen
  // _v3 forces fresh channel recreation (old cached channels ignore new settings)
  static const String _alertChannelId   = 'station_alert_v3';
  static const String _alertChannelName = 'Station Arrival Alert';
  static const String _alertChannelDesc =
      'Plays sound and vibrates when your destination is approaching';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Call once at app startup.
  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Request POST_NOTIFICATIONS permission at runtime (Android 13 / API 33+)
    await androidImpl?.requestNotificationsPermission();

    // Medical channel — silent, ongoing
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _medChannelId,
      _medChannelName,
      description: _medChannelDesc,
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    ));

    // Station alert channel — MAX importance, 10-pulse vibration, LED
    await androidImpl?.createNotificationChannel(AndroidNotificationChannel(
      _alertChannelId,
      _alertChannelName,
      description: _alertChannelDesc,
      importance: Importance.max,          // max = guaranteed heads-up + sound
      playSound: true,
      enableVibration: true,
      // 10 pulses: [delay, buzz, pause, buzz, ...] — feels continuous
      vibrationPattern: Int64List.fromList([
        0, 900, 200, 900, 200, 900, 200, 900, 200, 900,
        200, 900, 200, 900, 200, 900, 200, 900, 200, 900,
      ]),
      enableLights: true,
      ledColor: const Color(0xFF3949AB),
    ));

    _initialized = true;
  }

  // ── Station Alert Notification ──────────────────────────────────────────────

  /// Show a loud heads-up notification for a station arrival alert.
  Future<void> showStationAlert(String title, String body) async {
    await init();
    final androidDetails = AndroidNotificationDetails(
      _alertChannelId,
      _alertChannelName,
      channelDescription: _alertChannelDesc,
      importance: Importance.max,          // must match channel
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([
        0, 900, 200, 900, 200, 900, 200, 900, 200, 900,
        200, 900, 200, 900, 200, 900, 200, 900, 200, 900,
      ]),
      enableLights: true,
      ledColor: const Color(0xFF3949AB),
      ledOnMs: 1000,
      ledOffMs: 500,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,   // wakes locked screen
      ongoing: false,
      autoCancel: true,
      ticker: 'TrainAssist Station Alert',
      color: const Color(0xFF3949AB),
    );
    await _plugin.show(
      _alertNotifId,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  // ── Medical Lock-screen Notification ────────────────────────────────────────

  /// Show / update the medical emergency notification.
  Future<void> showMedicalNotification(MedicalProfile profile) async {
    await init();

    final lines = <String>[];
    if (profile.bloodGroup != 'Not Set' && profile.bloodGroup.isNotEmpty) {
      lines.add('🩸 Blood: ${profile.bloodGroup}');
    }
    if (profile.allergies.isNotEmpty) {
      lines.add('⚠️ Allergies: ${profile.allergies}');
    }
    if (profile.conditions.isNotEmpty) {
      lines.add('💊 Conditions: ${profile.conditions}');
    }
    if (profile.emergencyContact1Name.isNotEmpty) {
      lines.add(
          '📞 ${profile.emergencyContact1Name}: ${profile.emergencyContact1Phone}');
    }
    if (profile.emergencyContact2Name.isNotEmpty) {
      lines.add(
          '📞 ${profile.emergencyContact2Name}: ${profile.emergencyContact2Phone}');
    }
    if (profile.doctorName.isNotEmpty) {
      lines.add('🏥 Dr. ${profile.doctorName}: ${profile.doctorPhone}');
    }

    final body = lines.isEmpty ? 'Tap to view your medical profile.' : lines.join('\n');

    final androidDetails = AndroidNotificationDetails(
      _medChannelId,
      _medChannelName,
      channelDescription: _medChannelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: '🚨 Emergency Medical Info',
        summaryText: 'TrainAssist · Tap to open health card',
      ),
      color: const Color(0xFFB00020),
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      _medicalNotifId,
      '🚨 Emergency Medical Info',
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  /// Cancel the medical notification (when profile is cleared).
  Future<void> cancelMedicalNotification() async {
    await init();
    await _plugin.cancel(_medicalNotifId);
  }
}
