import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/atendimento_evolution_model.dart';
import 'atendimento_chart_colors.dart';

class EvolutionLineChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> months;
  final List<AtendimentoEvolutionSeries> series;

  const EvolutionLineChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.months,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double maxY = _resolveMaxY();
    return _ChartShell(
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (double value) {
                    return FlLine(
                      color: scheme.outlineVariant.withOpacity(0.4),
                      strokeWidth: 1,
                    );
                  },
                ),
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
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.toInt();
                        if (index < 0 || index >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            formatChartMonthLabel(months[index]),
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: series
                    .asMap()
                    .entries
                    .map(
                      (MapEntry<int, AtendimentoEvolutionSeries> entry) {
                        final Color color =
                            AtendimentoChartColors.colorAt(entry.key);
                        return LineChartBarData(
                          spots: entry.value.values
                              .asMap()
                              .entries
                              .map(
                                (MapEntry<int, int> point) => FlSpot(
                                  point.key.toDouble(),
                                  point.value.toDouble(),
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        );
                      },
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: series
                .asMap()
                .entries
                .map(
                  (MapEntry<int, AtendimentoEvolutionSeries> entry) {
                    final Color color =
                        AtendimentoChartColors.colorAt(entry.key);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.value.nome,
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  double _resolveMaxY() {
    int maxValue = 0;
    for (final AtendimentoEvolutionSeries item in series) {
      for (final int value in item.values) {
        if (value > maxValue) {
          maxValue = value;
        }
      }
    }
    if (maxValue <= 0) {
      return 5;
    }
    return (maxValue * 1.2).ceilToDouble();
  }
}

class _ChartShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
