class PerformanceTimelineEvent {
  final String hora;
  final String operacao;
  final String tabela;
  final String? histor;

  const PerformanceTimelineEvent({
    required this.hora,
    required this.operacao,
    required this.tabela,
    this.histor,
  });

  factory PerformanceTimelineEvent.fromJson(Map<String, dynamic> json) {
    return PerformanceTimelineEvent(
      hora: json['hora']?.toString() ?? '',
      operacao: json['operacao']?.toString() ?? '',
      tabela: json['tabela']?.toString() ?? '',
      histor: json['histor']?.toString(),
    );
  }

  String get displayAction {
    final String op = operacao.toLowerCase();
    if (op.contains('inclu')) {
      return 'Incluiu $tabela';
    }
    if (op.contains('alter')) {
      return 'Alterou $tabela';
    }
    if (op.contains('exclu')) {
      return 'Excluiu $tabela';
    }
    if (op.contains('consult')) {
      return 'Consultou $tabela';
    }
    if (op.contains('relat')) {
      return 'Emitiu relatório $tabela';
    }
    if (op.contains('fech')) {
      return 'Fechou $tabela';
    }
    return '$operacao $tabela';
  }
}

class PerformanceHorasEvent {
  final String hora;
  final String label;
  final String type;

  const PerformanceHorasEvent({
    required this.hora,
    required this.label,
    required this.type,
  });

  factory PerformanceHorasEvent.fromJson(Map<String, dynamic> json) {
    return PerformanceHorasEvent(
      hora: json['hora']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? 'access',
    );
  }
}

class PerformanceHorasData {
  final DateTime date;
  final List<PerformanceHorasEvent> events;
  final int totalMinutes;
  final int productiveMinutes;
  final int idleMinutes;

  const PerformanceHorasData({
    required this.date,
    required this.events,
    required this.totalMinutes,
    required this.productiveMinutes,
    required this.idleMinutes,
  });

  factory PerformanceHorasData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawEvents =
        json['events'] as List<dynamic>? ?? <dynamic>[];
    return PerformanceHorasData(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      events: rawEvents
          .map(
            (dynamic item) => PerformanceHorasEvent.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      totalMinutes: _parseInt(json['totalMinutes']),
      productiveMinutes: _parseInt(json['productiveMinutes']),
      idleMinutes: _parseInt(json['idleMinutes']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PerformanceAtividadesData {
  final List<PerformanceTimelineEvent> activities;

  const PerformanceAtividadesData({required this.activities});

  factory PerformanceAtividadesData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawList =
        json['activities'] as List<dynamic>? ?? <dynamic>[];
    return PerformanceAtividadesData(
      activities: rawList
          .map(
            (dynamic item) => PerformanceTimelineEvent.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
