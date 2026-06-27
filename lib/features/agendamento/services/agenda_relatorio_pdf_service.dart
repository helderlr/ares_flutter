import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../login/models/user_model.dart';
import '../models/agendamento_model.dart';
import '../models/agenda_list_filters.dart';
import '../models/empresa_report_model.dart';
import 'empresa_report_logo_decoder.dart';

class AgendaRelatorioPdfService {
  Future<Uint8List> buildAgendaCirurgiaPdf({
    required List<AgendaCirurgia> items,
    required AgendaListFilters filters,
    required EmpresaReportData empresa,
    required UserModel? usuario,
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
        : dateFmt.format(now);
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String userName = usuario?.nome ?? 'Usuário';
    final List<AgendaCirurgia> sorted = List<AgendaCirurgia>.from(items)
      ..sort((AgendaCirurgia a, AgendaCirurgia b) {
        final DateTime? da = a.datcir;
        final DateTime? db = b.datcir;
        if (da == null && db == null) {
          return a.nummov.compareTo(b.nummov);
        }
        if (da == null) {
          return 1;
        }
        if (db == null) {
          return -1;
        }
        final int cmp = da.compareTo(db);
        if (cmp != 0) {
          return cmp;
        }
        return (a.horcir ?? '').compareTo(b.horcir ?? '');
      });
    final Map<String, List<AgendaCirurgia>> byDate =
        <String, List<AgendaCirurgia>>{};
    for (final AgendaCirurgia item in sorted) {
      final String key = item.datcir != null
          ? dateFmt.format(item.datcir!)
          : 'Sem data';
      byDate.putIfAbsent(key, () => <AgendaCirurgia>[]).add(item);
    }
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        header: (pw.Context context) {
          return _buildHeader(
            empresa: empresa,
            now: now,
            pageNumber: context.pageNumber,
            userName: userName,
            periodFrom: periodFrom,
            periodTo: periodTo,
            dateFmt: dateFmt,
            timeFmt: timeFmt,
          );
        },
        footer: (pw.Context context) {
          return _buildFooter(
            empresa: empresa,
            packageVersion: packageInfo.version,
          );
        },
        build: (pw.Context context) {
          final List<pw.Widget> children = <pw.Widget>[];
          for (final MapEntry<String, List<AgendaCirurgia>> entry
              in byDate.entries) {
            children.add(
              pw.Container(
                width: double.infinity,
                color: PdfColors.blue100,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: pw.Text(
                  entry.key,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
            );
            children.add(_buildTableHeader());
            for (final AgendaCirurgia item in entry.value) {
              children.add(_buildDataRow(item));
              final String material = item.matcir?.trim() ?? '';
              if (material.isNotEmpty) {
                children.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
                    child: pw.Text(
                      material,
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
                );
              }
            }
            children.add(pw.SizedBox(height: 6));
          }
          if (children.isEmpty) {
            children.add(
              pw.Text(
                'Nenhum registro encontrado para os filtros selecionados.',
                style: const pw.TextStyle(fontSize: 10),
              ),
            );
          }
          return children;
        },
      ),
    );
    return document.save();
  }

  pw.Widget _buildHeader({
    required EmpresaReportData empresa,
    required DateTime now,
    required int pageNumber,
    required String userName,
    required String periodFrom,
    required String periodTo,
    required DateFormat dateFmt,
    required DateFormat timeFmt,
  }) {
    final Uint8List? logoBytes =
        EmpresaReportLogoDecoder.decodeLogomarcaBytes(empresa.logomarcaUrl);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Emissão: ${dateFmt.format(now)}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Página: $pageNumber',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Hora: ${timeFmt.format(now)}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Usuário: $userName',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (logoBytes != null)
                  pw.Container(
                    width: 72,
                    height: 36,
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Image(
                      pw.MemoryImage(logoBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                pw.SizedBox(
                  width: 140,
                  child: pw.Text(
                    empresa.displayNome,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                if (empresa.razaoSocial.trim().isNotEmpty &&
                    empresa.razaoSocial.trim() != empresa.displayNome)
                  pw.SizedBox(
                    width: 140,
                    child: pw.Text(
                      empresa.razaoSocial.trim(),
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Ordem: 02=Rel Mapa p/Data   Período de $periodFrom a $periodTo',
          style: const pw.TextStyle(fontSize: 8),
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Rel Agenda Cirurgia',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Legenda ● Agenda Cancelada',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.5),
      ],
    );
  }

  pw.Widget _buildFooter({
    required EmpresaReportData empresa,
    required String packageVersion,
  }) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5),
        pw.Text(
          empresa.footerLine1,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7),
        ),
        if (empresa.footerLine2.isNotEmpty)
          pw.Text(
            empresa.footerLine2,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7),
          ),
        pw.Text(
          'Ares - Domina Sistemas. Suporte: atendimento@dominatecnologia.com / (85) 98162-9113. Versão: $packageVersion',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7),
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader() {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey600),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: <pw.Widget>[
          _headerCell('Nummov', 0.07),
          _headerCell('HorCir', 0.07),
          _headerCell('Local Cirurgia', 0.14),
          _headerCell('Medico', 0.14),
          _headerCell('Convenio', 0.08),
          _headerCell('Tipo Cirurgia', 0.1),
          _headerCell('Paciente', 0.14),
          _headerCell('Vendedor', 0.1),
          _headerCell('Tipo', 0.04),
          _headerCell('Sit', 0.04),
          _headerCell('Sta', 0.04),
        ],
      ),
    );
  }

  pw.Widget _buildDataRow(AgendaCirurgia item) {
    final bool isCancelada = item.isAgendaCancelada;
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: const pw.Border(
          bottom: pw.BorderSide(width: 0.3, color: PdfColors.grey400),
        ),
        color: isCancelada ? PdfColors.grey300 : null,
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          _dataCell('${item.nummov}', 0.07),
          _dataCell(item.horcir ?? '', 0.07),
          _dataCell(item.nomcli ?? '', 0.14),
          _dataCell(item.nommed ?? '', 0.14),
          _dataCell(item.nomconv ?? '', 0.08),
          _dataCell(item.nomcirTipo ?? item.nomcir ?? '', 0.1),
          _dataCell(item.nompac ?? '', 0.14),
          _dataCell(item.nomven ?? '', 0.1),
          _dataCell(item.primrev ?? 'A', 0.04),
          _dataCell(item.situacaoDisplayCode, 0.04),
          _dataCell(isCancelada ? 'C' : 'A', 0.04),
        ],
      ),
    );
  }

  pw.Widget _headerCell(String text, double flex) {
    return pw.Expanded(
      flex: (flex * 100).round(),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _dataCell(String text, double flex) {
    return pw.Expanded(
      flex: (flex * 100).round(),
      child: pw.Text(
        text,
        maxLines: 2,
        style: const pw.TextStyle(fontSize: 7),
      ),
    );
  }
}
