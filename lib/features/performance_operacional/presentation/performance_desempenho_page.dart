import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_desempenho_model.dart';
import '../services/performance_operacional_service.dart';
import '../utils/performance_formatters.dart';
import '../widgets/performance_bar_charts.dart';
import '../widgets/performance_evolution_chart.dart';
import '../widgets/performance_pie_charts.dart';
import '../widgets/performance_quick_actions.dart';
import '../widgets/performance_score_card.dart';

class PerformanceDesempenhoPage extends StatefulWidget {
  final DateTime referenceMonth;
  final int? codusu;
  final String? userName;

  const PerformanceDesempenhoPage({
    super.key,
    required this.referenceMonth,
    this.codusu,
    this.userName,
  });

  @override
  State<PerformanceDesempenhoPage> createState() =>
      _PerformanceDesempenhoPageState();
}

class _PerformanceDesempenhoPageState extends State<PerformanceDesempenhoPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  PerformanceDesempenhoData? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final PerformanceDesempenhoData data = await _service.fetchDesempenho(
        codusu: widget.codusu,
        referenceMonth: widget.referenceMonth,
      );
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

  @override
  Widget build(BuildContext context) {
    if (widget.userName != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.userName!),
          backgroundColor: AppColors.lightBlue,
          foregroundColor: Colors.white,
        ),
        body: _buildBody(),
      );
    }
    return _buildBody();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    final PerformanceDesempenhoData data = _data!;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (widget.userName == null) ...<Widget>[
            Text(
              data.nome,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
          ],
          PerformanceScoreCard(
            score: data.score,
            scorePercent: data.scorePercent,
            starCount: data.starCount,
            levelLabel: data.levelLabel,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: <Widget>[
              PerformanceMetricCard(
                label: 'Horas trabalhadas',
                value: PerformanceFormatters.formatHoursMinutes(data.totalHoursMinutes),
                icon: Icons.schedule,
              ),
              PerformanceMetricCard(
                label: 'Tempo médio online',
                value: PerformanceFormatters.formatHoursMinutes(data.averageOnlineMinutes),
                icon: Icons.timer_outlined,
              ),
              PerformanceMetricCard(
                label: 'Primeiro acesso',
                value: data.firstAccess,
                icon: Icons.login,
              ),
              PerformanceMetricCard(
                label: 'Último acesso',
                value: data.lastAccess,
                icon: Icons.logout,
              ),
              PerformanceMetricCard(
                label: 'Dias trabalhados',
                value: '${data.daysWorked}',
                icon: Icons.calendar_today,
              ),
              PerformanceMetricCard(
                label: 'Operações',
                value: PerformanceFormatters.formatNumber(data.totalOperations),
                icon: Icons.bolt,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: PerformanceMetricCard(
                  label: 'Ações/hora',
                  value: '${data.actionsPerHour}',
                  subtitle: 'Produtividade',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PerformanceMetricCard(
                  label: 'Eficiência',
                  value: PerformanceFormatters.formatPercent(data.efficiencyPercent),
                  subtitle: 'Tempo ativo x ações',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PerformanceMetricCard(
            label: 'Frequência',
            value: PerformanceFormatters.formatPercent(data.frequencyPercent),
            subtitle: '${data.daysWorked} dias ativos no mês',
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 12),
          PerformanceOperationSummaryList(operations: data.operations),
          const SizedBox(height: 12),
          PerformanceHourlyBarChart(data: data.hourlyActivities),
          const SizedBox(height: 12),
          PerformanceWeekdayBarChart(data: data.weekdayActivities),
          const SizedBox(height: 12),
          PerformanceOperationPieChart(operations: data.operations),
          const SizedBox(height: 12),
          PerformanceModulePieChart(modules: data.moduleUsage),
          const SizedBox(height: 12),
          PerformanceHeatmapWidget(cells: data.heatmap),
        ],
      ),
    );
  }
}
