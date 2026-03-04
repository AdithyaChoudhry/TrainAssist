import 'package:geolocator/geolocator.dart';

/// Wraps geolocator with permission handling.
/// Zero cost — uses device GPS only.
class LocationService {
  /// Returns the current Position or null if permission denied / GPS off.
  static Future<Position?> getCurrentLocation() async {
    // Check if GPS is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // Check / request permission
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return null;
    }
    if (perm == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }
  }

  /// Build a free Google Maps link from coordinates.
  static String mapsLink(double lat, double lng) =>
      'https://maps.google.com/?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
}
