import 'dart:math' as math;

import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../hospital/models/hospital_model.dart';
import '../models/atendimento_mapa_model.dart';

class HospitalLocationResolver {
  static const LatLng defaultCenter = LatLng(-3.7504, -38.5017);
  static const double _maxDistanceFromAnchorKm = 80;

  final Map<int, Hospital> hospitalsById;
  LatLng anchor = defaultCenter;

  HospitalLocationResolver({required this.hospitalsById});

  Future<LatLng> resolve({
    required int? codcli,
    required String name,
    required int index,
    AtendimentoMapaHospital? mapaHospital,
  }) async {
    if (codcli != null) {
      final LatLng? cached = _resolvedCache[codcli];
      if (cached != null) {
        return cached;
      }
    }
    final Hospital? hospital =
        codcli != null ? hospitalsById[codcli] : null;
    final List<String> attempts = _buildAddressAttempts(
      hospital: hospital,
      mapaHospital: mapaHospital,
      name: name,
    );
    for (final String attempt in attempts) {
      try {
        final List<Location> locations = await locationFromAddress(
          attempt,
          localeIdentifier: 'pt_BR',
        );
        if (locations.isEmpty) {
          continue;
        }
        final LatLng candidate = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
        if (_isValidLocal(candidate)) {
          if (codcli != null) {
            _resolvedCache[codcli] = candidate;
          }
          return candidate;
        }
      } catch (_) {
        continue;
      }
    }
    final LatLng? cityLocation = await _resolveCityFallback(
      hospital: hospital,
      mapaHospital: mapaHospital,
      index: index,
    );
    if (cityLocation != null) {
      if (codcli != null) {
        _resolvedCache[codcli] = cityLocation;
      }
      return cityLocation;
    }
    return _hashFallbackLocation(codcli ?? name.hashCode, index);
  }

  LatLng resolveHome(List<LatLng> hospitalPoints) {
    if (hospitalPoints.isEmpty) {
      return anchor;
    }
    double latSum = 0;
    double lngSum = 0;
    for (final LatLng point in hospitalPoints) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return LatLng(
      latSum / hospitalPoints.length - 0.008,
      lngSum / hospitalPoints.length - 0.008,
    );
  }

  final Map<int, LatLng> _resolvedCache = <int, LatLng>{};

  List<String> _buildAddressAttempts({
    required Hospital? hospital,
    required AtendimentoMapaHospital? mapaHospital,
    required String name,
  }) {
    final List<String> attempts = <String>[];
    if (hospital != null) {
      final List<String> parts = <String>[
        hospital.address.trim(),
        hospital.numeroFormatado.trim(),
        hospital.bairroFormatado.trim(),
        hospital.cidadeFormatada.trim(),
        hospital.estadoFormatado.trim(),
        hospital.cepFormatado.trim(),
      ].where((String part) => part.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        attempts.add('${parts.join(', ')}, Brasil');
      }
      if (hospital.cepFormatado.trim().isNotEmpty) {
        attempts.add('${hospital.cepFormatado.trim()}, Brasil');
      }
      if (hospital.cidadeFormatada.trim().isNotEmpty) {
        attempts.add(
          '${hospital.cidadeFormatada.trim()}, '
          '${hospital.estadoFormatado.trim()}, Brasil',
        );
      }
    }
    if (mapaHospital != null) {
      final String mapaAddress = mapaHospital.fullAddress.trim();
      if (mapaAddress.isNotEmpty) {
        attempts.add('$mapaAddress, Brasil');
      }
    }
    if (name.trim().isNotEmpty) {
      attempts.add('${name.trim()}, Fortaleza, CE, Brasil');
    }
    return attempts;
  }

  Future<LatLng?> _resolveCityFallback({
    required Hospital? hospital,
    required AtendimentoMapaHospital? mapaHospital,
    required int index,
  }) async {
    final String city = hospital?.cidadeFormatada.trim() ??
        mapaHospital?.cidade?.trim() ??
        'Fortaleza';
    final String state = hospital?.estadoFormatado.trim() ??
        mapaHospital?.estado?.trim() ??
        'CE';
    final String query = '$city, $state, Brasil';
    try {
      final List<Location> locations = await locationFromAddress(
        query,
        localeIdentifier: 'pt_BR',
      );
      if (locations.isEmpty) {
        return null;
      }
      final Location base = locations.first;
      final double offset = index * 0.004;
      return LatLng(base.latitude + offset, base.longitude + offset);
    } catch (_) {
      return null;
    }
  }

  LatLng _hashFallbackLocation(int seed, int index) {
    final int hash = seed * 9973 + index * 37;
    final double latOffset = (hash % 1000) / 20000 + index * 0.004;
    final double lngOffset = ((hash ~/ 1000) % 1000) / 20000 + index * 0.004;
    return LatLng(
      anchor.latitude + latOffset,
      anchor.longitude + lngOffset,
    );
  }

  bool _isValidLocal(LatLng point) {
    return _distanceKm(anchor, point) <= _maxDistanceFromAnchorKm;
  }

  static double _distanceKm(LatLng from, LatLng to) {
    const double earthRadiusKm = 6371;
    final double lat1 = from.latitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double dLat = (to.latitude - from.latitude) * math.pi / 180;
    final double dLng = (to.longitude - from.longitude) * math.pi / 180;
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }
}
