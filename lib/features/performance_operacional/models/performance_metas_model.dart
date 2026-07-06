class PerformanceMetasData {
  final int goalTarget;
  final int goalCurrent;
  final double goalPercent;
  final int score;
  final int scorePercent;
  final int starCount;
  final int dailyAverage;
  final List<PerformanceMetasOperation> operationsByType;

  const PerformanceMetasData({
    required this.goalTarget,
    required this.goalCurrent,
    required this.goalPercent,
    required this.score,
    required this.scorePercent,
    required this.starCount,
    required this.dailyAverage,
    required this.operationsByType,
  });

  factory PerformanceMetasData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawOps =
        json['operationsByType'] as List<dynamic>? ?? <dynamic>[];
    return PerformanceMetasData(
      goalTarget: _parseInt(json['goalTarget']),
      goalCurrent: _parseInt(json['goalCurrent']),
      goalPercent: _parseDouble(json['goalPercent']),
      score: _parseInt(json['score']),
      scorePercent: _parseInt(json['scorePercent']),
      starCount: _parseInt(json['starCount']),
      dailyAverage: _parseInt(json['dailyAverage']),
      operationsByType: rawOps
          .map(
            (dynamic item) => PerformanceMetasOperation.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
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

class PerformanceMetasOperation {
  final String operacao;
  final int count;
  final double percent;

  const PerformanceMetasOperation({
    required this.operacao,
    required this.count,
    required this.percent,
  });

  factory PerformanceMetasOperation.fromJson(Map<String, dynamic> json) {
    return PerformanceMetasOperation(
      operacao: json['operacao']?.toString() ?? '',
      count: _parseInt(json['count']),
      percent: _parseDouble(json['percent']),
    );
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
