import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/atendimento_consulta_model.dart';

class AtendimentoConsultaExport {
  static String buildCsv({
    required String entityLabel,
    required List<AtendimentoConsultaItem> items,
  }) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('$entityLabel;Qtd;%;Principal');
    for (final AtendimentoConsultaItem item in items) {
      buffer.writeln(
        '${_escape(item.nome)};${item.qtd};${item.percent.toStringAsFixed(1)};${_escape(item.principal ?? '')}',
      );
    }
    return buffer.toString();
  }

  static Future<void> exportToClipboard({
    required String entityLabel,
    required List<AtendimentoConsultaItem> items,
  }) async {
    final String csv = buildCsv(entityLabel: entityLabel, items: items);
    await Clipboard.setData(ClipboardData(text: csv));
  }

  static Future<File> exportToFile({
    required String entityLabel,
    required List<AtendimentoConsultaItem> items,
  }) async {
    final Directory directory = await getTemporaryDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final File file = File('${directory.path}/consulta_$timestamp.csv');
    final String csv = buildCsv(entityLabel: entityLabel, items: items);
    await file.writeAsString(csv);
    return file;
  }

  static String _escape(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
