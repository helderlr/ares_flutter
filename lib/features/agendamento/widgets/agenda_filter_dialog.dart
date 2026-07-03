import 'package:flutter/material.dart';

import '../../../core/widgets/entity_lookup_picker.dart';
import '../../../core/widgets/form_section_field.dart';
import '../../../core/widgets/protected_ui.dart';
import '../models/agenda_list_filters.dart';

class AgendaFilterDialog {
  static Future<void> _applyLookup({
    required BuildContext context,
    required Future<EntityLookupSelection?> Function() pick,
    required TextEditingController controller,
    required void Function(String? name) setName,
    required StateSetter setStateDialog,
  }) async {
    final EntityLookupSelection? selection = await pick();
    if (selection == null) {
      return;
    }
    setStateDialog(() {
      controller.text = selection.code;
      setName(selection.name);
    });
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
    String confirmButtonLabel = 'Aplicar',
    bool showClearButton = false,
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
    String? pacienteName;
    String? medicoName;
    String? convenioName;
    String? hospitalName;
    String? tipoCirurgiaName;
    String? instrumentadorName;
    String? vendedorName;
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
              title: const Text('Filtro Agenda Cirurgia'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      FormSectionDropdown<AgendaDateFilterField>(
                        label: 'Tipo de data',
                        value: dateField,
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
                          if (value != null) {
                            setStateDialog(() => dateField = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final DateTime? picked = await showProtectedDatePicker(
                            context: context,
                            initialDate: dateFrom ?? DateTime.now(),
                            firstDate: pickerMinDate,
                            lastDate: maxDate,
                          );
                          if (picked != null) {
                            setStateDialog(() => dateFrom = picked);
                          }
                        },
                        child: Text(
                          dateFrom != null
                              ? 'Data Inicio: ${_formatDate(dateFrom!)}'
                              : 'Data Inicio',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final DateTime? picked = await showProtectedDatePicker(
                            context: context,
                            initialDate: dateTo ?? DateTime.now(),
                            firstDate: pickerMinDate,
                            lastDate: maxDate,
                          );
                          if (picked != null) {
                            setStateDialog(() => dateTo = picked);
                          }
                        },
                        child: Text(
                          dateTo != null
                              ? 'Data Termino: ${_formatDate(dateTo!)}'
                              : 'Data Termino',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FormSectionField(
                        label: 'Paciente',
                        controller: pacienteController,
                        subtitle: pacienteName,
                        keyboardType: TextInputType.number,
                        onSearch: () => _applyLookup(
                          context: context,
                          pick: () => EntityLookupPicker.pickPaciente(context),
                          controller: pacienteController,
                          setName: (String? name) => pacienteName = name,
                          setStateDialog: setStateDialog,
                        ),
                      ),
                      FormSectionField(
                        label: 'No Agenda',
                        controller: nummovController,
                        keyboardType: TextInputType.number,
                      ),
                      FormSectionField(
                        label: 'Medico',
                        controller: medicoController,
                        subtitle: medicoName,
                        keyboardType: TextInputType.number,
                        onSearch: () => _applyLookup(
                          context: context,
                          pick: () => EntityLookupPicker.pickMedico(context),
                          controller: medicoController,
                          setName: (String? name) => medicoName = name,
                          setStateDialog: setStateDialog,
                        ),
                      ),
                      FormSectionField(
                        label: 'Convenio',
                        controller: convenioController,
                        subtitle: convenioName,
                        keyboardType: TextInputType.number,
                        onSearch: () => _applyLookup(
                          context: context,
                          pick: () => EntityLookupPicker.pickConvenio(context),
                          controller: convenioController,
                          setName: (String? name) => convenioName = name,
                          setStateDialog: setStateDialog,
                        ),
                      ),
                      FormSectionField(
                        label: 'Hospital',
                        controller: hospitalController,
                        subtitle: hospitalName,
                        keyboardType: TextInputType.number,
                        onSearch: () => _applyLookup(
                          context: context,
                          pick: () => EntityLookupPicker.pickHospital(context),
                          controller: hospitalController,
                          setName: (String? name) => hospitalName = name,
                          setStateDialog: setStateDialog,
                        ),
                      ),
                      FormSectionField(
                        label: 'Tipo Cirurgia',
                        controller: tipoCirurgiaController,
                        subtitle: tipoCirurgiaName,
                        keyboardType: TextInputType.number,
                        onSearch: () => _applyLookup(
                          context: context,
                          pick: () => EntityLookupPicker.pickTipoCirurgia(context),
                          controller: tipoCirurgiaController,
                          setName: (String? name) => tipoCirurgiaName = name,
                          setStateDialog: setStateDialog,
                        ),
                      ),
                      FormSectionField(
                        label: 'Instrumentador',
                        controller: instrumentadorController,
                        subtitle: instrumentadorName,
                        keyboardType: TextInputType.number,
                        onSearch: () => _applyLookup(
                          context: context,
                          pick: () => EntityLookupPicker.pickInstrumentador(context),
                          controller: instrumentadorController,
                          setName: (String? name) => instrumentadorName = name,
                          setStateDialog: setStateDialog,
                        ),
                      ),
                      FormSectionField(
                        label: 'Vendedor',
                        controller: vendedorController,
                        subtitle: vendedorName,
                        keyboardType: TextInputType.number,
                        onSearch: () => _applyLookup(
                          context: context,
                          pick: () => EntityLookupPicker.pickVendedor(context),
                          controller: vendedorController,
                          setName: (String? name) => vendedorName = name,
                          setStateDialog: setStateDialog,
                        ),
                      ),
                      FormSectionDropdown<AgendaTipmarFilter>(
                        label: 'Tipo Marcacao',
                        value: tipoMarcacao,
                        items: const <DropdownMenuItem<AgendaTipmarFilter>>[
                          DropdownMenuItem<AgendaTipmarFilter>(
                            value: AgendaTipmarFilter.todas,
                            child: Text('Todas'),
                          ),
                          DropdownMenuItem<AgendaTipmarFilter>(
                            value: AgendaTipmarFilter.app,
                            child: Text('A - App'),
                          ),
                          DropdownMenuItem<AgendaTipmarFilter>(
                            value: AgendaTipmarFilter.web,
                            child: Text('W - Web'),
                          ),
                          DropdownMenuItem<AgendaTipmarFilter>(
                            value: AgendaTipmarFilter.desktop,
                            child: Text('Vazio - Desktop'),
                          ),
                          DropdownMenuItem<AgendaTipmarFilter>(
                            value: AgendaTipmarFilter.googleAgenda,
                            child: Text('Google Agenda'),
                          ),
                        ],
                        onChanged: (AgendaTipmarFilter? value) {
                          if (value != null) {
                            setStateDialog(() => tipoMarcacao = value);
                          }
                        },
                      ),
                      FormSectionDropdown<AgendaTriFilter>(
                        label: 'Agenda Cancelada',
                        value: agendaCancelada,
                        items: const <DropdownMenuItem<AgendaTriFilter>>[
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.todas,
                            child: Text('Todas'),
                          ),
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.sim,
                            child: Text('Sim'),
                          ),
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.nao,
                            child: Text('Não'),
                          ),
                        ],
                        onChanged: (AgendaTriFilter? value) {
                          if (value != null) {
                            setStateDialog(() => agendaCancelada = value);
                          }
                        },
                      ),
                      FormSectionDropdown<AgendaTriFilter>(
                        label: 'Agenda com Pedido',
                        value: agendaComPedido,
                        items: const <DropdownMenuItem<AgendaTriFilter>>[
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.todas,
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.sim,
                            child: Text('Sim'),
                          ),
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.nao,
                            child: Text('Não'),
                          ),
                        ],
                        onChanged: (AgendaTriFilter? value) {
                          if (value != null) {
                            setStateDialog(() => agendaComPedido = value);
                          }
                        },
                      ),
                      FormSectionDropdown<AgendaTriFilter>(
                        label: 'Agenda com Relatorio',
                        value: agendaComRelatorio,
                        items: const <DropdownMenuItem<AgendaTriFilter>>[
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.todas,
                            child: Text('Todas'),
                          ),
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.sim,
                            child: Text('Sim'),
                          ),
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.nao,
                            child: Text('Não'),
                          ),
                        ],
                        onChanged: (AgendaTriFilter? value) {
                          if (value != null) {
                            setStateDialog(() => agendaComRelatorio = value);
                          }
                        },
                      ),
                      FormSectionDropdown<AgendaTriFilter>(
                        label: 'Agenda Copia',
                        value: agendaCopia,
                        items: const <DropdownMenuItem<AgendaTriFilter>>[
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.todas,
                            child: Text('Todas'),
                          ),
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.sim,
                            child: Text('Sim'),
                          ),
                          DropdownMenuItem<AgendaTriFilter>(
                            value: AgendaTriFilter.nao,
                            child: Text('Não'),
                          ),
                        ],
                        onChanged: (AgendaTriFilter? value) {
                          if (value != null) {
                            setStateDialog(() => agendaCopia = value);
                          }
                        },
                      ),
                      FormSectionDropdown<AgendaLadoFilter>(
                        label: 'Lado',
                        value: lado,
                        items: const <DropdownMenuItem<AgendaLadoFilter>>[
                          DropdownMenuItem<AgendaLadoFilter>(
                            value: AgendaLadoFilter.todas,
                            child: Text('Todas'),
                          ),
                          DropdownMenuItem<AgendaLadoFilter>(
                            value: AgendaLadoFilter.esquerdo,
                            child: Text('Esquerdo'),
                          ),
                          DropdownMenuItem<AgendaLadoFilter>(
                            value: AgendaLadoFilter.direito,
                            child: Text('Direito'),
                          ),
                          DropdownMenuItem<AgendaLadoFilter>(
                            value: AgendaLadoFilter.vazio,
                            child: Text('Vazio'),
                          ),
                        ],
                        onChanged: (AgendaLadoFilter? value) {
                          if (value != null) {
                            setStateDialog(() => lado = value);
                          }
                        },
                      ),
                      FormSectionDropdown<AgendaSituacaoFilter>(
                        label: 'Situacao agenda',
                        value: situacao,
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
                          if (value != null) {
                            setStateDialog(() => situacao = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                if (showClearButton)
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(const AgendaListFilters());
                    },
                    child: const Text('Limpar'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final bool hasAgendaNumber =
                        _trimOrNull(nummovController.text) != null;
                    if (requireDateRange &&
                        !hasAgendaNumber &&
                        (dateFrom == null || dateTo == null)) {
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
                  child: Text(confirmButtonLabel),
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
