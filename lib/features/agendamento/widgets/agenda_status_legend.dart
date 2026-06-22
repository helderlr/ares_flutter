import 'package:flutter/material.dart';
import '../models/agendamento_model.dart';

class AgendaStatusLegend {
  static Color colorForStatus(AgendaVisualStatus status) {
    switch (status) {
      case AgendaVisualStatus.cancelada:
        return const Color(0xFFE53935);
      case AgendaVisualStatus.materialSaiu:
        return const Color(0xFF43A047);
      case AgendaVisualStatus.remarcada:
        return const Color(0xFFFFC107);
      case AgendaVisualStatus.retornou:
        return const Color(0xFF1E88E5);
      case AgendaVisualStatus.emAberto:
        return const Color(0xFF9E9E9E);
    }
  }

  static Color colorForAgenda(AgendaCirurgia agenda) {
    return colorForStatus(agenda.visualStatus);
  }

  static Widget buildBall(Color color, {double size = 22}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  static Widget buildBallForAgenda(AgendaCirurgia agenda, {double size = 22}) {
    return buildBall(colorForAgenda(agenda), size: size);
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
                    (AgendaLegendItem item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  static const List<AgendaLegendItem> _legendItems = <AgendaLegendItem>[
    AgendaLegendItem(
      color: Color(0xFFE53935),
      label: 'Agenda Cancelada',
    ),
    AgendaLegendItem(
      color: Color(0xFF43A047),
      label: 'Agenda Material Saiu',
    ),
    AgendaLegendItem(
      color: Color(0xFFFFC107),
      label: 'Agenda Remarcada',
    ),
    AgendaLegendItem(
      color: Color(0xFF1E88E5),
      label: 'Agenda Retornou',
    ),
    AgendaLegendItem(
      color: Color(0xFF9E9E9E),
      label: 'Agenda Em Aberto',
    ),
  ];
}

class AgendaLegendItem {
  final Color color;
  final String label;

  const AgendaLegendItem({
    required this.color,
    required this.label,
  });
}
