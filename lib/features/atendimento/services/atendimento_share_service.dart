import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/atendimento_consulta_model.dart';
import '../models/atendimento_dashboard_model.dart';
import '../models/atendimento_evolution_model.dart';

class AtendimentoShareService {
  Future<Uint8List> buildDashboardPdf({
    required AtendimentoDashboardData data,
    required String periodLabel,
  }) async {
    final pw.Document document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(
              'Dashboard — $periodLabel',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Cirurgias: ${data.cirurgias}'),
            pw.Text('Hospitais: ${data.hospitais}'),
            pw.Text('Convênios: ${data.convenios}'),
            pw.Text('Médicos: ${data.medicos}'),
            pw.Text('Tipos cirurgia: ${data.tiposCirurgia}'),
            pw.Text(
              'Taxa aproveitamento: ${data.taxaAproveitamentoPercent.toStringAsFixed(0)}%',
            ),
            pw.SizedBox(height: 16),
            pw.Text('Top médicos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ..._rankingLines(data.topMedicos),
            pw.SizedBox(height: 8),
            pw.Text('Top hospitais', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ..._rankingLines(data.topHospitais),
            pw.SizedBox(height: 8),
            pw.Text('Top tipos cirurgia', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ..._rankingLines(data.topTiposCirurgia),
            pw.SizedBox(height: 8),
            pw.Text('Top convênios', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ..._rankingLines(data.topConvenios),
          ];
        },
      ),
    );
    return document.save();
  }

  Future<Uint8List> buildConsultasPdf({
    required String title,
    required String periodLabel,
    required List<AtendimentoConsultaItem> items,
  }) async {
    final pw.Document document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Período: $periodLabel'),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: <String>['Nome', 'Qtd', '%', 'Principal'],
              data: items
                  .map(
                    (AtendimentoConsultaItem item) => <String>[
                      item.nome,
                      '${item.qtd}',
                      '${item.percent.toStringAsFixed(1)}%',
                      item.principal ?? '—',
                    ],
                  )
                  .toList(),
            ),
          ];
        },
      ),
    );
    return document.save();
  }

  Future<Uint8List> buildGraficosPdf({
    required String title,
    required String periodLabel,
    required String chartLabel,
    required List<AtendimentoConsultaItem> rankingItems,
    AtendimentoEvolutionData? evolution,
  }) async {
    final pw.Document document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final List<pw.Widget> children = <pw.Widget>[
            pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Período: $periodLabel'),
            pw.Text('Gráfico: $chartLabel'),
            pw.SizedBox(height: 12),
          ];
          if (evolution != null && evolution.series.isNotEmpty) {
            children.add(pw.Text('Evolução mensal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
            for (final AtendimentoEvolutionSeries series in evolution.series) {
              children.add(pw.Text('${series.nome}: ${series.values.join(', ')}'));
            }
            children.add(pw.SizedBox(height: 8));
          }
          children.add(pw.Text('Ranking', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          children.addAll(
            _rankingLinesFromConsulta(rankingItems.take(10).toList()),
          );
          return children;
        },
      ),
    );
    return document.save();
  }

  List<pw.Widget> _rankingLines(List<AtendimentoRankingItem> items) {
    return items
        .map((AtendimentoRankingItem item) => pw.Text('${item.nome} — ${item.total}'))
        .toList();
  }

  List<pw.Widget> _rankingLinesFromConsulta(List<AtendimentoConsultaItem> items) {
    return items
        .map((AtendimentoConsultaItem item) => pw.Text('${item.nome} — ${item.qtd}'))
        .toList();
  }
}
