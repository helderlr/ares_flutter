class PerformanceEvolutionPoint {
  final String label;
  final int score;

  const PerformanceEvolutionPoint({
    required this.label,
    required this.score,
  });

  factory PerformanceEvolutionPoint.fromJson(Map<String, dynamic> json) {
    return PerformanceEvolutionPoint(
      label: json['label']?.toString() ?? '',
      score: _parseInt(json['score']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

enum PerformanceEvolutionPeriod { daily, weekly, monthly }

extension PerformanceEvolutionPeriodApi on PerformanceEvolutionPeriod {
  String get apiValue {
    switch (this) {
      case PerformanceEvolutionPeriod.daily:
        return 'daily';
      case PerformanceEvolutionPeriod.weekly:
        return 'weekly';
      case PerformanceEvolutionPeriod.monthly:
        return 'monthly';
    }
  }

  String get label {
    switch (this) {
      case PerformanceEvolutionPeriod.daily:
        return 'Diário';
      case PerformanceEvolutionPeriod.weekly:
        return 'Semanal';
      case PerformanceEvolutionPeriod.monthly:
        return 'Mensal';
    }
  }
}

class PerformanceEvolutionData {
  final PerformanceEvolutionPeriod period;
  final List<PerformanceEvolutionPoint> points;
  final double growthPercent;
  final int averageScore;

  const PerformanceEvolutionData({
    required this.period,
    required this.points,
    required this.growthPercent,
    required this.averageScore,
  });

  factory PerformanceEvolutionData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPoints =
        json['points'] as List<dynamic>? ?? <dynamic>[];
    return PerformanceEvolutionData(
      period: _parsePeriod(json['period']?.toString()),
      points: rawPoints
          .map(
            (dynamic item) => PerformanceEvolutionPoint.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      growthPercent: _parseDouble(json['growthPercent']),
      averageScore: _parseInt(json['averageScore']),
    );
  }

  static PerformanceEvolutionPeriod _parsePeriod(String? value) {
    switch (value) {
      case 'daily':
        return PerformanceEvolutionPeriod.daily;
      case 'weekly':
        return PerformanceEvolutionPeriod.weekly;
      default:
        return PerformanceEvolutionPeriod.monthly;
    }
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
