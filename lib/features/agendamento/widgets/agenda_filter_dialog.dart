import 'package:flutter/material.dart';

import '../../../core/widgets/protected_ui.dart';
import '../models/agenda_list_filters.dart';

class AgendaFilterDialog {
  static InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      isDense: true,
    );
  }

  static DateTime _clampDate(
    DateTime value,
    DateTime minDate,
    DateTime maxDate,
  ) {
    if (value.isBefore(minDate)) {
      return minDate;
    }
    if (value.isAfter(maxDate)) {
      return maxDate;
    }
    return value;
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static Future<AgendaListFilters?> show(
    BuildContext context, {
    AgendaListFilters? initial,
    bool requireDateRange = true,
  }) async {
    final TextEditingController pacienteController = TextEditingController(
      text: initial?.pacienteQuery ?? '',
    );
    final TextEditingController nummovController = TextEditingController(
      text: initial?.nummovQuery ?? '',
    );
    final TextEditingController medicoController = TextEditingController(
      text: initial?.medicoQuery ?? '',
    );
    final TextEditingController convenioController = TextEditingController(
      text: initial?.convenioQuery ?? '',
    );
    final TextEditingController hospitalController = TextEditingController(
      text: initial?.hospitalQuery ?? '',
    );
    final TextEditingController tipoCirurgiaController = TextEditingController(
      text: initial?.tipoCirurgiaQuery ?? '',
    );
    final TextEditingController instrumentadorController = TextEditingController(
      text: initial?.instrumentadorQuery ?? '',
    );
    final TextEditingController vendedorController = TextEditingController(
      text: initial?.vendedorQuery ?? '',
    );
    DateTime? dateFrom = initial?.dateFrom;
    DateTime? dateTo = initial?.dateTo;
    AgendaDateFilterField dateField =
        initial?.dateField ?? AgendaDateFilterField.dataCirurgia;
    AgendaSituacaoFilter situacao =
        initial?.situacaoAgenda ?? AgendaSituacaoFilter.todos;
    AgendaTriFilter agendaCancelada =
        initial?.agendaCancelada ?? AgendaTriFilter.todas;
    AgendaTriFilter agendaComPedido =
        initial?.agendaComPedido ?? AgendaTriFilter.todas;
    AgendaTriFilter agendaComRelatorio =
        initial?.agendaComRelatorio ?? AgendaTriFilter.todas;
    AgendaTriFilter agendaCopia = initial?.agendaCopia ?? AgendaTriFilter.todas;
    AgendaTipmarFilter tipoMarcacao =
        initial?.tipoMarcacao ?? AgendaTipmarFilter.todas;
    AgendaLadoFilter lado = initial?.lado ?? AgendaLadoFilter.todas;
    final DateTime maxDate = AgendaListFilters.maxAllowedSurgeryDate();
    final AgendaListFilters? result = await showProtectedDialog<AgendaListFilters>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            final DateTime pickerMinDate =
                dateField == AgendaDateFilterField.dataMovto
                    ? AgendaListFilters.minAllowedMovementDate()
                    : AgendaListFilters.minAllowedSurgeryDate();
            return AlertDialog(
              title: const Text('Filtros'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DropdownButtonFormField<AgendaDateFilterField>(
                      value: dateField,
                      decoration: _decoration('Tipo de data'),
                      items: const <DropdownMenuItem<AgendaDateFilterField>>[
                        DropdownMenuItem<AgendaDateFilterField>(
                          value: AgendaDateFilterField.dataCirurgia,
                          child: Text('Data Cirurgia'),
                        ),
                        DropdownMenuItem<AgendaDateFilterField>(
                          value: AgendaDateFilterField.dataMovto,
                          child: Text('Data Movto'),
                        ),
                      ],
                      onChanged: (AgendaDateFilterField? value) {
                        if (value == null) {
                          return;
                        }
                        setStateDialog(() => dateField = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Período:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final DateTime? picked = await showProtectedDatePicker(
                          context: context,
                          initialDate: _clampDate(
                            dateFrom ?? DateTime.now(),
                            pickerMinDate,
                            maxDate,
                          ),
                          firstDate: pickerMinDate,
                          lastDate: maxDate,
                        );
                        if (picked != null) {
                          setStateDialog(() => dateFrom = picked);
                        }
                      },
                      child: Text(
                        dateFrom != null
                            ? 'De: ${_formatDate(dateFrom!)}'
                            : 'Data início',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final DateTime? picked = await showProtectedDatePicker(
                          context: context,
                          initialDate: _clampDate(
                            dateTo ?? DateTime.now(),
                            pickerMinDate,
                            maxDate,
                          ),
                          firstDate: pickerMinDate,
                          lastDate: maxDate,
                        );
                        if (picked != null) {
                          setStateDialog(() => dateTo = picked);
                        }
                      },
                      child: Text(
                        dateTo != null
                            ? 'Até: ${_formatDate(dateTo!)}'
                            : 'Data fim',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pacienteController,
                      decoration: _decoration('Paciente'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nummovController,
                      decoration: _decoration('No Agenda'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: medicoController,
                      decoration: _decoration('Médico'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: convenioController,
                      decoration: _decoration('Convênio'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hospitalController,
                      decoration: _decoration('Hospital'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tipoCirurgiaController,
                      decoration: _decoration('Tipo de Cirurgia'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AgendaSituacaoFilter>(
                      value: situacao,
                      decoration: _decoration('Situação agenda'),
                      items: AgendaSituacaoFilter.values
                          .map(
                            (AgendaSituacaoFilter value) =>
                                DropdownMenuItem<AgendaSituacaoFilter>(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                      onChanged: (AgendaSituacaoFilter? value) {
                        if (value == null) {
                          return;
                        }
                        setStateDialog(() => situacao = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (requireDateRange && (dateFrom == null || dateTo == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Informe o período (data início e fim).'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      AgendaListFilters(
                        dateFrom: dateFrom,
                        dateTo: dateTo,
                        dateField: dateField,
                        pacienteQuery: _trimOrNull(pacienteController.text),
                        nummovQuery: _trimOrNull(nummovController.text),
                        medicoQuery: _trimOrNull(medicoController.text),
                        convenioQuery: _trimOrNull(convenioController.text),
                        hospitalQuery: _trimOrNull(hospitalController.text),
                        tipoCirurgiaQuery: _trimOrNull(tipoCirurgiaController.text),
                        instrumentadorQuery: _trimOrNull(instrumentadorController.text),
                        vendedorQuery: _trimOrNull(vendedorController.text),
                        agendaCancelada: agendaCancelada,
                        agendaComPedido: agendaComPedido,
                        agendaComRelatorio: agendaComRelatorio,
                        agendaCopia: agendaCopia,
                        tipoMarcacao: tipoMarcacao,
                        lado: lado,
                        situacaoAgenda: situacao,
                      ),
                    );
                  },
                  child: const Text('Gerar'),
                ),
              ],
            );
          },
        );
      },
    );
    pacienteController.dispose();
    nummovController.dispose();
    medicoController.dispose();
    convenioController.dispose();
    hospitalController.dispose();
    tipoCirurgiaController.dispose();
    instrumentadorController.dispose();
    vendedorController.dispose();
    return result;
  }

  static String? _trimOrNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
