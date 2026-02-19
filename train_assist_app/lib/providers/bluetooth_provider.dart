import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/bluetooth_service.dart';

/// State management for Bluetooth crowd detection scans
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

  /// Runs a 5-second Bluetooth scan and updates state with results
  Future<BluetoothScanResult?> startScan() async {
    if (_isScanning) return null;

    _isScanning = true;
    _scanProgress = 'Starting Bluetooth scan...';
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    final progressController = StreamController<String>();
    final sub = progressController.stream.listen((msg) {
      _scanProgress = msg;
      notifyListeners();
    });

    try {
      final result = await _btService.scanForCrowd(
        progressController: progressController,
      );
      _lastResult = result;
      _scanProgress = 'Done — ${result.deviceCount} devices → ${result.crowdLevel} crowd';
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = 'Bluetooth scan failed: $e';
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
