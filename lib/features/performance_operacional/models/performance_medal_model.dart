class PerformanceMedal {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final DateTime? earnedAt;
  final bool isEarned;

  const PerformanceMedal({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.earnedAt,
    required this.isEarned,
  });

  factory PerformanceMedal.fromJson(Map<String, dynamic> json) {
    return PerformanceMedal(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '🏅',
      earnedAt: _parseDate(json['earnedAt']),
      isEarned: json['isEarned'] == true || json['earnedAt'] != null,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}

class PerformanceMedalhasData {
  final List<PerformanceMedal> medals;
  final int earnedCount;
  final int totalCount;

  const PerformanceMedalhasData({
    required this.medals,
    required this.earnedCount,
    required this.totalCount,
  });

  factory PerformanceMedalhasData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawList =
        json['medals'] as List<dynamic>? ?? <dynamic>[];
    return PerformanceMedalhasData(
      medals: rawList
          .map(
            (dynamic item) => PerformanceMedal.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      earnedCount: _parseInt(json['earnedCount']),
      totalCount: _parseInt(json['totalCount']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
