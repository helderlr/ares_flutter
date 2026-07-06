import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../atendimento/widgets/atendimento_chart_colors.dart';
import '../models/performance_desempenho_model.dart';

class PerformanceOperationPieChart extends StatelessWidget {
  final List<PerformanceOperationCount> operations;

  const PerformanceOperationPieChart({super.key, required this.operations});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (operations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Sem dados.', style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Tipos de operação',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: operations.asMap().entries.map(
                        (MapEntry<int, PerformanceOperationCount> entry) {
                          return PieChartSectionData(
                            value: entry.value.count.toDouble(),
                            color: AtendimentoChartColors.colorAt(entry.key),
                            radius: 40,
                            title: '${entry.value.percent.toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: operations.asMap().entries.map(
                      (MapEntry<int, PerformanceOperationCount> entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AtendimentoChartColors.colorAt(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.value.operacao,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              Text(
                                '${entry.value.count}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList(),
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

class PerformanceModulePieChart extends StatelessWidget {
  final List<PerformanceModuleUsage> modules;

  const PerformanceModulePieChart({super.key, required this.modules});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (modules.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Módulos mais utilizados',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Baseado na tabela de auditoria',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ...modules.asMap().entries.map(
              (MapEntry<int, PerformanceModuleUsage> entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(child: Text(entry.value.modulo, style: const TextStyle(fontSize: 11))),
                          Text(
                            '${entry.value.percent.toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value.percent / 100,
                          minHeight: 8,
                          backgroundColor: scheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AtendimentoChartColors.colorAt(entry.key),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PerformanceOperationSummaryList extends StatelessWidget {
  final List<PerformanceOperationCount> operations;

  const PerformanceOperationSummaryList({super.key, required this.operations});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Resumo do mês',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...operations.map((PerformanceOperationCount op) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(op.operacao, style: const TextStyle(fontSize: 12)),
                    ),
                    Text(
                      '${op.count}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${op.percent.toStringAsFixed(0)}%',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
