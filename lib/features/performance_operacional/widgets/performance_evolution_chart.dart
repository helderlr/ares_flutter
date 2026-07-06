import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_desempenho_model.dart';
import '../models/performance_evolution_model.dart';
import 'performance_chart_shell.dart';
import '../../atendimento/widgets/atendimento_chart_colors.dart';

class PerformanceEvolutionChart extends StatelessWidget {
  final List<PerformanceEvolutionPoint> points;
  final double growthPercent;
  final int averageScore;

  const PerformanceEvolutionChart({
    super.key,
    required this.points,
    required this.growthPercent,
    required this.averageScore,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    final int maxScore = points.map((PerformanceEvolutionPoint p) => p.score).reduce(
          (int a, int b) => a > b ? a : b,
        );
    return Column(
      children: <Widget>[
        PerformanceChartShell(
          title: 'Evolução do Score',
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: (maxScore * 1.15).ceilToDouble(),
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
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value != value.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          points[index].label,
                          style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: points.asMap().entries.map(
                      (MapEntry<int, PerformanceEvolutionPoint> entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.score.toDouble());
                      },
                    ).toList(),
                    isCurved: true,
                    color: AppColors.lightBlue,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.lightBlue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: <Widget>[
                      Text(
                        growthPercent >= 0 ? '+${growthPercent.toStringAsFixed(0)}%' : '${growthPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: growthPercent >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        'vs mês anterior',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '$averageScore',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightBlue,
                        ),
                      ),
                      Text(
                        'Média Score (3 meses)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PerformanceHeatmapWidget extends StatelessWidget {
  final List<PerformanceHeatmapCell> cells;

  const PerformanceHeatmapWidget({super.key, required this.cells});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (cells.isEmpty) {
      return const SizedBox.shrink();
    }
    final int maxCount = cells.map((PerformanceHeatmapCell c) => c.count).reduce(
          (int a, int b) => a > b ? a : b,
        );
    final Set<int> hours = cells.map((PerformanceHeatmapCell c) => c.hour).toSet();
    final List<int> sortedHours = hours.toList()..sort();
    const List<String> weekdays = <String>['Seg', 'Ter', 'Qua', 'Qui', 'Sex'];
    return PerformanceChartShell(
      title: 'Heatmap de atividade',
      subtitle: 'Hora x dia da semana',
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(width: 28),
              ...weekdays.map(
                (String day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...sortedHours.map((int hour) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$hour',
                      style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                    ),
                  ),
                  ...List<Widget>.generate(5, (int dayIndex) {
                    final int count = _resolveCellCount(cells, hour, dayIndex + 1);
                    final double intensity = maxCount > 0 ? count / maxCount : 0;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: 16,
                        decoration: BoxDecoration(
                          color: AtendimentoChartColors.colorAt(0).withOpacity(
                            0.15 + intensity * 0.85,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static int _resolveCellCount(
    List<PerformanceHeatmapCell> cells,
    int hour,
    int weekday,
  ) {
    for (final PerformanceHeatmapCell cell in cells) {
      if (cell.hour == hour && cell.weekday == weekday) {
        return cell.count;
      }
    }
    return 0;
  }
}
