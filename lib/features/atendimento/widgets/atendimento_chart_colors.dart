import 'package:flutter/material.dart';

class AtendimentoChartColors {
  static const List<Color> series = <Color>[
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFFFB8C00),
    Color(0xFF00ACC1),
    Color(0xFF6D4C41),
    Color(0xFF3949AB),
    Color(0xFFD81B60),
    Color(0xFF7CB342),
  ];

  static Color colorAt(int index) {
    return series[index % series.length];
  }
}
