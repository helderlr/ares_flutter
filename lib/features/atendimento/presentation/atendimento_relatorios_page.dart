import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/widgets/report_export_sheet.dart';
import '../../agendamento/models/agenda_list_filters.dart';
import '../../agendamento/models/agendamento_model.dart';
import '../../agendamento/services/agenda_relatorio_export_service.dart';
import '../../agendamento/services/agenda_relatorio_pdf_service.dart';
import '../../agendamento/services/agendamento_service_paginado.dart';
import '../../agendamento/services/empresa_report_service.dart';
import '../../agendamento/widgets/agenda_filter_dialog.dart';
import '../../login/models/user_model.dart';
import '../../login/services/auth_service.dart';

class AtendimentoRelatoriosPage extends StatefulWidget {
  const AtendimentoRelatoriosPage({super.key});

  @override
  State<AtendimentoRelatoriosPage> createState() =>
      _AtendimentoRelatoriosPageState();
}

class _AtendimentoRelatoriosPageState extends State<AtendimentoRelatoriosPage> {
  final AgendamentoServicePaginado _agendaService =
      AgendamentoServicePaginado();
  final EmpresaReportService _empresaService = EmpresaReportService();
  final AgendaRelatorioPdfService _pdfService = AgendaRelatorioPdfService();
  bool _isGenerating = false;

  Future<void> _openAgendaCirurgiaReport() async {
    final AgendaListFilters? filters = await AgendaFilterDialog.show(
      context,
      requireDateRange: true,
    );
    if (filters == null || !mounted) {
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final List<AgendaCirurgia> items = await _agendaService.fetchAllAgendamentos(
        filters: filters,
      );
      if (!mounted) {
        return;
      }
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum registro encontrado.')),
        );
        return;
      }
      final ReportExportAction? action =
          await ReportExportSheet.show(context);
      if (action == null || !mounted) {
        return;
      }
      final UserModel? user = await AuthService.getCurrentUser();
      final empresa = await _empresaService.fetchReportData();
      final Uint8List pdf = await _pdfService.buildAgendaCirurgiaPdf(
        items: items,
        filters: filters,
        empresa: empresa,
        usuario: user,
      );
      final String fileName =
          'agenda_cirurgia_${DateTime.now().millisecondsSinceEpoch}';
      switch (action) {
        case ReportExportAction.pdf:
          await AgendaRelatorioExportService.sharePdf(
            bytes: pdf,
            fileName: fileName,
          );
          break;
        case ReportExportAction.excel:
          await AgendaRelatorioExportService.shareExcel(items);
          break;
        case ReportExportAction.share:
          await AgendaRelatorioExportService.sharePdf(
            bytes: pdf,
            fileName: fileName,
          );
          break;
        case ReportExportAction.print:
          await AgendaRelatorioExportService.printPdf(pdf);
          break;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: _isGenerating
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Text('📅', style: TextStyle(fontSize: 28)),
                    title: const Text('Agenda cirurgia'),
                    subtitle: const Text(
                      'Relatório A4 — filtros da agenda, PDF, Excel, imprimir',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openAgendaCirurgiaReport,
                  ),
                ),
              ],
            ),
    );
  }
}
