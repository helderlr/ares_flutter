import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/agendamento_model.dart';

class AgendaRelatorioExportService {
  static String buildListaCsv(List<AgendaCirurgia> items) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
      'Paciente;No Agenda;Cirurgia;Data;Hora;Medico;Convenio;Hospital',
    );
    for (final AgendaCirurgia item in items) {
      buffer.writeln(
        '${_escape(item.pacienteName)};'
        '${item.nummov};'
        '${_escape(item.cirurgiaName)};'
        '${_escape(item.dataCirurgia)};'
        '${_escape(item.horaCirurgia)};'
        '${_escape(item.medicoName)};'
        '${_escape(item.convenioName)};'
        '${_escape(item.hospitalName)}',
      );
    }
    return buffer.toString();
  }

  static Future<void> shareListaPdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final Directory directory = await getTemporaryDirectory();
    final File file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      <XFile>[XFile(file.path, mimeType: 'application/pdf')],
      text: 'Lista Agenda',
    );
  }

  static Future<void> shareListaExcel(List<AgendaCirurgia> items) async {
    final Directory directory = await getTemporaryDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final File file = File('${directory.path}/agenda_lista_$timestamp.csv');
    await file.writeAsString(buildListaCsv(items));
    await Share.shareXFiles(
      <XFile>[XFile(file.path, mimeType: 'text/csv')],
      text: 'Lista Agenda (Excel)',
    );
  }

  static String buildCsv(List<AgendaCirurgia> items) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
      'Nummov;HorCir;Local Cirurgia;Medico;Convenio;Tipo Cirurgia;Paciente;Vendedor;Tipo;Sit;Sta;Material',
    );
    for (final AgendaCirurgia item in items) {
      buffer.writeln(
        '${item.nummov};'
        '${_escape(item.horcir ?? '')};'
        '${_escape(item.nomcli ?? '')};'
        '${_escape(item.nommed ?? '')};'
        '${_escape(item.nomconv ?? '')};'
        '${_escape(item.nomcirTipo ?? item.nomcir ?? '')};'
        '${_escape(item.nompac ?? '')};'
        '${_escape(item.nomven ?? '')};'
        '${_escape(item.tipmarDisplay)};'
        '${_escape(item.situacDisplay)};'
        '${_escape(item.statusAgendaDisplay)};'
        '${_escape(item.reportMaterialRaw ?? item.matcir ?? '')}',
      );
    }
    return buffer.toString();
  }

  static Future<File> saveCsvFile(List<AgendaCirurgia> items) async {
    final Directory directory = await getTemporaryDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final File file = File('${directory.path}/agenda_cirurgia_$timestamp.csv');
    await file.writeAsString(buildCsv(items));
    return file;
  }

  static Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final Directory directory = await getTemporaryDirectory();
    final File file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      <XFile>[XFile(file.path, mimeType: 'application/pdf')],
      text: 'Relatório Agenda Cirurgia',
    );
  }

  static Future<void> shareExcel(List<AgendaCirurgia> items) async {
    final File file = await saveCsvFile(items);
    await Share.shareXFiles(
      <XFile>[XFile(file.path, mimeType: 'text/csv')],
      text: 'Relatório Agenda Cirurgia (Excel)',
    );
  }

  static Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static String _escape(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
