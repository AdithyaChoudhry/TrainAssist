import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/medical_profile_model.dart';

/// Manages a persistent lock-screen notification that displays
/// the user's emergency medical information.
/// The notification has PUBLIC visibility → visible on Android lock screen
/// without requiring the phone to be unlocked.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _medicalNotifId = 1001;
  static const String _channelId = 'medical_emergency';
  static const String _channelName = 'Emergency Medical Info';
  static const String _channelDesc =
      'Shows your medical details on the lock screen for first responders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Call once at app startup (before any notification is shown).
  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    // Create the notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    _initialized = true;
  }

  /// Show / update the medical emergency notification.
  /// Visible on the lock screen because visibility = public.
  Future<void> showMedicalNotification(MedicalProfile profile) async {
    await init();

    // Build a readable summary for the lock screen
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

    final body = lines.isEmpty
        ? 'Tap to view your medical profile.'
        : lines.join('\n');

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,                        // can't be swiped away
      autoCancel: false,
      // PUBLIC → full details visible on lock screen without unlocking
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
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

  /// Cancel the notification (when profile is cleared).
  Future<void> cancelMedicalNotification() async {
    await init();
    await _plugin.cancel(_medicalNotifId);
  }
}
