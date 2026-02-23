import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Coach geometry constants  (Indian Railways Sleeper / AC coach standards)
// ─────────────────────────────────────────────────────────────────────────────

/// Standard coach length in metres (ICF design: ~24 m over buffers)
const double kCoachLengthMetres = 24.0;

/// Standard coach width in metres (ICF: ~3.2 m interior)
const double kCoachWidthMetres = 3.2;

/// Average seat/berth spacing along coach length in metres
/// (Sleeper: 8 bays × 8 berths in ~24 m → ~0.50 m per berth pitch)
const double kBerthPitchMetres = 0.50;

/// Maximum berths in a standard sleeper coach
const int kDefaultCoachCapacity = 72;

// ─────────────────────────────────────────────────────────────────────────────
// Bluetooth geometry constants
// ─────────────────────────────────────────────────────────────────────────────

/// Effective BLE scan radius inside a metal coach body (walls attenuate)
/// A raw BLE range is ~30 m outdoors, but a metal coach body limits it to
/// roughly 8–10 m in practice.
const double kBleEffectiveRangeMetres = 10.0;

/// RSSI threshold (dBm) for "inside the coach" — signals stronger than this
/// are almost certainly within 5–6 m (same coach).
const int kRssiInsideCoachThreshold = -70;

/// RSSI threshold below which a device is likely on the platform / next coach
const int kRssiPlatformThreshold = -85;

// ─────────────────────────────────────────────────────────────────────────────
// Density algorithm
// ─────────────────────────────────────────────────────────────────────────────

/// Fraction of coach volume covered by a single-point BLE scan.
///
///   coverage = (scan diameter) / (coach length)
///   = (2 × effectiveRange) / coachLength
///   clamped to 1.0 (can't cover more than the whole coach)
double get scanCoverageFraction =>
    ((2 * kBleEffectiveRangeMetres) / kCoachLengthMetres).clamp(0.01, 1.0);

/// Extrapolated total occupants from the [devicesInsideCoach] seen in range.
///
/// Each person carries ~1 device on average (phone). We correct for the
/// fraction of the coach that the scan covers.
int estimateTotalOccupancy({
  required int devicesInsideCoach,
  double coverage = 0,
}) {
  final c = coverage > 0 ? coverage : scanCoverageFraction;
  return (devicesInsideCoach / c).round();
}

/// Maps estimated occupancy to a crowd level.
///
/// ≤ 30 % capacity → Low
/// ≤ 70 % capacity → Medium
/// > 70 % capacity → High
String occupancyToCrowdLevel(int estimatedOccupancy, {int capacity = kDefaultCoachCapacity}) {
  final ratio = estimatedOccupancy / capacity;
  if (ratio <= 0.30) return 'Low';
  if (ratio <= 0.70) return 'Medium';
  return 'High';
}

// ─────────────────────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────────────────────

class BluetoothScanResult {
  /// Raw count of unique devices detected within BLE range
  final int rawDeviceCount;

  /// Devices classified as "inside this coach" by RSSI filter
  final int insideCoachCount;

  /// Estimated total occupancy for the whole coach (after coverage correction)
  final int estimatedOccupancy;

  /// Crowd level derived from estimated occupancy: "Low" / "Medium" / "High"
  final String crowdLevel;

  /// Percentage of coach capacity (0–100)
  final int occupancyPercent;

  /// Names / identifiers of detected devices (for debug/transparency)
  final List<String> deviceNames;

  /// Scan was performed on real hardware (true) or fallback simulation (false)
  final bool isRealScan;

  final DateTime scannedAt;

  BluetoothScanResult({
    required this.rawDeviceCount,
    required this.insideCoachCount,
    required this.estimatedOccupancy,
    required this.crowdLevel,
    required this.occupancyPercent,
    required this.deviceNames,
    required this.isRealScan,
    required this.scannedAt,
  });

  /// Convenience: legacy single device-count getter used by some UI paths
  int get deviceCount => rawDeviceCount;

  String get crowdEmoji =>
      crowdLevel == 'Low' ? '🟢' : crowdLevel == 'Medium' ? '🟡' : '🔴';

  String get summaryLine =>
      '$crowdEmoji $crowdLevel  ($estimatedOccupancy / $kDefaultCoachCapacity est.)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class BluetoothCrowdService {
  static const Duration _scanDuration = Duration(seconds: 8);

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// Main entry point — scans for nearby BT devices and calculates crowd density.
  ///
  /// On Android / iOS: uses flutter_blue_plus for a real BLE scan.
  /// On web or unsupported platforms: falls back to physics-based simulation.
  ///
  /// [coachCapacity] can be overridden for non-standard coaches.
  /// [progressController] receives human-readable progress strings during scan.
  Future<BluetoothScanResult> scanForCrowd({
    int coachCapacity = kDefaultCoachCapacity,
    StreamController<String>? progressController,
  }) async {
    if (_isScanning) throw StateError('Scan already in progress');
    _isScanning = true;
    try {
      // Web or non-mobile → always simulate (no BT API available)
      if (kIsWeb) {
        return _simulateScan(
          coachCapacity: coachCapacity,
          progressController: progressController,
        );
      }

      // Mobile: try real scan, fall back to simulation on error / no support
      try {
        return await _realScan(
          coachCapacity: coachCapacity,
          progressController: progressController,
        );
      } catch (_) {
        progressController?.add('BT unavailable — using proximity simulation...');
        return await _simulateScan(
          coachCapacity: coachCapacity,
          progressController: progressController,
        );
      }
    } finally {
      _isScanning = false;
    }
  }

