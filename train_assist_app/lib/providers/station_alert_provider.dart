import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station_alert_model.dart';

class StationAlertProvider extends ChangeNotifier {
  static const _key = 'station_alerts';

  List<StationAlert> _alerts = [];
  Timer? _ticker;
  String? _triggerMessage; // non-null when an alert fires

  List<StationAlert> get alerts =>
      _alerts.where((a) => !a.isExpired).toList();
  String? get triggerMessage => _triggerMessage;

  StationAlertProvider() {
    _load();
    // Poll every 30 seconds to check alert thresholds
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _check());
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
    for (final alert in _alerts) {
      if (alert.isTriggered || alert.isExpired) continue;
      final mins = alert.timeRemaining.inMinutes;

      if (mins <= 5) {
        alert.isTriggered = true;
        _triggerMessage =
            '🚨 WAKE UP! "${alert.destinationStation}" is arriving in ~${mins} min!\n'
            '${alert.elderlyMode ? "⚠️ Elderly Alert active — prepare to deboard!" : ""}';
        // Strong haptic
        HapticFeedback.vibrate();
        HapticFeedback.heavyImpact();
        _save();
        notifyListeners();
      } else if (mins <= 15) {
        _triggerMessage =
            '⏰ "${alert.destinationStation}" arriving in ~${mins} minutes. Get ready!';
        HapticFeedback.mediumImpact();
        notifyListeners();
      } else if (mins <= 30) {
        _triggerMessage =
            '🔔 "${alert.destinationStation}" is ~${mins} minutes away.';
        HapticFeedback.lightImpact();
        notifyListeners();
      }
    }
    // Clean expired
    _alerts.removeWhere((a) => a.isExpired && a.isTriggered);
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
