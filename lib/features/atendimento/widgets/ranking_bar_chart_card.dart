import 'package:flutter/material.dart';
import '../models/atendimento_consulta_model.dart';
import 'atendimento_chart_colors.dart';

class RankingBarChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AtendimentoConsultaItem> items;
  final int maxItems;

  const RankingBarChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    this.maxItems = 10,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<AtendimentoConsultaItem> visible =
        items.take(maxItems).toList(growable: false);
    final int maxQtd = visible.isEmpty
        ? 1
        : visible.map((AtendimentoConsultaItem item) => item.qtd).reduce(
              (int a, int b) => a > b ? a : b,
            );
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
            if (visible.isEmpty)
              Text(
                'Sem dados no período.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              )
            else
              ...visible.asMap().entries.map(
                (MapEntry<int, AtendimentoConsultaItem> entry) {
                  final Color color =
                      AtendimentoChartColors.colorAt(entry.key);
                  final double ratio = entry.value.qtd / maxQtd;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.value.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value.qtd}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 10,
                            backgroundColor: scheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
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
