import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/agendamento_model.dart';
import '../models/agenda_list_filters.dart';

class AgendaListaPdfService {
  Future<Uint8List> buildListaPdf({
    required List<AgendaCirurgia> items,
    required AgendaListFilters filters,
    required String userName,
  }) async {
    final pw.Document document = pw.Document();
    final DateFormat dateFmt = DateFormat('dd/MM/yyyy');
    final DateFormat timeFmt = DateFormat('HH:mm:ss');
    final DateTime now = DateTime.now();
    final String periodFrom = filters.dateFrom != null
        ? dateFmt.format(filters.dateFrom!)
        : dateFmt.format(now);
    final String periodTo = filters.dateTo != null
        ? dateFmt.format(filters.dateTo!)
        : periodFrom;
    final List<AgendaCirurgia> sorted = List<AgendaCirurgia>.from(items)
      ..sort((AgendaCirurgia a, AgendaCirurgia b) {
        final int dateCompare = (a.datcir ?? DateTime(1900))
            .compareTo(b.datcir ?? DateTime(1900));
        if (dateCompare != 0) {
          return dateCompare;
        }
        return (a.horcir ?? '').compareTo(b.horcir ?? '');
      });
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(
              'Agenda',
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
            ...sorted.map(_buildListItem),
          ];
        },
      ),
    );
    return document.save();
  }

  pw.Widget _buildListItem(AgendaCirurgia item) {
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
            item.pacienteName,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text('No Agenda: ${item.nummov}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Cirurgia: ${item.cirurgiaName}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            'Data: ${item.dataCirurgia} às ${item.horaCirurgia}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text('Médico: ${item.medicoName}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Convênio: ${item.convenioName}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            'Hospital: ${item.hospitalName}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }
}
