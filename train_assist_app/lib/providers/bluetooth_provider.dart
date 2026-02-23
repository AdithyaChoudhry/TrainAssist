import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/bluetooth_service.dart';

/// State management for real Bluetooth crowd detection
class BluetoothProvider extends ChangeNotifier {
  final BluetoothCrowdService _btService = BluetoothCrowdService();

  bool _isScanning = false;
  String _scanProgress = '';
  BluetoothScanResult? _lastResult;
  String? _errorMessage;

  bool get isScanning => _isScanning;
  String get scanProgress => _scanProgress;
  BluetoothScanResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;

  /// The crowd level detected from the last scan ("Low", "Medium", "High")
  String? get detectedCrowdLevel => _lastResult?.crowdLevel;

  /// Runs a Bluetooth scan (real BLE on device, physics sim on web).
  Future<BluetoothScanResult?> startScan({int coachCapacity = kDefaultCoachCapacity}) async {
    if (_isScanning) return null;

    _isScanning = true;
    _scanProgress = 'Requesting Bluetooth access…';
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    final progressController = StreamController<String>.broadcast();
    final sub = progressController.stream.listen((msg) {
      _scanProgress = msg;
      notifyListeners();
    });

    try {
      final result = await _btService.scanForCrowd(
        coachCapacity: coachCapacity,
        progressController: progressController,
      );
      _lastResult = result;
      _scanProgress = result.summaryLine;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _scanProgress = '';
      notifyListeners();
      return null;
    } finally {
      _isScanning = false;
      await sub.cancel();
      await progressController.close();
      notifyListeners();
    }
  }

  void clearResult() {
    _lastResult = null;
    _scanProgress = '';
    _errorMessage = null;
    notifyListeners();
  }
}
