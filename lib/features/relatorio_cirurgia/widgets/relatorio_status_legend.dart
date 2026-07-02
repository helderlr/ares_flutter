import 'package:flutter/material.dart';
import '../models/relatorio_cirurgia_model.dart';

class RelatorioStatusLegend {
  static Color colorForStatus(RelatorioVisualStatus status) {
    switch (status) {
      case RelatorioVisualStatus.contaContaminado:
        return const Color(0xFFE53935);
      case RelatorioVisualStatus.comProblema:
        return const Color(0xFFFFC107);
      case RelatorioVisualStatus.semProblema:
        return const Color(0xFF43A047);
    }
  }

  static Color colorForRelatorio(RelatorioCirurgia item) {
    return colorForStatus(item.visualStatus);
  }

  static Widget buildBall(Color color, {double size = 22}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  static Widget buildBallForRelatorio(
    RelatorioCirurgia item, {
    double size = 22,
  }) {
    return buildBall(colorForRelatorio(item), size: size);
  }

  static void showLegendDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Legenda'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _legendItems
                  .map(
                    (RelatorioLegendItem item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: <Widget>[
                          buildBall(item.color, size: 24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  static const List<RelatorioLegendItem> _legendItems = <RelatorioLegendItem>[
    RelatorioLegendItem(
      color: Color(0xFFE53935),
      label: 'Rel Mat Contaminado',
    ),
    RelatorioLegendItem(
      color: Color(0xFF43A047),
      label: 'Rel Sem Problema',
    ),
    RelatorioLegendItem(
      color: Color(0xFFFFC107),
      label: 'Rel Com Problema',
    ),
  ];
}

class RelatorioLegendItem {
  final Color color;
  final String label;

  const RelatorioLegendItem({
    required this.color,
    required this.label,
  });
}
