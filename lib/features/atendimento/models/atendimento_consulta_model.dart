enum AtendimentoConsultaGroupBy {
  medico,
  hospital,
  convenio,
  tipoCirurgia,
  vendedor,
  instrumentador,
}

extension AtendimentoConsultaGroupByLabels on AtendimentoConsultaGroupBy {
  String get label {
    switch (this) {
      case AtendimentoConsultaGroupBy.medico:
        return 'Médico';
      case AtendimentoConsultaGroupBy.hospital:
        return 'Hospital';
      case AtendimentoConsultaGroupBy.convenio:
        return 'Convênio';
      case AtendimentoConsultaGroupBy.tipoCirurgia:
        return 'Tipo cirurgia';
      case AtendimentoConsultaGroupBy.vendedor:
        return 'Vendedor';
      case AtendimentoConsultaGroupBy.instrumentador:
        return 'Instrumentador';
    }
  }

  String get apiValue {
    switch (this) {
      case AtendimentoConsultaGroupBy.medico:
        return 'medico';
      case AtendimentoConsultaGroupBy.hospital:
        return 'hospital';
      case AtendimentoConsultaGroupBy.convenio:
        return 'convenio';
      case AtendimentoConsultaGroupBy.tipoCirurgia:
        return 'tipoCirurgia';
      case AtendimentoConsultaGroupBy.vendedor:
        return 'vendedor';
      case AtendimentoConsultaGroupBy.instrumentador:
        return 'instrumentador';
    }
  }

  static AtendimentoConsultaGroupBy fromApi(String? raw) {
    return AtendimentoConsultaGroupBy.values.firstWhere(
      (AtendimentoConsultaGroupBy value) => value.apiValue == raw,
      orElse: () => AtendimentoConsultaGroupBy.medico,
    );
  }
}

class AtendimentoConsultaItem {
  final int rank;
  final int? id;
  final String nome;
  final int qtd;
  final double percent;
  final String? principal;

  const AtendimentoConsultaItem({
    required this.rank,
    required this.id,
    required this.nome,
    required this.qtd,
    required this.percent,
    required this.principal,
  });

  factory AtendimentoConsultaItem.fromJson(Map<String, dynamic> json) {
    final dynamic idValue = json['id'];
    return AtendimentoConsultaItem(
      rank: int.tryParse(json['rank']?.toString() ?? '') ?? 0,
      id: idValue is int
          ? idValue
          : int.tryParse(idValue?.toString() ?? ''),
      nome: json['nome']?.toString() ?? '—',
      qtd: int.tryParse(json['qtd']?.toString() ?? '') ?? 0,
      percent: double.tryParse(json['percent']?.toString() ?? '') ?? 0,
      principal: json['principal']?.toString(),
    );
  }
}

class AtendimentoConsultaData {
  final AtendimentoConsultaGroupBy groupBy;
  final int total;
  final List<AtendimentoConsultaItem> items;

  const AtendimentoConsultaData({
    required this.groupBy,
    required this.total,
    required this.items,
  });

  factory AtendimentoConsultaData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['items'] as List<dynamic>? ?? [];
    return AtendimentoConsultaData(
      groupBy: AtendimentoConsultaGroupByLabels.fromApi(
        json['groupBy']?.toString(),
      ),
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      items: raw
          .map(
            (dynamic item) => AtendimentoConsultaItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
