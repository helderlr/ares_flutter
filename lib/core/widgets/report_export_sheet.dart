import 'package:flutter/material.dart';

enum ReportExportAction {
  pdf,
  excel,
  share,
  print,
}

class ReportExportSheet {
  static Future<ReportExportAction?> show(BuildContext context) {
    return showModalBottomSheet<ReportExportAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Exportar relatório',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Arquivo PDF'),
                onTap: () => Navigator.of(context).pop(ReportExportAction.pdf),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Arquivo Excel (CSV)'),
                onTap: () => Navigator.of(context).pop(ReportExportAction.excel),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Compartilhar PDF'),
                onTap: () => Navigator.of(context).pop(ReportExportAction.share),
              ),
              ListTile(
                leading: const Icon(Icons.print_outlined),
                title: const Text('Imprimir'),
                onTap: () => Navigator.of(context).pop(ReportExportAction.print),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
