import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/atendimento_evolution_model.dart';
import 'atendimento_chart_colors.dart';

class ParticipationPieChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AtendimentoParticipationSlice> slices;

  const ParticipationPieChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.slices,
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
            if (slices.isEmpty)
              Text(
                'Sem dados no período.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: slices
                            .asMap()
                            .entries
                            .map(
                              (MapEntry<int, AtendimentoParticipationSlice>
                                  entry) {
                                final Color color =
                                    AtendimentoChartColors.colorAt(entry.key);
                                return PieChartSectionData(
                                  value: entry.value.qtd.toDouble(),
                                  color: color,
                                  radius: 42,
                                  title: '${entry.value.percent.toStringAsFixed(0)}%',
                                  titleStyle: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: slices
                          .asMap()
                          .entries
                          .map(
                            (MapEntry<int, AtendimentoParticipationSlice>
                                entry) {
                              final Color color =
                                  AtendimentoChartColors.colorAt(entry.key);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        entry.value.nome,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${entry.value.percent.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
