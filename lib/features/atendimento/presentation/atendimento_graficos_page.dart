import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/screen_capture_service.dart';
import '../../../core/widgets/share_format_sheet.dart';
import '../../login/services/auth_service.dart';
import '../models/atendimento_consulta_filters.dart';
import '../models/atendimento_consulta_model.dart';
import '../models/atendimento_evolution_model.dart';
import '../services/atendimento_analytics_service.dart';
import '../services/atendimento_share_service.dart';
import '../widgets/evolution_line_chart_card.dart';
import '../widgets/participation_pie_chart_card.dart';
import '../widgets/ranking_bar_chart_card.dart';

enum AtendimentoChartType {
  evolution,
  ranking,
  participation,
}

extension AtendimentoChartTypeLabels on AtendimentoChartType {
  String get label {
    switch (this) {
      case AtendimentoChartType.evolution:
        return 'Evolução';
      case AtendimentoChartType.ranking:
        return 'Ranking';
      case AtendimentoChartType.participation:
        return 'Participação';
    }
  }

  IconData get icon {
    switch (this) {
      case AtendimentoChartType.evolution:
        return Icons.show_chart;
      case AtendimentoChartType.ranking:
        return Icons.leaderboard;
      case AtendimentoChartType.participation:
        return Icons.pie_chart_outline;
    }
  }
}

class AtendimentoGraficosPage extends StatefulWidget {
  const AtendimentoGraficosPage({super.key});

  @override
  State<AtendimentoGraficosPage> createState() =>
      _AtendimentoGraficosPageState();
}

