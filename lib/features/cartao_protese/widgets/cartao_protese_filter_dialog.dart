import 'package:flutter/material.dart';

import '../../../core/widgets/entity_lookup_picker.dart';
import '../../../core/widgets/form_section_field.dart';
import '../../../core/widgets/protected_ui.dart';
import '../models/cartao_protese_list_filters.dart';

class CartaoProteseFilterDialog {
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

  static Future<CartaoProteseListFilters?> show(
    BuildContext context, {
    CartaoProteseListFilters? initial,
    bool showClearButton = true,
  }) async {
    final TextEditingController pacienteController = TextEditingController(
      text: initial?.pacienteQuery ?? '',
    );
    final TextEditingController medicoController = TextEditingController(
      text: initial?.medicoQuery ?? '',
    );
    final TextEditingController hospitalController = TextEditingController(
      text: initial?.hospitalQuery ?? '',
    );
    final TextEditingController nummovController = TextEditingController(
      text: initial?.nummovQuery ?? '',
    );
    final TextEditingController numpedvController = TextEditingController(
      text: initial?.numpedvQuery ?? '',
    );
    String? pacienteName;
    String? medicoName;
    String? hospitalName;
    DateTime? dateFrom = initial?.dateFrom;
    DateTime? dateTo = initial?.dateTo;
    return showProtectedDialog<CartaoProteseListFilters>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            Future<void> pickDate({
              required bool isFrom,
            }) async {
              final DateTime minDate = CartaoProteseListFilters.minAllowedDate();
              final DateTime maxDate = CartaoProteseListFilters.maxAllowedDate();
              final DateTime initialDate = isFrom
                  ? (dateFrom ?? DateTime.now())
                  : (dateTo ?? dateFrom ?? DateTime.now());
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: minDate,
                lastDate: maxDate,
              );
              if (picked == null) {
                return;
              }
              setStateDialog(() {
                if (isFrom) {
                  dateFrom = picked;
                } else {
                  dateTo = picked;
                }
              });
            }
            return AlertDialog(
              title: const Text('Filtros - Cartão Prótese'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Data início'),
                      subtitle: Text(
                        dateFrom != null ? _formatDate(dateFrom!) : 'Não definida',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => pickDate(isFrom: true),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Data fim'),
                      subtitle: Text(
                        dateTo != null ? _formatDate(dateTo!) : 'Não definida',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => pickDate(isFrom: false),
                      ),
                    ),
                    FormSectionField(
                      label: 'Paciente',
                      controller: pacienteController,
                      subtitle: pacienteName,
                      onSearch: () => _applyLookup(
                        context: context,
                        pick: () => EntityLookupPicker.pickPaciente(context),
                        controller: pacienteController,
                        setName: (String? name) => pacienteName = name,
                        setStateDialog: setStateDialog,
                      ),
                    ),
                    FormSectionField(
                      label: 'Médico',
                      controller: medicoController,
                      subtitle: medicoName,
                      onSearch: () => _applyLookup(
                        context: context,
                        pick: () => EntityLookupPicker.pickMedico(context),
                        controller: medicoController,
                        setName: (String? name) => medicoName = name,
                        setStateDialog: setStateDialog,
                      ),
                    ),
                    FormSectionField(
                      label: 'Hospital',
                      controller: hospitalController,
                      subtitle: hospitalName,
                      onSearch: () => _applyLookup(
                        context: context,
                        pick: () => EntityLookupPicker.pickHospital(context),
                        controller: hospitalController,
                        setName: (String? name) => hospitalName = name,
                        setStateDialog: setStateDialog,
                      ),
                    ),
                    FormSectionField(
                      label: 'No Cartão',
                      controller: nummovController,
                      keyboardType: TextInputType.number,
                    ),
                    FormSectionField(
                      label: 'No Pedido',
                      controller: numpedvController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                if (showClearButton)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(const CartaoProteseListFilters());
                    },
                    child: const Text('Limpar'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      CartaoProteseListFilters(
                        dateFrom: dateFrom,
                        dateTo: dateTo,
                        pacienteQuery: pacienteController.text.trim().isEmpty
                            ? null
                            : pacienteController.text.trim(),
                        medicoQuery: medicoController.text.trim().isEmpty
                            ? null
                            : medicoController.text.trim(),
                        hospitalQuery: hospitalController.text.trim().isEmpty
                            ? null
                            : hospitalController.text.trim(),
                        nummovQuery: nummovController.text.trim().isEmpty
                            ? null
                            : nummovController.text.trim(),
                        numpedvQuery: numpedvController.text.trim().isEmpty
                            ? null
                            : numpedvController.text.trim(),
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
