import 'package:flutter/material.dart';
import '../models/performance_evolution_model.dart';
import '../services/performance_operacional_service.dart';
import '../widgets/performance_evolution_chart.dart';

class PerformanceEvolutionPage extends StatefulWidget {
  final DateTime referenceMonth;
  final int? codusu;

  const PerformanceEvolutionPage({
    super.key,
    required this.referenceMonth,
    this.codusu,
  });

  @override
  State<PerformanceEvolutionPage> createState() =>
      _PerformanceEvolutionPageState();
}

class _PerformanceEvolutionPageState extends State<PerformanceEvolutionPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  PerformanceEvolutionPeriod _period = PerformanceEvolutionPeriod.monthly;
  PerformanceEvolutionData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final PerformanceEvolutionData data = await _service.fetchEvolution(
        period: _period,
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
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  void _changePeriod(PerformanceEvolutionPeriod period) {
    setState(() => _period = period);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SegmentedButton<PerformanceEvolutionPeriod>(
            segments: <ButtonSegment<PerformanceEvolutionPeriod>>[
              ButtonSegment<PerformanceEvolutionPeriod>(
                value: PerformanceEvolutionPeriod.daily,
                label: Text(PerformanceEvolutionPeriod.daily.label),
              ),
              ButtonSegment<PerformanceEvolutionPeriod>(
                value: PerformanceEvolutionPeriod.weekly,
                label: Text(PerformanceEvolutionPeriod.weekly.label),
              ),
              ButtonSegment<PerformanceEvolutionPeriod>(
                value: PerformanceEvolutionPeriod.monthly,
                label: Text(PerformanceEvolutionPeriod.monthly.label),
              ),
            ],
            selected: <PerformanceEvolutionPeriod>{_period},
            onSelectionChanged: (Set<PerformanceEvolutionPeriod> selection) {
              _changePeriod(selection.first);
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      if (_data != null)
                        PerformanceEvolutionChart(
                          points: _data!.points,
                          growthPercent: _data!.growthPercent,
                          averageScore: _data!.averageScore,
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
