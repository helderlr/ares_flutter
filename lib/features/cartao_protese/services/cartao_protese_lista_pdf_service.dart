import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cartao_protese_list_filters.dart';
import '../models/cartao_protese_model.dart';

class CartaoProteseListaPdfService {
  Future<Uint8List> buildListaPdf({
    required List<CartaoProtese> items,
    required CartaoProteseListFilters filters,
    required String userName,
  }) async {
    final pw.Document document = pw.Document();
    final DateFormat dateFmt = DateFormat('dd/MM/yyyy');
    final DateFormat timeFmt = DateFormat('HH:mm:ss');
    final DateTime now = DateTime.now();
    final String periodFrom = filters.dateFrom != null
        ? dateFmt.format(filters.dateFrom!)
        : '—';
    final String periodTo = filters.dateTo != null
        ? dateFmt.format(filters.dateTo!)
        : periodFrom;
    final List<CartaoProtese> sorted = List<CartaoProtese>.from(items)
      ..sort((CartaoProtese a, CartaoProtese b) {
        final DateTime dateA = a.datcir ?? DateTime(1900);
        final DateTime dateB = b.datcir ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(
              'Cartão Prótese',
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

  pw.Widget _buildListItem(CartaoProtese item) {
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
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.Text('No Cartão: ${item.nummov}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Cirurgia: ${item.tipoCirurgiaName}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Data: ${item.dataCirurgiaDisplay}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Médico: ${item.medicoName}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Hospital: ${item.hospitalName}', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
