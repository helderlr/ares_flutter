import 'package:flutter/material.dart';

import '../../agendamento/models/agendamento_model.dart';

class CirurgiaSurgeryDetailsTile extends StatelessWidget {
  final AgendaCirurgia surgery;
  final EdgeInsetsGeometry padding;

  const CirurgiaSurgeryDetailsTile({
    super.key,
    required this.surgery,
    this.padding = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _formatHour(surgery.horcir ?? ''),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            surgery.nompac ?? 'Paciente não informado',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Convênio: ${surgery.nomconv ?? '—'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            'Cirurgia: ${_surgeryTypeLabel(surgery)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          if ((surgery.nommed ?? '').isNotEmpty)
            Text(
              'Médico: ${surgery.nommed}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
        ],
      ),
    );
  }

  static String _formatHour(String horcir) {
    final String trimmed = horcir.trim();
    if (trimmed.length >= 5) {
      return trimmed.substring(0, 5);
    }
    return trimmed.isEmpty ? '—' : trimmed;
  }

  static String _surgeryTypeLabel(AgendaCirurgia surgery) {
    if ((surgery.nomcirTipo ?? '').isNotEmpty) {
      return surgery.nomcirTipo!;
    }
    if ((surgery.procir ?? '').isNotEmpty) {
      return surgery.procir!;
    }
    if ((surgery.nomcir ?? '').isNotEmpty) {
      return surgery.nomcir!;
    }
    return '—';
  }
}