class _AtendimentoGraficosPageState extends State<AtendimentoGraficosPage> {
  final AtendimentoAnalyticsService _service = AtendimentoAnalyticsService();
  final AtendimentoShareService _shareService = AtendimentoShareService();
  final GlobalKey _shareKey = GlobalKey();
  AtendimentoChartType _chartType = AtendimentoChartType.ranking;
  AtendimentoConsultaGroupBy _groupBy = AtendimentoConsultaGroupBy.medico;
  DateTime _referenceMonth = DateTime.now();
  bool _isAdmin = false;
  bool _isLoading = true;
  bool _isSharing = false;
  String? _consultasError;
  String? _evolutionError;
  AtendimentoEvolutionData? _evolution;
  AtendimentoConsultaData? _consultas;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadCharts();
  }

  Future<void> _loadPermissions() async {
    final permissions = await AuthService.getUserPermissions();
    if (!mounted) {
      return;
    }
    final DateTime now = DateTime.now();
    setState(() {
      _isAdmin = permissions.isAdmin;
      if (!permissions.isAdmin) {
        _referenceMonth = DateTime(now.year, now.month, 1);
      }
    });
  }

  Future<void> _loadCharts() async {
    setState(() {
      _isLoading = true;
      _consultasError = null;
      _evolutionError = null;
    });
    final AtendimentoConsultaFilters filters = AtendimentoConsultaFilters(
      dateFrom: DateTime(_referenceMonth.year, _referenceMonth.month, 1),
      dateTo: DateTime(_referenceMonth.year, _referenceMonth.month + 1, 0),
      groupBy: _groupBy,
    );
    try {
      final AtendimentoConsultaData consultas =
          await _service.fetchConsultas(filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _consultas = consultas;
        _consultasError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _consultas = null;
        _consultasError = _service.formatUserError(error);
      });
    }
    if (_chartType == AtendimentoChartType.evolution) {
      await _loadEvolution();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEvolution() async {
    setState(() => _evolutionError = null);
    try {
      final AtendimentoEvolutionData evolution = await _service.fetchEvolution(
        groupBy: _groupBy,
        referenceMonth: _referenceMonth,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _evolution = evolution;
        _evolutionError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _evolution = null;
        _evolutionError = _service.formatUserError(error);
      });
    }
  }

  Future<void> _onChartTypeChanged(AtendimentoChartType type) async {
    setState(() => _chartType = type);
    if (type != AtendimentoChartType.evolution) {
      return;
    }
    setState(() => _isLoading = true);
    await _loadEvolution();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMonth() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Apenas administradores podem consultar meses anteriores.',
          ),
        ),
      );
      return;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _referenceMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _referenceMonth = DateTime(picked.year, picked.month, 1);
      _evolution = null;
    });
    await _loadCharts();
  }

  String get _monthLabel {
    const List<String> months = <String>[
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${months[_referenceMonth.month - 1]} ${_referenceMonth.year}';
  }

  String get _dimensionLabel => _groupBy.label.toLowerCase();

  Future<void> _shareGraficos() async {
    final List<AtendimentoConsultaItem> items =
        _consultas?.items ?? const <AtendimentoConsultaItem>[];
    if (items.isEmpty && _chartType != AtendimentoChartType.evolution) {
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
          fileName: 'graficos_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        final Uint8List pdf = await _shareService.buildGraficosPdf(
          title: 'Gráficos — $_dimensionLabel',
          periodLabel: _monthLabel,
          chartLabel: _chartType.label,
          rankingItems: items,
          evolution: _evolution,
        );
        await ScreenCaptureService.sharePdfFile(
          bytes: pdf,
          fileName: 'graficos_${DateTime.now().millisecondsSinceEpoch}',
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
    final List<AtendimentoParticipationSlice> slices =
        buildParticipationSlices(
      items: _consultas?.items ?? const <AtendimentoConsultaItem>[],
      total: _consultas?.total ?? 0,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráficos'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _consultas != null)
            IconButton(
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share),
              onPressed: _isSharing ? null : _shareGraficos,
              tooltip: 'Compartilhar',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCharts,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            RepaintBoundary(
              key: _shareKey,
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFiltersCard(),
                    const SizedBox(height: 12),
                    _buildChartTypeSelector(),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      _buildSelectedChart(slices),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: AtendimentoChartType.values.map(
            (AtendimentoChartType type) {
              final bool isSelected = _chartType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      type.label,
                      style: TextStyle(fontSize: 12),
                    ),
                    selected: isSelected,
                    onSelected: _isLoading
                        ? null
                        : (_) => _onChartTypeChanged(type),
                    avatar: Icon(type.icon, size: 16),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  Widget _buildSelectedChart(List<AtendimentoParticipationSlice> slices) {
    switch (_chartType) {
      case AtendimentoChartType.evolution:
        if (_evolutionError != null) {
          return _buildErrorCard(_evolutionError!);
        }
        return EvolutionLineChartCard(
          title: 'Evolução mensal de cirurgias',
          subtitle: 'Top 5 $_dimensionLabel — últimos 6 meses',
          months: _evolution?.months ?? const <String>[],
          series: _evolution?.series ?? const <AtendimentoEvolutionSeries>[],
        );
      case AtendimentoChartType.ranking:
        if (_consultasError != null) {
          return _buildErrorCard(_consultasError!);
        }
        return RankingBarChartCard(
          title: 'Ranking de $_dimensionLabel',
          subtitle: 'Mês atual ($_monthLabel) — top 10',
          items: _consultas?.items ?? const <AtendimentoConsultaItem>[],
        );
      case AtendimentoChartType.participation:
        if (_consultasError != null) {
          return _buildErrorCard(_consultasError!);
        }
        return ParticipationPieChartCard(
          title: 'Participação dos $_dimensionLabel',
          subtitle: 'Mês atual ($_monthLabel) — top 5 + outros',
          slices: slices,
        );
    }
  }

  Widget _buildErrorCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, size: 40, color: Colors.orange),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadCharts,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<AtendimentoConsultaGroupBy>(
              value: _groupBy,
              decoration: const InputDecoration(
                labelText: 'Dimensão',
                isDense: true,
              ),
              items: AtendimentoConsultaGroupBy.values
                  .map(
                    (AtendimentoConsultaGroupBy value) =>
                        DropdownMenuItem<AtendimentoConsultaGroupBy>(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (AtendimentoConsultaGroupBy? value) async {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _groupBy = value;
                        _evolution = null;
                      });
                      await _loadCharts();
                    },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickMonth,
              icon: const Icon(Icons.calendar_month, size: 18),
              label: Text('Período: $_monthLabel'),
            ),
          ],
        ),
      ),
    );
  }
}
