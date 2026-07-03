import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../relatorio_cirurgia/models/relatorio_cirurgia_model.dart';
import '../models/registro_hora_list_filters.dart';

class RegistroHoraListaPdfService {
  Future<Uint8List> buildListaPdf({
    required List<RelatorioCirurgia> items,
    required RegistroHoraListFilters filters,
    required String userName,
  }) async {
    final pw.Document document = pw.Document();
    final DateFormat dateFmt = DateFormat('dd/MM/yyyy');
    final DateFormat timeFmt = DateFormat('HH:mm:ss');
    final DateTime now = DateTime.now();
    final String periodFrom = filters.relatorioFilters.dateFrom != null
        ? dateFmt.format(filters.relatorioFilters.dateFrom!)
        : '—';
    final String periodTo = filters.relatorioFilters.dateTo != null
        ? dateFmt.format(filters.relatorioFilters.dateTo!)
        : periodFrom;
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(
              'Registro Hora Cirurgia',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Emissão: ${dateFmt.format(now)} ${timeFmt.format(now)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Usuário: $userName',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Período: $periodFrom a $periodTo',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 12),
            ...items.map(_buildListItem),
          ];
        },
      ),
    );
    return document.save();
  }

  pw.Widget _buildListItem(RelatorioCirurgia item) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            item.tipoCirurgiaDisplay,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.Text(
            'Data: ${item.dataCirurgiaDisplay}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'No rel: ${item.numrel ?? item.nummov}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Pac: ${item.pacienteName}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Início: ${item.horaInicioDisplay} | Fim: ${item.horaFimDisplay}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }
}
