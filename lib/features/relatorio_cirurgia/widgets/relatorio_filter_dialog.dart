import 'package:flutter/material.dart';
import '../../../core/widgets/entity_lookup_picker.dart';
import '../../../core/widgets/form_section_field.dart';
import '../../../core/widgets/protected_ui.dart';
import '../../agendamento/models/agenda_list_filters.dart';
import '../models/relatorio_list_filters.dart';

class RelatorioFilterDialog {
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

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

  static Widget _triDropdown({
    required String label,
    required AgendaTriFilter value,
    required ValueChanged<AgendaTriFilter> onChanged,
  }) {
    return FormSectionDropdown<AgendaTriFilter>(
      label: label,
      value: value,
      items: const <DropdownMenuItem<AgendaTriFilter>>[
        DropdownMenuItem<AgendaTriFilter>(
          value: AgendaTriFilter.todas,
          child: Text('T = Todos'),
        ),
        DropdownMenuItem<AgendaTriFilter>(
          value: AgendaTriFilter.sim,
          child: Text('S = Sim'),
        ),
        DropdownMenuItem<AgendaTriFilter>(
          value: AgendaTriFilter.nao,
          child: Text('N = Não'),
        ),
      ],
      onChanged: (AgendaTriFilter? selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }

  static Future<RelatorioListFilters?> show(
    BuildContext context, {
    RelatorioListFilters? initial,
    String title = 'Filtro Rel Cirurgia',
    List<Widget> Function(StateSetter setStateDialog)? prefixFields,
    VoidCallback? onClearExtra,
  }) async {
    final TextEditingController hospitalController = TextEditingController(
      text: initial?.hospitalQuery ?? '',
    );
    final TextEditingController medicoController = TextEditingController(
      text: initial?.medicoQuery ?? '',
    );
    final TextEditingController convenioController = TextEditingController(
      text: initial?.convenioQuery ?? '',
    );
    final TextEditingController pacienteController = TextEditingController(
      text: initial?.pacienteQuery ?? '',
    );
    final TextEditingController digitadoController = TextEditingController(
      text: initial?.digitadoPorQuery ?? '',
    );
    final TextEditingController numrelController = TextEditingController(
      text: initial?.numrelQuery ?? '',
    );
    final TextEditingController nagecirController = TextEditingController(
      text: initial?.nagecirQuery ?? '',
    );
    final TextEditingController codinsController = TextEditingController(
      text: initial?.codinsQuery ?? '',
    );
    final TextEditingController codcirController = TextEditingController(
      text: initial?.codcirQuery ?? '',
    );
    final TextEditingController produtoController = TextEditingController(
      text: initial?.codProdutoQuery ?? '',
    );
    final TextEditingController tipoController = TextEditingController(
      text: initial?.tipoQuery ?? '',
    );
    String? hospitalName;
    String? medicoName;
    String? convenioName;
    String? pacienteName;
    String? circulanteName;
    String? instrumentadorName;
    String? tipoCirurgiaName;
    DateTime? dateFrom = initial?.dateFrom;
    DateTime? dateTo = initial?.dateTo;
    RelatorioDateFilterField dateField =
        initial?.dateField ?? RelatorioDateFilterField.dataCirurgia;
    RelatorioLadoFilter lado = initial?.lado ?? RelatorioLadoFilter.todos;
    RelatorioSexoFilter sexo = initial?.sexo ?? RelatorioSexoFilter.todos;
    AgendaTriFilter darVisto = initial?.darVisto ?? AgendaTriFilter.todas;
    AgendaTriFilter relProblema = initial?.relProblema ?? AgendaTriFilter.todas;
    AgendaTriFilter relComAgenda = initial?.relComAgenda ?? AgendaTriFilter.todas;
    AgendaTriFilter relComPedido = initial?.relComPedido ?? AgendaTriFilter.todas;
    final DateTime minDate = RelatorioListFilters.minAllowedDate();
    final DateTime maxDate = RelatorioListFilters.maxAllowedDate();
    return showProtectedDialog<RelatorioListFilters>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (prefixFields != null) ...prefixFields(setStateDialog),
                      FormSectionField(
                        label: 'Local Cirurgia',
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
                      _triDropdown(
                        label: 'Dar Visto',
                        value: darVisto,
                        onChanged: (AgendaTriFilter value) =>
                            setStateDialog(() => darVisto = value),
                      ),
                      FormSectionDropdown<RelatorioDateFilterField>(
                        label: 'Tipo Periodo',
                        value: dateField,
                        items: const <DropdownMenuItem<RelatorioDateFilterField>>[
                          DropdownMenuItem<RelatorioDateFilterField>(
                            value: RelatorioDateFilterField.dataCirurgia,
                            child: Text('1 = Data Cirurgia'),
                          ),
                          DropdownMenuItem<RelatorioDateFilterField>(
                            value: RelatorioDateFilterField.dataEmissao,
                            child: Text('2 = Data Emissao'),
                          ),
                        ],
                        onChanged: (RelatorioDateFilterField? value) {
                          if (value != null) {
                            setStateDialog(() => dateField = value);
                          }
                        },
                      ),
                      FormSectionField(
                        label: 'Digitado por',
                        controller: digitadoController,
                      ),
                      FormSectionDropdown<RelatorioLadoFilter>(
                        label: 'Lado',
                        value: lado,
                        items: const <DropdownMenuItem<RelatorioLadoFilter>>[
                          DropdownMenuItem<RelatorioLadoFilter>(
                            value: RelatorioLadoFilter.todos,
                            child: Text('T = Todos'),
                          ),
                          DropdownMenuItem<RelatorioLadoFilter>(
                            value: RelatorioLadoFilter.esquerdo,
                            child: Text('E = Esquerdo'),
                          ),
                          DropdownMenuItem<RelatorioLadoFilter>(
                            value: RelatorioLadoFilter.direito,
                            child: Text('D = Direito'),
                          ),
                          DropdownMenuItem<RelatorioLadoFilter>(
                            value: RelatorioLadoFilter.ambos,
                            child: Text('A = Ambos'),
                          ),
                        ],
                        onChanged: (RelatorioLadoFilter? value) {
                          if (value != null) {
                            setStateDialog(() => lado = value);
                          }
                        },
                      ),
                      FormSectionField(
                        label: 'Tipo',
                        controller: tipoController,
                        subtitle: tipoCirurgiaName,
                        keyboardType: TextInputType.number,
                        onSearch: () => _applyLookup(
                          context: context,
                          pick: () => EntityLookupPicker.pickTipoCirurgia(context),
                          controller: tipoController,
                          setName: (String? name) => tipoCirurgiaName = name,
                          setStateDialog: setStateDialog,
                        ),
                      ),
                      FormSectionField(
                        label: 'Circulante',
                        controller: codcirController,
                        subtitle: circulanteName,
                        keyboardType: TextInputType.number,
                        onSearch: () => _applyLookup(
                          context: context,
                          pick: () => EntityLookupPicker.pickTipoCirurgia(context),
                          controller: codcirController,
                          setName: (String? name) => circulanteName = name,
                          setStateDialog: setStateDialog,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final DateTime? picked = await showProtectedDatePicker(
                            context: context,
                            initialDate: dateFrom ?? DateTime.now(),
                            firstDate: minDate,
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
                            firstDate: minDate,
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
                        label: 'No Rel',
                        controller: numrelController,
                        keyboardType: TextInputType.number,
                      ),
                      FormSectionDropdown<RelatorioSexoFilter>(
                        label: 'Sexo',
                        value: sexo,
                        items: const <DropdownMenuItem<RelatorioSexoFilter>>[
                          DropdownMenuItem<RelatorioSexoFilter>(
                            value: RelatorioSexoFilter.todos,
                            child: Text('T = Todos'),
                          ),
                          DropdownMenuItem<RelatorioSexoFilter>(
                            value: RelatorioSexoFilter.masculino,
                            child: Text('M = Masculino'),
                          ),
                          DropdownMenuItem<RelatorioSexoFilter>(
                            value: RelatorioSexoFilter.feminino,
                            child: Text('F = Feminino'),
                          ),
                        ],
                        onChanged: (RelatorioSexoFilter? value) {
                          if (value != null) {
                            setStateDialog(() => sexo = value);
                          }
                        },
                      ),
                      _triDropdown(
                        label: 'Rel Problema',
                        value: relProblema,
                        onChanged: (AgendaTriFilter value) =>
                            setStateDialog(() => relProblema = value),
                      ),
                      _triDropdown(
                        label: 'Rel Com Agenda',
                        value: relComAgenda,
                        onChanged: (AgendaTriFilter value) =>
                            setStateDialog(() => relComAgenda = value),
                      ),
                      FormSectionField(
                        label: 'Instrumentador',
                        controller: codinsController,
                        subtitle: instrumentadorName,
                        keyboardType: TextInputType.number,
                        onSearch: () => _applyLookup(
                          context: context,
                          pick: () => EntityLookupPicker.pickInstrumentador(context),
                          controller: codinsController,
                          setName: (String? name) => instrumentadorName = name,
                          setStateDialog: setStateDialog,
                        ),
                      ),
                      FormSectionField(
                        label: 'Produto',
                        controller: produtoController,
                      ),
                      _triDropdown(
                        label: 'Rel Com Pedido',
                        value: relComPedido,
                        onChanged: (AgendaTriFilter value) =>
                            setStateDialog(() => relComPedido = value),
                      ),
                      FormSectionField(
                        label: 'No Agenda',
                        controller: nagecirController,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    onClearExtra?.call();
                    Navigator.of(dialogContext).pop(const RelatorioListFilters());
                  },
                  child: const Text('Limpar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      RelatorioListFilters(
                        dateFrom: dateFrom,
                        dateTo: dateTo,
                        dateField: dateField,
                        hospitalQuery: hospitalController.text.trim(),
                        medicoQuery: medicoController.text.trim(),
                        convenioQuery: convenioController.text.trim(),
                        pacienteQuery: pacienteController.text.trim(),
                        digitadoPorQuery: digitadoController.text.trim(),
                        numrelQuery: numrelController.text.trim(),
                        nagecirQuery: nagecirController.text.trim(),
                        codinsQuery: codinsController.text.trim(),
                        codcirQuery: codcirController.text.trim(),
                        codProdutoQuery: produtoController.text.trim(),
                        tipoQuery: tipoController.text.trim(),
                        lado: lado,
                        sexo: sexo,
                        darVisto: darVisto,
                        relProblema: relProblema,
                        relComAgenda: relComAgenda,
                        relComPedido: relComPedido,
                      ),
                    );
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
