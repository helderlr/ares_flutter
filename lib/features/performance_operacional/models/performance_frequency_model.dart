import 'performance_ranking_model.dart';

enum PerformanceFrequencyStatus {
  present,
  halfDay,
  absent,
  vacation,
  none,
}

extension PerformanceFrequencyStatusApi on PerformanceFrequencyStatus {
  String get apiValue {
    switch (this) {
      case PerformanceFrequencyStatus.present:
        return 'present';
      case PerformanceFrequencyStatus.halfDay:
        return 'half_day';
      case PerformanceFrequencyStatus.absent:
        return 'absent';
      case PerformanceFrequencyStatus.vacation:
        return 'vacation';
      case PerformanceFrequencyStatus.none:
        return 'none';
    }
  }

  static PerformanceFrequencyStatus fromApi(String? value) {
    switch (value) {
      case 'present':
        return PerformanceFrequencyStatus.present;
      case 'half_day':
        return PerformanceFrequencyStatus.halfDay;
      case 'absent':
        return PerformanceFrequencyStatus.absent;
      case 'vacation':
        return PerformanceFrequencyStatus.vacation;
      default:
        return PerformanceFrequencyStatus.none;
    }
  }
}

class PerformanceFrequencyDay {
  final DateTime date;
  final PerformanceFrequencyStatus status;

  const PerformanceFrequencyDay({
    required this.date,
    required this.status,
  });

  factory PerformanceFrequencyDay.fromJson(Map<String, dynamic> json) {
    return PerformanceFrequencyDay(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: PerformanceFrequencyStatusApi.fromApi(
        json['status']?.toString(),
      ),
    );
  }
}

class PerformanceFrequenciaData {
  final int year;
  final int month;
  final List<PerformanceFrequencyDay> days;
  final int presentDays;
  final int halfDays;
  final int absentDays;
  final int vacationDays;

  const PerformanceFrequenciaData({
    required this.year,
    required this.month,
    required this.days,
    required this.presentDays,
    required this.halfDays,
    required this.absentDays,
    required this.vacationDays,
  });

  factory PerformanceFrequenciaData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawDays =
        json['days'] as List<dynamic>? ?? <dynamic>[];
    return PerformanceFrequenciaData(
      year: _parseInt(json['year']),
      month: _parseInt(json['month']),
      days: rawDays
          .map(
            (dynamic item) => PerformanceFrequencyDay.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      presentDays: _parseInt(json['presentDays']),
      halfDays: _parseInt(json['halfDays']),
      absentDays: _parseInt(json['absentDays']),
      vacationDays: _parseInt(json['vacationDays']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PerformanceGestorKpi {
  final String label;
  final String value;
  final String icon;

  const PerformanceGestorKpi({
    required this.label,
    required this.value,
    required this.icon,
  });

  factory PerformanceGestorKpi.fromJson(Map<String, dynamic> json) {
    return PerformanceGestorKpi(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
    );
  }
}

class PerformanceGestorData {
  final List<PerformanceGestorKpi> kpis;
  final List<PerformanceRankingEntry> topRanking;
  final double growthPercent;

  const PerformanceGestorData({
    required this.kpis,
    required this.topRanking,
    required this.growthPercent,
  });

  factory PerformanceGestorData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawKpis =
        json['kpis'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawRanking =
        json['topRanking'] as List<dynamic>? ?? <dynamic>[];
    return PerformanceGestorData(
      kpis: rawKpis
          .map(
            (dynamic item) => PerformanceGestorKpi.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      topRanking: rawRanking
          .map(
            (dynamic item) => PerformanceRankingEntry.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      growthPercent: _parseDouble(json['growthPercent']),
    );
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
