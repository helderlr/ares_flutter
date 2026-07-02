import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../agendamento/models/empresa_report_model.dart';
import '../../agendamento/services/empresa_report_logo_decoder.dart';
import '../../login/models/user_model.dart';
import '../models/relatorio_cirurgia_model.dart';
import '../models/relatorio_list_filters.dart';
import '../utils/relatorio_field_labels.dart';

class RelatorioCirurgiaPdfService {
  Future<Uint8List> buildRelatorioCirurgiaPdf({
    required List<RelatorioCirurgia> items,
    required RelatorioListFilters filters,
    required EmpresaReportData empresa,
    required UserModel? usuario,
  }) async {
    final pw.Document document = pw.Document();
    final DateFormat dateFmt = DateFormat('dd/MM/yyyy');
    final DateFormat timeFmt = DateFormat('HH:mm:ss');
    final DateTime now = DateTime.now();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String userName = usuario?.nome ?? 'Usuario';
    final String periodFrom = filters.dateFrom != null
        ? dateFmt.format(filters.dateFrom!)
        : dateFmt.format(now);
    final String periodTo = filters.dateTo != null
        ? dateFmt.format(filters.dateTo!)
        : dateFmt.format(now);
    final List<RelatorioCirurgia> sorted = List<RelatorioCirurgia>.from(items)
      ..sort((RelatorioCirurgia a, RelatorioCirurgia b) {
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
        return a.nummov.compareTo(b.nummov);
      });
    for (final RelatorioCirurgia item in sorted) {
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          header: (pw.Context context) {
            return _buildHeader(
              empresa: empresa,
              item: item,
              now: now,
              pageNumber: context.pageNumber,
              userName: userName,
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
            return <pw.Widget>[
              _buildDataGrid(item),
              pw.SizedBox(height: 8),
              _buildAvaliacaoSection(item),
              pw.SizedBox(height: 8),
              _sectionBox('Observacao', item.historico ?? ''),
              pw.SizedBox(height: 6),
              _problemaSection(item),
              pw.SizedBox(height: 6),
              _sectionBox(
                'Resolucao do Problema',
                item.medidaTomadaEstoque ?? '',
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Periodo: $periodFrom a $periodTo',
                style: const pw.TextStyle(fontSize: 7),
              ),
            ];
          },
        ),
      );
    }
    if (sorted.isEmpty) {
      document.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Nenhum relatorio encontrado para os filtros selecionados.',
                style: const pw.TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      );
    }
    return document.save();
  }

  Future<Uint8List> buildSingleRelatorioPdf({
    required RelatorioCirurgia item,
    required EmpresaReportData empresa,
    required UserModel? usuario,
  }) async {
    final DateTime refDate = item.datcir ?? item.datmov ?? DateTime.now();
    return buildRelatorioCirurgiaPdf(
      items: <RelatorioCirurgia>[item],
      filters: RelatorioListFilters(
        dateFrom: refDate,
        dateTo: refDate,
      ),
      empresa: empresa,
      usuario: usuario,
    );
  }

  pw.Widget _buildHeader({
    required EmpresaReportData empresa,
    required RelatorioCirurgia item,
    required DateTime now,
    required int pageNumber,
    required String userName,
    required DateFormat dateFmt,
    required DateFormat timeFmt,
  }) {
    final Uint8List? logoBytes =
        EmpresaReportLogoDecoder.decodeLogomarcaBytes(empresa.logomarcaUrl);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(
                    'Emissao: ${dateFmt.format(now)}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Pagina: $pageNumber',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Hora: ${timeFmt.format(now)}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Usuario: $userName',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                children: <pw.Widget>[
                  pw.Text(
                    'Rel Cirurgia No: ${item.nummov}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: <pw.Widget>[
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
                  width: 120,
                  child: pw.Text(
                    empresa.displayNome,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
      children: <pw.Widget>[
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
          'Ares - Domina Sistemas. Suporte: atendimento@dominatecnologia.com / (85) 98162-9113. Versao: $packageVersion',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7),
        ),
      ],
    );
  }

  pw.Widget _buildDataGrid(RelatorioCirurgia item) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey600),
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
      },
      children: <pw.TableRow>[
        _gridRow('Local Cir', _codeName(item.codcli, item.cliNome)),
        _gridRow(
          'Cirurgia',
          '${_codeName(item.circod, item.tipoCirNome)}  Inicio: ${item.hrini ?? ''}  Fim: ${item.hrfin ?? ''}',
        ),
        _gridRow(
          'Cirurgiao',
          '${_codeName(item.codmed, item.medNome)}  Convenio: ${_codeName(item.codconv, item.convNome)}',
        ),
        _gridRow(
          'Paciente',
          '${_codeName(item.codpac, item.pacNome)}  Prontuario: ${item.nprontuario ?? ''}',
        ),
        _gridRow(
          'Instrumentador(a)',
          item.inshos ?? '',
          rightLabel: 'Circulante',
          rightValue: item.nomcir ?? '',
        ),
        _gridRow(
          'Inst Hospital',
          item.inshos ?? '',
          rightLabel: 'Circ Hospital',
          rightValue: item.cirhos ?? '',
        ),
        _gridRow(
          'Lado',
          RelatorioFieldLabels.ladoToDisplay(item.lado),
          rightLabel: 'Sexo',
          rightValue: RelatorioFieldLabels.sexoToDisplay(item.sexo),
          extraRight: 'Tipo: ${RelatorioFieldLabels.displayPriRevForPdf(item.priRev)}  No Req: ${item.numreq ?? ''}',
        ),
        _gridRow(
          'Data Cir',
          item.dataCirurgiaDisplay,
          rightLabel: 'Data Mov',
          rightValue: item.dataEmissaoDisplay,
          extraRight:
              'No Agenda: ${item.nagecir ?? ''}  Urgencia: ${RelatorioFieldLabels.displaySnForPdf(item.urgencia)}',
        ),
      ],
    );
  }

  pw.TableRow _gridRow(
    String label,
    String value, {
    String? rightLabel,
    String? rightValue,
    String extraRight = '',
  }) {
    final String left = '$label: $value';
    final String right = rightLabel == null
        ? extraRight
        : '$rightLabel: ${rightValue ?? ''}${extraRight.isNotEmpty ? '  $extraRight' : ''}';
    return pw.TableRow(
      children: <pw.Widget>[
        pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(left, style: const pw.TextStyle(fontSize: 7)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(right, style: const pw.TextStyle(fontSize: 7)),
        ),
      ],
    );
  }

  String _codeName(int? code, String? name) {
    final String nome = (name ?? '').trim();
    if (code != null && nome.isNotEmpty) {
      return '$code $nome';
    }
    if (nome.isNotEmpty) {
      return nome;
    }
    if (code != null) {
      return '$code';
    }
    return '';
  }

  pw.Widget _buildAvaliacaoSection(RelatorioCirurgia item) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.3, color: PdfColors.grey600),
      ),
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Text(
            'Avaliacao Cirurgiao',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                'Nivel satisfacao do Material (${item.satisfacaoMatCirurg ?? ' '})',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.Text(
                'Nivel satisfacao do Instrumentador (${item.satisfacaoInstCirurg ?? ' '})',
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Legenda: 1-Muito insatisfeito  2-Insatisfeito  3-Indiferente  4-Satisfeito  5-Muito satisfeito',
            style: const pw.TextStyle(fontSize: 6.5),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionBox(String title, String content) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.3, color: PdfColors.grey600),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Container(
            color: PdfColors.blue100,
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.Container(
            constraints: const pw.BoxConstraints(minHeight: 48),
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              content,
              style: const pw.TextStyle(fontSize: 7),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _problemaSection(RelatorioCirurgia item) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.3, color: PdfColors.grey600),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Container(
            color: PdfColors.blue100,
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Text(
              'Problema na Cirurgia',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      'MATERIAL/EQUIPAMENTO:',
                      style: pw.TextStyle(fontSize: 7, color: PdfColors.red),
                    ),
                    pw.Text(
                      'LOTE:',
                      style: pw.TextStyle(fontSize: 7, color: PdfColors.red),
                    ),
                    pw.Text(
                      'COR:',
                      style: pw.TextStyle(fontSize: 7, color: PdfColors.red),
                    ),
                    pw.Text(
                      'REFER:',
                      style: pw.TextStyle(fontSize: 7, color: PdfColors.red),
                    ),
                    pw.Text(
                      'DEFEITO APRESENTADO:',
                      style: pw.TextStyle(fontSize: 7, color: PdfColors.red),
                    ),
                  ],
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    item.problema ?? '',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
