import 'package:flutter/material.dart';

import '../../agendamento/models/agendamento_model.dart';

class CirurgiaDayDetailsSheet {
  static Future<void> show({
    required BuildContext context,
    required DateTime day,
    required List<AgendaCirurgia> surgeries,
    Color? markerColor,
  }) async {
    final List<AgendaCirurgia> sorted =
        List<AgendaCirurgia>.from(surgeries)
          ..sort((AgendaCirurgia a, AgendaCirurgia b) {
            return (a.horcir ?? '').compareTo(b.horcir ?? '');
          });
    final Map<int, List<AgendaCirurgia>> byHospital = <int, List<AgendaCirurgia>>{};
    for (final AgendaCirurgia item in sorted) {
      final int key = item.codcli ?? 0;
      byHospital.putIfAbsent(key, () => <AgendaCirurgia>[]).add(item);
    }
    final String dayLabel =
        '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      if (markerColor != null)
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: markerColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: markerColor.withOpacity(0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Text(
                          'Cirurgias — $dayLabel',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${sorted.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: sorted.isEmpty
                        ? const Center(child: Text('Nenhuma cirurgia neste dia.'))
                        : ListView.builder(
                            controller: controller,
                            itemCount: byHospital.length,
                            itemBuilder: (BuildContext context, int index) {
                              final List<AgendaCirurgia> items =
                                  byHospital.values.elementAt(index);
                              final AgendaCirurgia first = items.first;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      first.nomcli ?? 'Hospital não informado',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...items.map(
                                      (AgendaCirurgia surgery) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              _formatHour(surgery.horcir ?? ''),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              surgery.nompac ?? 'Paciente não informado',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                            Text(
                                              'Convênio: ${surgery.nomconv ?? '—'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(
                                              'Cirurgia: ${surgery.nomcirTipo ?? surgery.procir ?? surgery.nomcir ?? '—'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(
                                              'Médico: ${surgery.nommed ?? '—'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _formatHour(String horcir) {
    final String trimmed = horcir.trim();
    if (trimmed.length >= 5) {
      return trimmed.substring(0, 5);
    }
    return trimmed.isEmpty ? '—' : trimmed;
  }
}
