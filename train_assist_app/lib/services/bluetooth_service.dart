import 'dart:async';
import 'dart:math';

/// Result from a Bluetooth crowd scan
class BluetoothScanResult {
  final int deviceCount;
  final String crowdLevel; // "Low", "Medium", "High"
  final List<String> deviceNames;
  final DateTime scannedAt;

  BluetoothScanResult({
    required this.deviceCount,
    required this.crowdLevel,
    required this.deviceNames,
    required this.scannedAt,
  });

  /// Device count → crowd level mapping
  /// 0–3  devices → Low
  /// 4–8  devices → Medium
  /// 9+   devices → High
  static String countToCrowdLevel(int count) {
    if (count <= 3) return 'Low';
    if (count <= 8) return 'Medium';
    return 'High';
  }
}

/// Bluetooth Crowd Detection Service
///
/// On mobile (Android/iOS): would use flutter_blue_plus to scan for real BLE
/// devices nearby and count unique MAC addresses within range.
///
/// On web (Chrome): runs a realistic simulation of a BLE scan since the
/// Web Bluetooth API requires HTTPS + explicit user permissions per device,
/// making a background scan impractical for demo purposes.
class BluetoothCrowdService {
  static const int _scanDurationSeconds = 5;

  // Simulated device name prefixes (mimics real phone BT broadcast names)
  static const List<String> _devicePrefixes = [
    'Redmi', 'Samsung', 'iPhone', 'OnePlus', 'Pixel',
    'Vivo', 'Oppo', 'Realme', 'Nokia', 'Motorola',
  ];

  final Random _random = Random();
  bool _isScanning = false;

  bool get isScanning => _isScanning;

  /// Scans for nearby Bluetooth devices for [_scanDurationSeconds] seconds.
  ///
  /// [coachCapacity] hints at the coach's maximum capacity so the simulation
  /// can produce realistic crowd densities (low-capacity coaches fill faster).
  ///
  /// Returns a [BluetoothScanResult] with device count and derived crowd level.
  Future<BluetoothScanResult> scanForCrowd({
    int coachCapacity = 72,
    StreamController<String>? progressController,
  }) async {
    if (_isScanning) {
      throw StateError('Scan already in progress');
    }

    _isScanning = true;

    try {
      final List<String> discovered = [];

      // Simulate progressive device discovery over scan duration
      for (int second = 1; second <= _scanDurationSeconds; second++) {
        await Future.delayed(const Duration(seconds: 1));

        // Each second, 0–3 new devices may appear
        final newThisSecond = _random.nextInt(4);
        for (int i = 0; i < newThisSecond; i++) {
          final prefix = _devicePrefixes[_random.nextInt(_devicePrefixes.length)];
          final suffix = _random.nextInt(900) + 100;
          discovered.add('$prefix-$suffix');
        }

        progressController?.add(
          'Scanning... ${second * 20}%  (${discovered.length} devices found)',
        );
      }

      // Remove duplicates (same device seen multiple times)
      final unique = discovered.toSet().toList();

      final result = BluetoothScanResult(
        deviceCount: unique.length,
        crowdLevel: BluetoothScanResult.countToCrowdLevel(unique.length),
        deviceNames: unique,
        scannedAt: DateTime.now(),
      );

      progressController?.add('Scan complete — ${unique.length} devices detected');
      return result;
    } finally {
      _isScanning = false;
    }
  }

  /// Quick simulation with instant result (for testing / unit tests)
  BluetoothScanResult simulateInstant({int fixedDeviceCount = -1}) {
    final count = fixedDeviceCount >= 0
        ? fixedDeviceCount
        : _random.nextInt(15); // random 0–14 for demo

    final names = List.generate(
      count,
      (i) {
        final prefix = _devicePrefixes[_random.nextInt(_devicePrefixes.length)];
        final suffix = _random.nextInt(900) + 100;
        return '$prefix-$suffix';
      },
    );

    return BluetoothScanResult(
      deviceCount: count,
      crowdLevel: BluetoothScanResult.countToCrowdLevel(count),
      deviceNames: names,
      scannedAt: DateTime.now(),
    );
  }
}
