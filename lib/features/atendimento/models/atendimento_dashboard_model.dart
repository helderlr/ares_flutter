class AtendimentoDashboardPeriod {
  final String dateFrom;
  final String dateTo;

  const AtendimentoDashboardPeriod({
    required this.dateFrom,
    required this.dateTo,
  });

  factory AtendimentoDashboardPeriod.fromJson(Map<String, dynamic> json) {
    return AtendimentoDashboardPeriod(
      dateFrom: json['dateFrom']?.toString() ?? '',
      dateTo: json['dateTo']?.toString() ?? '',
    );
  }
}

class AtendimentoChartMonth {
  final String mes;
  final int total;

  const AtendimentoChartMonth({
    required this.mes,
    required this.total,
  });

  factory AtendimentoChartMonth.fromJson(Map<String, dynamic> json) {
    return AtendimentoChartMonth(
      mes: json['mes']?.toString() ?? '',
      total: _parseInt(json['total']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtendimentoRankingItem {
  final int? id;
  final String nome;
  final int total;

  const AtendimentoRankingItem({
    required this.id,
    required this.nome,
    required this.total,
  });

  factory AtendimentoRankingItem.fromJson(
    Map<String, dynamic> json, {
    required String idKey,
  }) {
    final dynamic idValue = json[idKey] ?? json['id'];
    return AtendimentoRankingItem(
      id: idValue is int
          ? idValue
          : int.tryParse(idValue?.toString() ?? ''),
      nome: json['nome']?.toString() ?? '—',
      total: AtendimentoChartMonth._parseInt(json['total']),
    );
  }
}

class AtendimentoDashboardData {
  final AtendimentoDashboardPeriod period;
  final int cirurgias;
  final double? cirurgiasVariacaoPercent;
  final int hospitais;
  final int convenios;
  final double taxaRetornoPercent;
  final List<AtendimentoChartMonth> chartMeses;
  final List<AtendimentoRankingItem> topMedicos;
  final List<AtendimentoRankingItem> topHospitais;

  const AtendimentoDashboardData({
    required this.period,
    required this.cirurgias,
    required this.cirurgiasVariacaoPercent,
    required this.hospitais,
    required this.convenios,
    required this.taxaRetornoPercent,
    required this.chartMeses,
    required this.topMedicos,
    required this.topHospitais,
  });

  factory AtendimentoDashboardData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> chartRaw = json['chartMeses'] as List<dynamic>? ?? [];
    final List<dynamic> medRaw = json['topMedicos'] as List<dynamic>? ?? [];
    final List<dynamic> hospRaw = json['topHospitais'] as List<dynamic>? ?? [];
    return AtendimentoDashboardData(
      period: AtendimentoDashboardPeriod.fromJson(
        json['period'] as Map<String, dynamic>? ?? {},
      ),
      cirurgias: AtendimentoChartMonth._parseInt(json['cirurgias']),
      cirurgiasVariacaoPercent: json['cirurgiasVariacaoPercent'] == null
          ? null
          : double.tryParse(json['cirurgiasVariacaoPercent'].toString()),
      hospitais: AtendimentoChartMonth._parseInt(json['hospitais']),
      convenios: AtendimentoChartMonth._parseInt(json['convenios']),
      taxaRetornoPercent:
          double.tryParse(json['taxaRetornoPercent']?.toString() ?? '') ?? 0,
      chartMeses: chartRaw
          .map(
            (dynamic item) => AtendimentoChartMonth.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      topMedicos: medRaw
          .map(
            (dynamic item) => AtendimentoRankingItem.fromJson(
              item as Map<String, dynamic>,
              idKey: 'codmed',
            ),
          )
          .toList(),
      topHospitais: hospRaw
          .map(
            (dynamic item) => AtendimentoRankingItem.fromJson(
              item as Map<String, dynamic>,
              idKey: 'codcli',
            ),
          )
          .toList(),
    );
  }
}
