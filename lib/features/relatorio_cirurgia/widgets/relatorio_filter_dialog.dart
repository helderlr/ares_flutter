import 'package:flutter/material.dart';
import '../../../core/widgets/protected_ui.dart';
import '../../agendamento/models/agenda_list_filters.dart';
import '../models/relatorio_list_filters.dart';

class RelatorioFilterDialog {
  static InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static Widget _triDropdown({
    required String label,
    required AgendaTriFilter value,
    required ValueChanged<AgendaTriFilter> onChanged,
  }) {
    return DropdownButtonFormField<AgendaTriFilter>(
      value: value,
      decoration: _decoration(label),
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
      onChanged: (AgendaTriFilter? v) {
        if (v != null) {
          onChanged(v);
        }
      },
    );
  }

  static Future<RelatorioListFilters?> show(
    BuildContext context, {
    RelatorioListFilters? initial,
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
    DateTime? dateFrom = initial?.dateFrom ?? DateTime.now();
    DateTime? dateTo = initial?.dateTo ?? RelatorioListFilters.maxAllowedDate();
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
              title: const Text('Filtro Rel Cirurgia'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextField(
                        controller: hospitalController,
                        decoration: _decoration('Cod Loc Cir'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: medicoController,
                        decoration: _decoration('Cod Medico'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: convenioController,
                        decoration: _decoration('Cod Convenio'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: pacienteController,
                        decoration: _decoration('Cod Paciente'),
                      ),
                      const SizedBox(height: 10),
                      _triDropdown(
                        label: 'Dar Visto',
                        value: darVisto,
                        onChanged: (AgendaTriFilter v) =>
                            setStateDialog(() => darVisto = v),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<RelatorioDateFilterField>(
                        value: dateField,
                        decoration: _decoration('Tipo Periodo'),
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
                        onChanged: (RelatorioDateFilterField? v) {
                          if (v != null) {
                            setStateDialog(() => dateField = v);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: digitadoController,
                        decoration: _decoration('Digitado por'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<RelatorioLadoFilter>(
                        value: lado,
                        decoration: _decoration('Lado'),
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
                        onChanged: (RelatorioLadoFilter? v) {
                          if (v != null) {
                            setStateDialog(() => lado = v);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: tipoController,
                        decoration: _decoration('Tipo'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: codcirController,
                        decoration: _decoration('Cod Circulante'),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      TextField(
                        controller: numrelController,
                        decoration: _decoration('No Rel'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<RelatorioSexoFilter>(
                        value: sexo,
                        decoration: _decoration('Sexo'),
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
                        onChanged: (RelatorioSexoFilter? v) {
                          if (v != null) {
                            setStateDialog(() => sexo = v);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _triDropdown(
                        label: 'Rel Problema',
                        value: relProblema,
                        onChanged: (AgendaTriFilter v) =>
                            setStateDialog(() => relProblema = v),
                      ),
                      const SizedBox(height: 10),
                      _triDropdown(
                        label: 'Rel Com Agenda',
                        value: relComAgenda,
                        onChanged: (AgendaTriFilter v) =>
                            setStateDialog(() => relComAgenda = v),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: codinsController,
                        decoration: _decoration('Cod Inst'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: produtoController,
                        decoration: _decoration('Cod Produto'),
                      ),
                      const SizedBox(height: 10),
                      _triDropdown(
                        label: 'Rel Com Pedido',
                        value: relComPedido,
                        onChanged: (AgendaTriFilter v) =>
                            setStateDialog(() => relComPedido = v),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nagecirController,
                        decoration: _decoration('No Agenda'),
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
