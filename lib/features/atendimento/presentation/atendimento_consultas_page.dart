import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/screen_capture_service.dart';
import '../../../core/widgets/share_format_sheet.dart';
import '../../login/services/auth_service.dart';
import '../models/atendimento_consulta_filters.dart';
import '../models/atendimento_consulta_model.dart';
import '../services/atendimento_analytics_service.dart';
import '../services/atendimento_consulta_export.dart';
import '../services/atendimento_share_service.dart';
import 'atendimento_consulta_filters_sheet.dart';

class AtendimentoConsultasPage extends StatefulWidget {
  const AtendimentoConsultasPage({super.key});

  @override
  State<AtendimentoConsultasPage> createState() =>
      _AtendimentoConsultasPageState();
}

class _AtendimentoConsultasPageState extends State<AtendimentoConsultasPage> {
  final AtendimentoAnalyticsService _service = AtendimentoAnalyticsService();
  final AtendimentoShareService _shareService = AtendimentoShareService();
  final GlobalKey _shareKey = GlobalKey();
  final GlobalKey _tableKey = GlobalKey();
  AtendimentoConsultaFilters _filters =
      AtendimentoConsultaFilters.currentMonth();
  AtendimentoConsultaData? _data;
  bool _isLoading = true;
  bool _showAllSummary = false;
  bool _isExporting = false;
  bool _isSharing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConsultas();
  }

  Future<void> _loadConsultas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final AtendimentoConsultaData data =
          await _service.fetchConsultas(_filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _isLoading = false;
        _showAllSummary = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openFilters() async {
    final bool isAdmin =
        (await AuthService.getUserPermissions()).isAdmin;
    final AtendimentoConsultaFilters? result =
        await showModalBottomSheet<AtendimentoConsultaFilters>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return AtendimentoConsultaFiltersSheet(
          initialFilters: _filters,
          isAdmin: isAdmin,
        );
      },
    );
    if (result == null) {
      return;
    }
    setState(() => _filters = result);
    await _loadConsultas();
  }

  Future<void> _exportExcel() async {
    final List<AtendimentoConsultaItem> items =
        _data?.items ?? const <AtendimentoConsultaItem>[];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há dados para exportar.')),
      );
      return;
    }
    setState(() => _isExporting = true);
    try {
      await AtendimentoConsultaExport.exportToClipboard(
        entityLabel: _entityColumnLabel(),
        items: items,
      );
      final file = await AtendimentoConsultaExport.exportToFile(
        entityLabel: _entityColumnLabel(),
        items: items,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CSV copiado! Arquivo: ${file.path.split(Platform.pathSeparator).last}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _toggleShowAll() {
    setState(() => _showAllSummary = !_showAllSummary);
    if (!_showAllSummary) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? tableContext = _tableKey.currentContext;
      if (tableContext != null) {
        Scrollable.ensureVisible(
          tableContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _groupLabel() {
    return 'Resumo por ${_filters.groupBy.label.toLowerCase()}';
  }

  String _entityColumnLabel() {
    return _filters.groupBy.label;
  }

  String get _periodLabel {
    return '${_formatDisplayDate(_filters.dateFrom)} — ${_formatDisplayDate(_filters.dateTo)}';
  }

  Future<void> _shareConsultas() async {
    final List<AtendimentoConsultaItem> items =
        _data?.items ?? const <AtendimentoConsultaItem>[];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há dados para compartilhar.')),
      );
      return;
    }
    final ShareFormat? format = await ShareFormatSheet.show(context);
    if (format == null || !mounted) {
      return;
    }
    setState(() => _isSharing = true);
    try {
      if (format == ShareFormat.image) {
        final Uint8List? bytes =
            await ScreenCaptureService.capturePng(_shareKey);
        if (bytes == null) {
          throw Exception('Não foi possível capturar a imagem.');
        }
        await ScreenCaptureService.sharePngBytes(
          bytes: bytes,
          fileName: 'consultas_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        final Uint8List pdf = await _shareService.buildConsultasPdf(
          title: _groupLabel(),
          periodLabel: _periodLabel,
          items: items,
        );
        await ScreenCaptureService.sharePdfFile(
          bytes: pdf,
          fileName: 'consultas_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<AtendimentoConsultaItem> allItems =
        _data?.items ?? const <AtendimentoConsultaItem>[];
    final List<AtendimentoConsultaItem> summaryItems = _showAllSummary
        ? allItems
        : allItems.take(3).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultas'),
        actions: [
          if (!_isLoading && _data != null)
            IconButton(
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              onPressed: _isSharing ? null : _shareConsultas,
              tooltip: 'Compartilhar',
            ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openFilters,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadConsultas,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: RepaintBoundary(
                      key: _shareKey,
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFilterSummary(),
                            const SizedBox(height: 16),
                            _buildSummaryHeader(allItems.length),
                            const SizedBox(height: 12),
                            ...summaryItems.map(_buildSummaryCard),
                            const SizedBox(height: 20),
                            _buildTableCard(allItems),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage ?? 'Erro ao carregar',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadConsultas,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSummary() {
    return OutlinedButton.icon(
      onPressed: _openFilters,
      icon: const Icon(Icons.tune),
      label: Text(
        'Agrupar: ${_filters.groupBy.label} • ${_formatDisplayDate(_filters.dateFrom)} - ${_formatDisplayDate(_filters.dateTo)}',
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(14),
      ),
    );
  }

  Widget _buildSummaryHeader(int totalItems) {
    final bool canExpand = totalItems > 3;
    return Row(
      children: [
        Expanded(
          child: Text(
            _groupLabel(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (canExpand)
          TextButton(
            onPressed: _toggleShowAll,
            child: Text(_showAllSummary ? 'Ver menos' : 'Ver todos'),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(AtendimentoConsultaItem item) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: AppColors.lightBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.nome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        _buildRankBadge(item.rank),
                      ],
                    ),
                    if (item.principal != null)
                      Text(
                        item.principal!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricColumn(
                    '${item.qtd}',
                    'cirurgias',
                    valueFontSize: 14,
                  ),
                ),
                VerticalDivider(color: Colors.grey.shade300),
                Expanded(
                  child: _buildMetricColumn(
                    '${item.percent.toStringAsFixed(1)}%',
                    'do total',
                    valueFontSize: 14,
                  ),
                ),
                VerticalDivider(color: Colors.grey.shade300),
                Expanded(
                  child: _buildMetricColumn(
                    item.principal ?? '—',
                    'principal',
                    valueFontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0B2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${rank}º',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricColumn(
    String value,
    String label, {
    double valueFontSize = 15,
  }) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: valueFontSize,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard(List<AtendimentoConsultaItem> items) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      key: _tableKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _isExporting ? null : _exportExcel,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(_isExporting ? 'Exportando...' : 'Exportar Excel'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  _entityColumnLabel(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(
                child: Text(
                  'Qtd',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(
                child: Text(
                  '%',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Principal',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Divider(),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Sem dados no período'),
            )
          else
            ...items.map(
              (AtendimentoConsultaItem item) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.nome,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${item.qtd}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${item.percent.toStringAsFixed(1)}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.principal ?? '—',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item != items.last)
                    Divider(color: Colors.grey.shade200, height: 1),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDisplayDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
