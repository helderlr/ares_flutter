import 'atendimento_consulta_model.dart';

class AtendimentoEvolutionSeries {
  final int? id;
  final String nome;
  final List<int> values;

  const AtendimentoEvolutionSeries({
    required this.id,
    required this.nome,
    required this.values,
  });

  factory AtendimentoEvolutionSeries.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['values'] as List<dynamic>? ?? [];
    return AtendimentoEvolutionSeries(
      id: int.tryParse(json['id']?.toString() ?? ''),
      nome: json['nome']?.toString() ?? '—',
      values: raw.map((dynamic value) => int.tryParse(value.toString()) ?? 0).toList(),
    );
  }
}

class AtendimentoEvolutionData {
  final AtendimentoConsultaGroupBy groupBy;
  final List<String> months;
  final List<AtendimentoEvolutionSeries> series;
  final List<int> totalMeses;

  const AtendimentoEvolutionData({
    required this.groupBy,
    required this.months,
    required this.series,
    required this.totalMeses,
  });

  factory AtendimentoEvolutionData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> monthsRaw = json['months'] as List<dynamic>? ?? [];
    final List<dynamic> seriesRaw = json['series'] as List<dynamic>? ?? [];
    final List<dynamic> totalRaw = json['totalMeses'] as List<dynamic>? ?? [];
    return AtendimentoEvolutionData(
      groupBy: AtendimentoConsultaGroupByLabels.fromApi(
        json['groupBy']?.toString(),
      ),
      months: monthsRaw.map((dynamic item) => item.toString()).toList(),
      series: seriesRaw
          .map(
            (dynamic item) => AtendimentoEvolutionSeries.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      totalMeses:
          totalRaw.map((dynamic item) => int.tryParse(item.toString()) ?? 0).toList(),
    );
  }
}

class AtendimentoParticipationSlice {
  final String nome;
  final int qtd;
  final double percent;

  const AtendimentoParticipationSlice({
    required this.nome,
    required this.qtd,
    required this.percent,
  });
}

List<AtendimentoParticipationSlice> buildParticipationSlices({
  required List<AtendimentoConsultaItem> items,
  required int total,
  int topN = 5,
}) {
  if (items.isEmpty || total <= 0) {
    return const <AtendimentoParticipationSlice>[];
  }
  final List<AtendimentoConsultaItem> top =
      items.take(topN).toList(growable: false);
  final int othersQtd = items.skip(topN).fold<int>(
        0,
        (int sum, AtendimentoConsultaItem item) => sum + item.qtd,
      );
  final List<AtendimentoParticipationSlice> slices = top
      .map(
        (AtendimentoConsultaItem item) => AtendimentoParticipationSlice(
          nome: item.nome,
          qtd: item.qtd,
          percent: item.percent,
        ),
      )
      .toList();
  if (othersQtd > 0) {
    slices.add(
      AtendimentoParticipationSlice(
        nome: 'Outros',
        qtd: othersQtd,
        percent: (othersQtd / total) * 100,
      ),
    );
  }
  return slices;
}

String formatChartMonthLabel(String monthKey) {
  final List<String> parts = monthKey.split('-');
  if (parts.length < 2) {
    return monthKey;
  }
  const List<String> names = <String>[
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  final int month = int.tryParse(parts[1]) ?? 0;
  if (month < 1 || month > 12) {
    return monthKey;
  }
  return names[month - 1];
}
