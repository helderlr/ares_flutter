import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerColors {
  static const Color homeMarkerColor = Color(0xFF1E88E5);

  static const List<double> markerHues = <double>[
    BitmapDescriptor.hueRed,
    BitmapDescriptor.hueAzure,
    BitmapDescriptor.hueGreen,
    BitmapDescriptor.hueOrange,
    BitmapDescriptor.hueViolet,
    BitmapDescriptor.hueYellow,
  ];

  static Color colorForIndex(int index) {
    final double hue = markerHues[index % markerHues.length];
    return HSVColor.fromAHSV(1, hue, 0.9, 0.95).toColor();
  }

  static BitmapDescriptor iconForIndex(int index) {
    return BitmapDescriptor.defaultMarkerWithHue(
      markerHues[index % markerHues.length],
    );
  }
}
