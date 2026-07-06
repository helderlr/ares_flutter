import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../atendimento/widgets/atendimento_chart_colors.dart';
import '../models/performance_desempenho_model.dart';
import 'performance_chart_shell.dart';

class PerformanceHourlyBarChart extends StatelessWidget {
  final List<PerformanceHourlyActivity> data;

  const PerformanceHourlyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (data.isEmpty) {
      return Text('Sem dados.', style: TextStyle(color: scheme.onSurfaceVariant));
    }
    final int maxCount = data.map((PerformanceHourlyActivity e) => e.count).reduce(
          (int a, int b) => a > b ? a : b,
        );
    return PerformanceChartShell(
      title: 'Atividades por hora',
      subtitle: 'Quando trabalha mais',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: (maxCount * 1.2).ceilToDouble(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (double value) => FlLine(
                color: scheme.outlineVariant.withOpacity(0.3),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${data[index].hour}',
                        style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: data.asMap().entries.map(
              (MapEntry<int, PerformanceHourlyActivity> entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: <BarChartRodData>[
                    BarChartRodData(
                      toY: entry.value.count.toDouble(),
                      color: AtendimentoChartColors.colorAt(0),
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }
}

class PerformanceWeekdayBarChart extends StatelessWidget {
  final List<PerformanceWeekdayActivity> data;

  const PerformanceWeekdayBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (data.isEmpty) {
      return Text('Sem dados.', style: TextStyle(color: scheme.onSurfaceVariant));
    }
    final int maxCount = data.map((PerformanceWeekdayActivity e) => e.count).reduce(
          (int a, int b) => a > b ? a : b,
        );
    return PerformanceChartShell(
      title: 'Atividades por dia',
      subtitle: 'Distribuição semanal',
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            maxY: (maxCount * 1.2).ceilToDouble(),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      data[index].label,
                      style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                    );
                  },
                ),
              ),
            ),
            barGroups: data.asMap().entries.map(
              (MapEntry<int, PerformanceWeekdayActivity> entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: <BarChartRodData>[
                    BarChartRodData(
                      toY: entry.value.count.toDouble(),
                      color: AtendimentoChartColors.colorAt(1),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }
}
