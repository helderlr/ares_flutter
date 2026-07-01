import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CurrentLocationResult {
  final LatLng position;
  final String addressLabel;

  const CurrentLocationResult({
    required this.position,
    required this.addressLabel,
  });
}

class CurrentLocationService {
  static Future<CurrentLocationResult?> resolve() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final LatLng latLng = LatLng(position.latitude, position.longitude);
      final String address = await _resolveAddress(latLng);
      return CurrentLocationResult(
        position: latLng,
        addressLabel: address,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> _resolveAddress(LatLng location) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
        localeIdentifier: 'pt_BR',
      );
      if (placemarks.isEmpty) {
        return _formatCoordinates(location);
      }
      final Placemark place = placemarks.first;
      final List<String> parts = <String>[
        place.street ?? '',
        place.subLocality ?? '',
        place.locality ?? '',
        place.administrativeArea ?? '',
      ].where((String part) => part.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
      return _formatCoordinates(location);
    } catch (_) {
      return _formatCoordinates(location);
    }
  }

  static String _formatCoordinates(LatLng location) {
    return '${location.latitude.toStringAsFixed(5)}, '
        '${location.longitude.toStringAsFixed(5)}';
  }
}
