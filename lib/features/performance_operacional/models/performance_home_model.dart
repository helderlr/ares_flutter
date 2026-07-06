class PerformanceHomeData {
  final String userName;
  final int score;
  final int scorePercent;
  final int starCount;
  final String levelLabel;
  final int goalTarget;
  final int goalCurrent;
  final double goalPercent;
  final int hoursTodayMinutes;
  final int activitiesToday;
  final int rankingPosition;

  const PerformanceHomeData({
    required this.userName,
    required this.score,
    required this.scorePercent,
    required this.starCount,
    required this.levelLabel,
    required this.goalTarget,
    required this.goalCurrent,
    required this.goalPercent,
    required this.hoursTodayMinutes,
    required this.activitiesToday,
    required this.rankingPosition,
  });

  factory PerformanceHomeData.fromJson(Map<String, dynamic> json) {
    return PerformanceHomeData(
      userName: json['userName']?.toString() ?? '',
      score: _parseInt(json['score']),
      scorePercent: _parseInt(json['scorePercent']),
      starCount: _parseInt(json['starCount']),
      levelLabel: json['levelLabel']?.toString() ?? '',
      goalTarget: _parseInt(json['goalTarget']),
      goalCurrent: _parseInt(json['goalCurrent']),
      goalPercent: _parseDouble(json['goalPercent']),
      hoursTodayMinutes: _parseInt(json['hoursTodayMinutes']),
      activitiesToday: _parseInt(json['activitiesToday']),
      rankingPosition: _parseInt(json['rankingPosition']),
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