  // ── Real BLE scan (Android / iOS) ─────────────────────────────────────────

  Future<BluetoothScanResult> _realScan({
    required int coachCapacity,
    StreamController<String>? progressController,
  }) async {
    // 1. Request permissions
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,           // needed on Android < 12
      ].request();

      final denied = statuses.values.any(
        (s) => s.isDenied || s.isPermanentlyDenied,
      );
      if (denied) throw Exception('Bluetooth permissions denied');
    }

    // 2. Check adapter state
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      throw Exception('Bluetooth is off — please enable it');
    }

    progressController?.add('Scanning for nearby devices (${_scanDuration.inSeconds}s)…');

    // 3. Start BLE scan (scan for both connectable and non-connectable adverts)
    final Map<String, ScanResult> seen = {};

    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        seen[r.device.remoteId.str] = r;
      }
      final inside = seen.values
          .where((r) => r.rssi >= kRssiInsideCoachThreshold)
          .length;
      progressController?.add(
        'Found ${seen.length} device(s) — $inside likely inside coach…',
      );
    });

    await FlutterBluePlus.startScan(
      timeout: _scanDuration,
      androidScanMode: AndroidScanMode.lowLatency,
    );

    // Wait for scan to complete
    await FlutterBluePlus.isScanning.where((s) => !s).first;
    await sub.cancel();

    return _buildResult(seen.values.toList(), coachCapacity, isReal: true);
  }

  // ── Physics-based simulation (web / fallback) ─────────────────────────────
  //
  // Instead of random numbers, we model a realistic occupied coach:
  //   • Peak-hour trains: 60–90 % occupancy
  //   • Off-peak: 20–50 %
  //   • Random variance ±15 %
  //
  // We then back-calculate how many devices would appear in the scan
  // coverage zone from that occupancy.

  Future<BluetoothScanResult> _simulateScan({
    required int coachCapacity,
    StreamController<String>? progressController,
  }) async {
    final now = DateTime.now();
    // Rush hour: 7–10 am, 5–8 pm
    final isRushHour =
        (now.hour >= 7 && now.hour < 10) || (now.hour >= 17 && now.hour < 20);
    final baseOccupancyRatio = isRushHour ? 0.72 : 0.38;
    const variance = 0.15;
    final jitter = (DateTime.now().millisecond / 1000.0) * variance - (variance / 2);
    final occupancyRatio = (baseOccupancyRatio + jitter).clamp(0.05, 1.0);
    final totalOccupied = (coachCapacity * occupancyRatio).round();

    // Devices visible in scan zone = occupancy × coverage fraction
    final inZone = (totalOccupied * scanCoverageFraction).round();

    // Simulate progressive discovery
    final fakeDevices = <String>[];
    for (int i = 0; i < inZone; i++) {
      fakeDevices.add('Device-${i + 1}');
    }

    for (int pct in [25, 50, 75, 100]) {
      await Future.delayed(const Duration(milliseconds: 500));
      progressController?.add('Scanning… $pct%  (${(inZone * pct / 100).round()} devices detected)');
    }

    final occupancyPercent = (occupancyRatio * 100).round();
    return BluetoothScanResult(
      rawDeviceCount: inZone,
      insideCoachCount: inZone,
      estimatedOccupancy: totalOccupied,
      crowdLevel: occupancyToCrowdLevel(totalOccupied, capacity: coachCapacity),
      occupancyPercent: occupancyPercent,
      deviceNames: fakeDevices,
      isRealScan: false,
      scannedAt: DateTime.now(),
    );
  }

  // ── Build result from real scan data ──────────────────────────────────────

  BluetoothScanResult _buildResult(
    List<ScanResult> results,
    int coachCapacity, {
    required bool isReal,
  }) {
    // Filter: keep devices with a strong enough signal (inside the coach)
    final inside = results
        .where((r) => r.rssi >= kRssiInsideCoachThreshold)
        .toList();

    // Nearby but possibly on platform
    final nearby = results
        .where((r) =>
            r.rssi >= kRssiPlatformThreshold &&
            r.rssi < kRssiInsideCoachThreshold)
        .toList();

    // Count inside + half of "nearby" (they might be in adjacent bays)
    final effectiveCount = inside.length + (nearby.length / 2).round();

    final estimated = estimateTotalOccupancy(devicesInsideCoach: effectiveCount);
    final occupancyPercent = ((estimated / coachCapacity) * 100).clamp(0, 100).round();

    final deviceNames = results.map((r) {
      final name = r.device.platformName.isNotEmpty
          ? r.device.platformName
          : r.device.remoteId.str;
      return '$name (${r.rssi} dBm)';
    }).toList();

    return BluetoothScanResult(
      rawDeviceCount: results.length,
      insideCoachCount: inside.length,
      estimatedOccupancy: estimated,
      crowdLevel: occupancyToCrowdLevel(estimated, capacity: coachCapacity),
      occupancyPercent: occupancyPercent,
      deviceNames: deviceNames,
      isRealScan: isReal,
      scannedAt: DateTime.now(),
    );
  }
}
