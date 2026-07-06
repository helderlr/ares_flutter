import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_desempenho_model.dart';
import '../models/performance_metas_model.dart';
import '../services/performance_operacional_service.dart';
import '../widgets/performance_goal_card.dart';
import '../widgets/performance_pie_charts.dart';
import '../widgets/performance_score_card.dart';

class PerformanceMetasPage extends StatefulWidget {
  final DateTime referenceMonth;

  const PerformanceMetasPage({
    super.key,
    required this.referenceMonth,
  });

  @override
  State<PerformanceMetasPage> createState() => _PerformanceMetasPageState();
}

class _PerformanceMetasPageState extends State<PerformanceMetasPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  PerformanceMetasData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final PerformanceMetasData data = await _service.fetchMetas(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  if (_data != null) ...<Widget>[
                    PerformanceGoalProgressCard(
                      current: _data!.goalCurrent,
                      target: _data!.goalTarget,
                      percent: _data!.goalPercent,
                    ),
                    const SizedBox(height: 12),
                    PerformanceScoreCard(
                      score: _data!.score,
                      scorePercent: _data!.scorePercent,
                      starCount: _data!.starCount,
                      levelLabel: _resolveLevel(_data!.starCount),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.today, color: AppColors.lightBlue),
                        title: const Text('Média diária'),
                        trailing: Text(
                          '${_data!.dailyAverage} ops/dia',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PerformanceOperationSummaryList(
                      operations: _data!.operationsByType
                          .map(
                            (PerformanceMetasOperation op) => PerformanceOperationCount(
                              operacao: op.operacao,
                              count: op.count,
                              percent: op.percent,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _resolveLevel(int stars) {
    if (stars >= 5) {
      return 'Nível Ouro';
    }
    if (stars >= 4) {
      return 'Nível Prata';
    }
    if (stars >= 3) {
      return 'Nível Bronze';
    }
    return 'Em evolução';
  }
}
