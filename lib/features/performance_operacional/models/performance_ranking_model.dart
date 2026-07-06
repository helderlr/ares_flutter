class PerformanceRankingEntry {
  final int position;
  final int codusu;
  final String nome;
  final int score;
  final int scorePercent;
  final int starCount;
  final String medalTier;
  final int totalPoints;

  const PerformanceRankingEntry({
    required this.position,
    required this.codusu,
    required this.nome,
    required this.score,
    required this.scorePercent,
    required this.starCount,
    required this.medalTier,
    required this.totalPoints,
  });

  factory PerformanceRankingEntry.fromJson(Map<String, dynamic> json) {
    return PerformanceRankingEntry(
      position: _parseInt(json['position']),
      codusu: _parseInt(json['codusu']),
      nome: json['nome']?.toString() ?? json['nomusu']?.toString() ?? '',
      score: _parseInt(json['score']),
      scorePercent: _parseInt(json['scorePercent']),
      starCount: _parseInt(json['starCount']),
      medalTier: json['medalTier']?.toString() ?? '',
      totalPoints: _parseInt(json['totalPoints']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PerformanceRankingData {
  final List<PerformanceRankingEntry> entries;
  final int totalUsers;

  const PerformanceRankingData({
    required this.entries,
    required this.totalUsers,
  });

  factory PerformanceRankingData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawList =
        json['entries'] as List<dynamic>? ?? json['ranking'] as List<dynamic>? ?? <dynamic>[];
    return PerformanceRankingData(
      entries: rawList
          .map(
            (dynamic item) => PerformanceRankingEntry.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      totalUsers: _parseInt(json['totalUsers']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
