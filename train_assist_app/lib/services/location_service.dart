import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

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

  /// Open the device location settings. Returns true if the settings activity
  /// was opened (best-effort). Useful for prompting users to enable GPS.
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Reverse-geocode coordinates to a single-line address when possible.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final places = await geo.placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return null;
      final p = places.first;
      final parts = <String>[];
      if (p.name != null && p.name!.isNotEmpty) parts.add(p.name!);
      if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
      if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) parts.add(p.administrativeArea!);
      if (p.postalCode != null && p.postalCode!.isNotEmpty) parts.add(p.postalCode!);
      if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);
      if (parts.isEmpty) return null;
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
