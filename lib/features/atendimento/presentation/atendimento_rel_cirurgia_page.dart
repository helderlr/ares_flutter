import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
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
import '../widgets/agenda_cirurgia_report_item_tile.dart';

class AtendimentoRelCirurgiaPage extends StatefulWidget {
  const AtendimentoRelCirurgiaPage({super.key});

  @override
  State<AtendimentoRelCirurgiaPage> createState() =>
      _AtendimentoRelCirurgiaPageState();
}

class _AtendimentoRelCirurgiaPageState extends State<AtendimentoRelCirurgiaPage> {
  final AgendamentoServicePaginado _agendaService =
      AgendamentoServicePaginado();
  final EmpresaReportService _empresaService = EmpresaReportService();
  final AgendaRelatorioPdfService _pdfService = AgendaRelatorioPdfService();
  bool _isLoading = false;
  bool _isExporting = false;
  bool _filtersActive = false;
  String _userName = 'Usuário';
  List<AgendaCirurgia> _items = const <AgendaCirurgia>[];
  late AgendaListFilters _filters;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _filters = AgendaListFilters(
      dateFrom: DateTime(now.year, now.month, now.day),
      dateTo: DateTime(now.year, now.month, now.day),
      dateField: AgendaDateFilterField.dataCirurgia,
    );
    _loadUserName();
    _loadData();
  }

  Future<void> _loadUserName() async {
    final String? name = await AuthService.getUserName();
    if (!mounted) {
      return;
    }
    setState(() {
      _userName = name?.trim().isNotEmpty == true ? name!.trim() : 'Usuário';
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final List<AgendaCirurgia> items = await _agendaService.fetchAllAgendamentos(
        filters: _filters,
      );
      final List<AgendaCirurgia> enriched =
          await _agendaService.enrichAgendasForReport(items);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = enriched
          ..sort((AgendaCirurgia a, AgendaCirurgia b) {
            final int dateCompare = (a.datcir ?? DateTime(1900))
                .compareTo(b.datcir ?? DateTime(1900));
            if (dateCompare != 0) {
              return dateCompare;
            }
            return (a.horcir ?? '').compareTo(b.horcir ?? '');
          });
        _isLoading = false;
      });
      final int withMaterial =
          enriched.where((AgendaCirurgia item) => item.hasReportMaterialLines).length;
      if (mounted && enriched.isNotEmpty && withMaterial == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Materiais (matcir) nao retornaram da API para este periodo.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _openFilters() async {
    final AgendaListFilters? result = await AgendaFilterDialog.show(
      context,
      initial: _filters,
      requireDateRange: true,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _filters = result;
      _filtersActive = result.hasActiveFilters;
    });
    await _loadData();
  }

  Future<void> _exportReport() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum registro para exportar.')),
      );
      return;
    }
    final ReportExportAction? action = await ReportExportSheet.show(context);
    if (action == null || !mounted) {
      return;
    }
    setState(() => _isExporting = true);
    try {
      final UserModel? user = await AuthService.getCurrentUser();
      final empresa = await _empresaService.fetchReportData();
      final Uint8List pdf = await _pdfService.buildAgendaCirurgiaPdf(
        items: _items,
        filters: _filters,
        empresa: empresa,
        usuario: user,
      );
      final String fileName =
          'rel_agenda_cirurgia_${DateTime.now().millisecondsSinceEpoch}';
      switch (action) {
        case ReportExportAction.pdf:
        case ReportExportAction.share:
          await AgendaRelatorioExportService.sharePdf(
            bytes: pdf,
            fileName: fileName,
          );
          break;
        case ReportExportAction.excel:
          await AgendaRelatorioExportService.shareExcel(_items);
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
        setState(() => _isExporting = false);
      }
    }
  }

  String get _periodLabel {
    final DateFormat fmt = DateFormat('dd/MM/yyyy');
    final String from = _filters.dateFrom != null
        ? fmt.format(_filters.dateFrom!)
        : fmt.format(DateTime.now());
    final String to = _filters.dateTo != null
        ? fmt.format(_filters.dateTo!)
        : from;
    return 'Período de $from a $to';
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateFormat dateFmt = DateFormat('dd/MM/yyyy');
    final DateFormat timeFmt = DateFormat('HH:mm:ss');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rel Agenda Cirurgia'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            onPressed: _isLoading || _isExporting ? null : _exportReport,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            onPressed: _isLoading ? null : _openFilters,
            icon: Badge(
              isLabelVisible: _filtersActive,
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: _isLoading || _isExporting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Emissão: ${dateFmt.format(now)} • Hora: ${timeFmt.format(now)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        'Usuário: $_userName',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        'Ordem: 02=Rel Mapa p/Data   $_periodLabel',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              'Rel Agenda Cirurgia',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Agenda Cancelada',
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const AgendaCirurgiaReportHeaderRow(),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text('Nenhuma cirurgia encontrada.'))
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (BuildContext context, int index) {
                            return AgendaCirurgiaReportItemTile(
                              item: _items[index],
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
