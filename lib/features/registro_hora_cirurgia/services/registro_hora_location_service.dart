import '../../../core/utils/address_text_helper.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RegistroHoraLocationCapture {
  final LatLng position;
  final double accuracyMeters;
  final String addressLabel;

  const RegistroHoraLocationCapture({
    required this.position,
    required this.accuracyMeters,
    required this.addressLabel,
  });
}

class RegistroHoraLocationService {
  static Future<RegistroHoraLocationCapture?> capture() async {
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
        desiredAccuracy: LocationAccuracy.high,
      );
      final LatLng latLng = LatLng(position.latitude, position.longitude);
      final String address = await _resolveAddress(latLng);
      return RegistroHoraLocationCapture(
        position: latLng,
        accuracyMeters: position.accuracy,
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
      final String address = AddressTextHelper.formatPlacemarkPart(
        street: place.street,
        subLocality: place.subLocality,
        locality: place.locality,
        administrativeArea: place.administrativeArea,
      );
      if (address.isNotEmpty) {
        return address;
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
