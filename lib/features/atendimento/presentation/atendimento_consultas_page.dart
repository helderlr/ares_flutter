import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/atendimento_consulta_filters.dart';
import '../models/atendimento_consulta_model.dart';
import '../services/atendimento_analytics_service.dart';
import 'atendimento_consulta_filters_sheet.dart';

class AtendimentoConsultasPage extends StatefulWidget {
  const AtendimentoConsultasPage({super.key});

  @override
  State<AtendimentoConsultasPage> createState() =>
      _AtendimentoConsultasPageState();
}

class _AtendimentoConsultasPageState extends State<AtendimentoConsultasPage> {
  final AtendimentoAnalyticsService _service = AtendimentoAnalyticsService();
  AtendimentoConsultaFilters _filters =
      AtendimentoConsultaFilters.currentMonth();
  AtendimentoConsultaData? _data;
  bool _isLoading = true;
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
    final AtendimentoConsultaFilters? result =
        await showModalBottomSheet<AtendimentoConsultaFilters>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return AtendimentoConsultaFiltersSheet(initialFilters: _filters);
      },
    );
    if (result == null) {
      return;
    }
    setState(() => _filters = result);
    await _loadConsultas();
  }

  String _groupLabel() {
    return 'Resumo por ${_filters.groupBy.label.toLowerCase()}';
  }

  String _entityColumnLabel() {
    return _filters.groupBy.label;
  }

  @override
  Widget build(BuildContext context) {
    final List<AtendimentoConsultaItem> topItems =
        (_data?.items ?? const <AtendimentoConsultaItem>[]).take(3).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        title: const Text('Consultas'),
        actions: [
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFilterSummary(),
                        const SizedBox(height: 16),
                        _buildSummaryHeader(),
                        const SizedBox(height: 12),
                        ...topItems.map(_buildSummaryCard),
                        const SizedBox(height: 20),
                        _buildTableCard(),
                      ],
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

  Widget _buildSummaryHeader() {
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
        TextButton(
          onPressed: () {},
          child: const Text('Ver todos'),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(AtendimentoConsultaItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildRankBadge(item.rank),
                        const Icon(Icons.chevron_right),
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
                  ),
                ),
                VerticalDivider(color: Colors.grey.shade300),
                Expanded(
                  child: _buildMetricColumn(
                    '${item.percent.toStringAsFixed(1)}%',
                    'do total',
                  ),
                ),
                VerticalDivider(color: Colors.grey.shade300),
                Expanded(
                  child: _buildMetricColumn(
                    item.principal ?? '—',
                    'principal',
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

  Widget _buildMetricColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
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

  Widget _buildTableCard() {
    final List<AtendimentoConsultaItem> items =
        _data?.items ?? const <AtendimentoConsultaItem>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tabela compacta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exportação Excel em desenvolvimento'),
                    ),
                  );
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exportar Excel'),
              ),
            ],
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
                          child: Text(item.nome),
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
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.principal ?? '—',
                            textAlign: TextAlign.end,
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
