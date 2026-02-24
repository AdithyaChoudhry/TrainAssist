import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station_alert_model.dart';
import '../services/notification_service.dart';

class StationAlertProvider extends ChangeNotifier {
  static const _key = 'station_alerts';

  List<StationAlert> _alerts = [];
  Timer? _ticker;
  String? _triggerMessage;

  List<StationAlert> get alerts =>
      _alerts.where((a) => !a.isExpired).toList();
  String? get triggerMessage => _triggerMessage;

  StationAlertProvider() {
    _load();
    // Check every 10 seconds for more responsive alerts
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addAlert(StationAlert alert) async {
    _alerts.add(alert);
    await _save();
    notifyListeners();
  }

  Future<void> removeAlert(String id) async {
    _alerts.removeWhere((a) => a.id == id);
    await _save();
    notifyListeners();
  }

  void clearTriggerMessage() {
    _triggerMessage = null;
    notifyListeners();
  }

  // ── Countdown logic ────────────────────────────────────────────────────────

  void _check() {
    bool changed = false;
    for (final alert in _alerts) {
      if (alert.isTriggered || alert.isExpired) continue;
      final mins = alert.timeRemaining.inMinutes;

      if (mins <= 5) {
        alert.isTriggered = true;
        _triggerMessage =
            '🚨 WAKE UP! "${alert.destinationStation}" arriving in ~$mins min!\n'
            '${alert.elderlyMode ? "⚠️ Elderly Alert — prepare to deboard!" : "Get off at the next stop!"}';
        // Fire the alarm 3 × with 5-second gaps so the beep repeats
        // (each showStationAlert re-triggers sound + vibration on the device)
        int _repeat = 0;
        Timer.periodic(const Duration(seconds: 5), (t) {
          NotificationService().showStationAlert(
            '🚨 Your stop is almost here!',
            '"${alert.destinationStation}" arriving in ~$mins minute${mins == 1 ? "" : "s"}! '
            '${alert.elderlyMode ? "⚠️ Elderly mode — please prepare now!" : "Get ready to deboard!"}',
          );
          if (++_repeat >= 3) t.cancel();
        });
        // Also fire once immediately
        HapticFeedback.heavyImpact();
        NotificationService().showStationAlert(
          '🚨 Your stop is almost here!',
          '"${alert.destinationStation}" arriving in ~$mins minute${mins == 1 ? "" : "s"}! '
          '${alert.elderlyMode ? "⚠️ Elderly mode — please prepare now!" : "Get ready to deboard!"}',
        );
        changed = true;
        _save();
      } else if (mins <= 15) {
        _triggerMessage =
            '⏰ "${alert.destinationStation}" arriving in ~$mins minutes. Get ready!';
        HapticFeedback.mediumImpact();
        NotificationService().showStationAlert(
          '⏰ Approaching ${alert.destinationStation}',
          '~$mins minutes away. Start packing your belongings.',
        );
        changed = true;
      } else if (mins <= 30) {
        _triggerMessage =
            '🔔 "${alert.destinationStation}" is ~$mins minutes away.';
        HapticFeedback.lightImpact();
        NotificationService().showStationAlert(
          '🔔 ${alert.destinationStation} in ~$mins min',
          'You\'re about ${mins} minutes from your stop.',
        );
        changed = true;
      }
    }
    // Clean expired
    _alerts.removeWhere((a) => a.isExpired && a.isTriggered);
    if (changed) notifyListeners();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _alerts = list
            .map((e) => StationAlert.fromJson(e as Map<String, dynamic>))
            .where((a) => !a.isExpired)
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(_alerts.map((a) => a.toJson()).toList()));
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
