import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_frequency_model.dart';
import '../services/performance_operacional_service.dart';
import '../widgets/performance_ranking_widgets.dart';

class PerformanceGestorPage extends StatefulWidget {
  final DateTime referenceMonth;

  const PerformanceGestorPage({
    super.key,
    required this.referenceMonth,
  });

  @override
  State<PerformanceGestorPage> createState() => _PerformanceGestorPageState();
}

class _PerformanceGestorPageState extends State<PerformanceGestorPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  PerformanceGestorData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final PerformanceGestorData data = await _service.fetchGestorDashboard(
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

  IconData _resolveKpiIcon(String icon) {
    switch (icon) {
      case 'users':
        return Icons.people_outline;
      case 'star':
        return Icons.star_outline;
      case 'clock':
        return Icons.schedule;
      case 'fire':
        return Icons.local_fire_department_outlined;
      case 'trophy':
        return Icons.emoji_events_outlined;
      case 'growth':
        return Icons.trending_up;
      default:
        return Icons.analytics_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Gestor'),
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
                    Text(
                      'Dashboard Geral',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: _data!.kpis.map((PerformanceGestorKpi kpi) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(_resolveKpiIcon(kpi.icon), color: AppColors.lightBlue),
                                const Spacer(),
                                Text(
                                  kpi.value,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  kpi.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ranking Geral',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (_data!.topRanking.length >= 3)
                      PerformanceRankingPodium(
                        topThree: _data!.topRanking.take(3).toList(),
                      ),
                    ..._data!.topRanking.skip(3).map(
                      (entry) => PerformanceRankingListTile(entry: entry),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
