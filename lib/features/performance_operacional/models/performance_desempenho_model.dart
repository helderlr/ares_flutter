class PerformanceOperationCount {
  final String operacao;
  final int count;
  final double percent;

  const PerformanceOperationCount({
    required this.operacao,
    required this.count,
    required this.percent,
  });

  factory PerformanceOperationCount.fromJson(Map<String, dynamic> json) {
    return PerformanceOperationCount(
      operacao: json['operacao']?.toString() ?? '',
      count: _parseInt(json['count'] ?? json['qtd']),
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

class PerformanceModuleUsage {
  final String modulo;
  final int count;
  final double percent;

  const PerformanceModuleUsage({
    required this.modulo,
    required this.count,
    required this.percent,
  });

  factory PerformanceModuleUsage.fromJson(Map<String, dynamic> json) {
    return PerformanceModuleUsage(
      modulo: json['modulo']?.toString() ?? json['tabela']?.toString() ?? '',
      count: _parseInt(json['count'] ?? json['qtd']),
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

class PerformanceHourlyActivity {
  final int hour;
  final int count;

  const PerformanceHourlyActivity({
    required this.hour,
    required this.count,
  });

  factory PerformanceHourlyActivity.fromJson(Map<String, dynamic> json) {
    return PerformanceHourlyActivity(
      hour: _parseInt(json['hour'] ?? json['hora']),
      count: _parseInt(json['count'] ?? json['qtd']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PerformanceWeekdayActivity {
  final int weekday;
  final String label;
  final int count;

  const PerformanceWeekdayActivity({
    required this.weekday,
    required this.label,
    required this.count,
  });

  factory PerformanceWeekdayActivity.fromJson(Map<String, dynamic> json) {
    return PerformanceWeekdayActivity(
      weekday: _parseInt(json['weekday']),
      label: json['label']?.toString() ?? '',
      count: _parseInt(json['count'] ?? json['qtd']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PerformanceHeatmapCell {
  final int weekday;
  final int hour;
  final int count;

  const PerformanceHeatmapCell({
    required this.weekday,
    required this.hour,
    required this.count,
  });

  factory PerformanceHeatmapCell.fromJson(Map<String, dynamic> json) {
    return PerformanceHeatmapCell(
      weekday: _parseInt(json['weekday']),
      hour: _parseInt(json['hour'] ?? json['hora']),
      count: _parseInt(json['count'] ?? json['qtd']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PerformanceDesempenhoData {
  final int codusu;
  final String nome;
  final int score;
  final int scorePercent;
  final int starCount;
  final String levelLabel;
  final int totalHoursMinutes;
  final int averageOnlineMinutes;
  final String firstAccess;
  final String lastAccess;
  final int daysWorked;
  final int totalOperations;
  final int actionsPerHour;
  final double efficiencyPercent;
  final double frequencyPercent;
  final List<PerformanceOperationCount> operations;
  final List<PerformanceHourlyActivity> hourlyActivities;
  final List<PerformanceWeekdayActivity> weekdayActivities;
  final List<PerformanceModuleUsage> moduleUsage;
  final List<PerformanceHeatmapCell> heatmap;

  const PerformanceDesempenhoData({
    required this.codusu,
    required this.nome,
    required this.score,
    required this.scorePercent,
    required this.starCount,
    required this.levelLabel,
    required this.totalHoursMinutes,
    required this.averageOnlineMinutes,
    required this.firstAccess,
    required this.lastAccess,
    required this.daysWorked,
    required this.totalOperations,
    required this.actionsPerHour,
    required this.efficiencyPercent,
    required this.frequencyPercent,
    required this.operations,
    required this.hourlyActivities,
    required this.weekdayActivities,
    required this.moduleUsage,
    required this.heatmap,
  });

  factory PerformanceDesempenhoData.fromJson(Map<String, dynamic> json) {
    return PerformanceDesempenhoData(
      codusu: _parseInt(json['codusu']),
      nome: json['nome']?.toString() ?? json['nomusu']?.toString() ?? '',
      score: _parseInt(json['score']),
      scorePercent: _parseInt(json['scorePercent']),
      starCount: _parseInt(json['starCount']),
      levelLabel: json['levelLabel']?.toString() ?? '',
      totalHoursMinutes: _parseInt(json['totalHoursMinutes']),
      averageOnlineMinutes: _parseInt(json['averageOnlineMinutes']),
      firstAccess: json['firstAccess']?.toString() ?? '',
      lastAccess: json['lastAccess']?.toString() ?? '',
      daysWorked: _parseInt(json['daysWorked']),
      totalOperations: _parseInt(json['totalOperations']),
      actionsPerHour: _parseInt(json['actionsPerHour']),
      efficiencyPercent: _parseDouble(json['efficiencyPercent']),
      frequencyPercent: _parseDouble(json['frequencyPercent']),
      operations: _parseOperations(json['operations']),
      hourlyActivities: _parseHourly(json['hourlyActivities']),
      weekdayActivities: _parseWeekday(json['weekdayActivities']),
      moduleUsage: _parseModules(json['moduleUsage']),
      heatmap: _parseHeatmap(json['heatmap']),
    );
  }

  static List<PerformanceOperationCount> _parseOperations(dynamic raw) {
    if (raw is! List<dynamic>) {
      return <PerformanceOperationCount>[];
    }
    return raw
        .map(
          (dynamic item) => PerformanceOperationCount.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static List<PerformanceHourlyActivity> _parseHourly(dynamic raw) {
    if (raw is! List<dynamic>) {
      return <PerformanceHourlyActivity>[];
    }
    return raw
        .map(
          (dynamic item) => PerformanceHourlyActivity.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static List<PerformanceWeekdayActivity> _parseWeekday(dynamic raw) {
    if (raw is! List<dynamic>) {
      return <PerformanceWeekdayActivity>[];
    }
    return raw
        .map(
          (dynamic item) => PerformanceWeekdayActivity.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static List<PerformanceModuleUsage> _parseModules(dynamic raw) {
    if (raw is! List<dynamic>) {
      return <PerformanceModuleUsage>[];
    }
    return raw
        .map(
          (dynamic item) => PerformanceModuleUsage.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static List<PerformanceHeatmapCell> _parseHeatmap(dynamic raw) {
    if (raw is! List<dynamic>) {
      return <PerformanceHeatmapCell>[];
    }
    return raw
        .map(
          (dynamic item) => PerformanceHeatmapCell.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
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
