import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteLegInfo {
  final String fromLabel;
  final String toLabel;
  final double distanceKm;
  final int durationMinutes;

  const RouteLegInfo({
    required this.fromLabel,
    required this.toLabel,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RouteStopInfo {
  final String label;
  final String? subtitle;
  final String? timeLabel;
  final LatLng location;
  final bool isHome;
  final int order;
  final int? markerIndex;

  const RouteStopInfo({
    required this.label,
    required this.location,
    required this.order,
    this.subtitle,
    this.timeLabel,
    this.isHome = false,
    this.markerIndex,
  });
}

class OptimizedRouteResult {
  final List<RouteStopInfo> stops;
  final List<RouteLegInfo> legs;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final double fuelCostBrl;
  final double chronologicalDistanceKm;
  final int chronologicalDurationMinutes;

  const OptimizedRouteResult({
    required this.stops,
    required this.legs,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.fuelCostBrl,
    required this.chronologicalDistanceKm,
    required this.chronologicalDurationMinutes,
  });

  double get savedDistanceKm =>
      math.max(0, chronologicalDistanceKm - totalDistanceKm);

  int get savedDurationMinutes =>
      math.max(0, chronologicalDurationMinutes - totalDurationMinutes);
}

class RouteHospitalInput {
  final int? codcli;
  final String name;
  final String? timeLabel;
  final LatLng location;

  const RouteHospitalInput({
    required this.codcli,
    required this.name,
    required this.location,
    this.timeLabel,
  });
}

class RouteOptimizationService {
  static const double _averageSpeedKmh = 40;
  static const double _fuelCostPerKm = 0.67;

  OptimizedRouteResult optimize({
    required LatLng homeLocation,
    required List<RouteHospitalInput> hospitals,
    List<RouteHospitalInput>? chronologicalOrder,
    String homeLabel = 'Local atual',
    String? homeSubtitle,
  }) {
    final List<RouteHospitalInput> uniqueHospitals =
        _uniqueByCodcli(hospitals);
    if (uniqueHospitals.isEmpty) {
      return const OptimizedRouteResult(
        stops: <RouteStopInfo>[],
        legs: <RouteLegInfo>[],
        totalDistanceKm: 0,
        totalDurationMinutes: 0,
        fuelCostBrl: 0,
        chronologicalDistanceKm: 0,
        chronologicalDurationMinutes: 0,
      );
    }
    final List<RouteHospitalInput> ordered =
        _chronologicalOrder(uniqueHospitals);
    final List<RouteStopInfo> stops = <RouteStopInfo>[
      RouteStopInfo(
        label: homeLabel,
        subtitle: homeSubtitle,
        location: homeLocation,
        order: 1,
        isHome: true,
      ),
      ...List<RouteStopInfo>.generate(ordered.length, (int index) {
        final RouteHospitalInput hospital = ordered[index];
        return RouteStopInfo(
          label: hospital.name,
          timeLabel: hospital.timeLabel,
          location: hospital.location,
          order: index + 2,
          markerIndex: index,
        );
      }),
    ];
    final List<RouteLegInfo> legs = <RouteLegInfo>[];
    double totalDistanceKm = 0;
    int totalDurationMinutes = 0;
    for (int index = 0; index < stops.length - 1; index++) {
      final RouteStopInfo from = stops[index];
      final RouteStopInfo to = stops[index + 1];
      final double distanceKm = _distanceKm(from.location, to.location);
      final int durationMinutes = _estimateMinutes(distanceKm);
      totalDistanceKm += distanceKm;
      totalDurationMinutes += durationMinutes;
      legs.add(
        RouteLegInfo(
          fromLabel: from.label,
          toLabel: to.label,
          distanceKm: distanceKm,
          durationMinutes: durationMinutes,
        ),
      );
    }
    final List<RouteHospitalInput> chrono =
        chronologicalOrder ?? uniqueHospitals;
    final double chronologicalDistanceKm =
        _chronologicalDistanceKm(homeLocation, chrono);
    final int chronologicalDurationMinutes =
        _estimateMinutes(chronologicalDistanceKm);
    return OptimizedRouteResult(
      stops: stops,
      legs: legs,
      totalDistanceKm: totalDistanceKm,
      totalDurationMinutes: totalDurationMinutes,
      fuelCostBrl: totalDistanceKm * _fuelCostPerKm,
      chronologicalDistanceKm: chronologicalDistanceKm,
      chronologicalDurationMinutes: chronologicalDurationMinutes,
    );
  }

  List<RouteHospitalInput> _uniqueByCodcli(List<RouteHospitalInput> items) {
    final Map<int, RouteHospitalInput> byCodcli = <int, RouteHospitalInput>{};
    for (final RouteHospitalInput item in items) {
      final int key = item.codcli ?? item.name.hashCode;
      final RouteHospitalInput? existing = byCodcli[key];
      if (existing == null) {
        byCodcli[key] = item;
        continue;
      }
      final String existingTime = existing.timeLabel ?? '99:99';
      final String currentTime = item.timeLabel ?? '99:99';
      if (currentTime.compareTo(existingTime) < 0) {
        byCodcli[key] = item;
      }
    }
    return byCodcli.values.toList()
      ..sort(
        (RouteHospitalInput a, RouteHospitalInput b) =>
            (a.timeLabel ?? '99:99').compareTo(b.timeLabel ?? '99:99'),
      );
  }

  List<RouteHospitalInput> _chronologicalOrder(
    List<RouteHospitalInput> hospitals,
  ) {
    final List<RouteHospitalInput> ordered =
        List<RouteHospitalInput>.from(hospitals)
          ..sort(
            (RouteHospitalInput a, RouteHospitalInput b) =>
                (a.timeLabel ?? '99:99').compareTo(b.timeLabel ?? '99:99'),
          );
    return ordered;
  }

  double _chronologicalDistanceKm(
    LatLng home,
    List<RouteHospitalInput> hospitals,
  ) {
    if (hospitals.isEmpty) {
      return 0;
    }
    double total = 0;
    LatLng current = home;
    for (final RouteHospitalInput hospital in hospitals) {
      total += _distanceKm(current, hospital.location);
      current = hospital.location;
    }
    return total;
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
    final double straightLine = earthRadiusKm * c;
    return straightLine * 1.25;
  }

  static int _estimateMinutes(double distanceKm) {
    if (distanceKm <= 0) {
      return 0;
    }
    return math.max(1, (distanceKm / _averageSpeedKmh * 60).round());
  }
}
