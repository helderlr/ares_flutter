import 'package:flutter/material.dart';

import '../../relatorio_cirurgia/models/relatorio_list_filters.dart';
import '../../relatorio_cirurgia/widgets/relatorio_filter_dialog.dart';
import '../models/registro_hora_list_filters.dart';
import '../models/registro_hora_situacao_filter.dart';
import '../../../core/widgets/form_section_field.dart';

class RegistroHoraFilterDialog {
  static Future<RegistroHoraListFilters?> show(
    BuildContext context, {
    RegistroHoraListFilters? initial,
  }) async {
    RegistroHoraSituacaoFilter situacao =
        initial?.situacao ?? RegistroHoraSituacaoFilter.todos;
    final RelatorioListFilters? relatorioResult =
        await RelatorioFilterDialog.show(
      context,
      initial: initial?.relatorioFilters,
      title: 'Filtro Registro Hora',
      prefixFields: (StateSetter setStateDialog) {
        return <Widget>[
          FormSectionDropdown<RegistroHoraSituacaoFilter>(
            label: 'Situacao',
            value: situacao,
            items: RegistroHoraSituacaoFilter.values
                .map(
                  (RegistroHoraSituacaoFilter value) =>
                      DropdownMenuItem<RegistroHoraSituacaoFilter>(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (RegistroHoraSituacaoFilter? value) {
              if (value != null) {
                setStateDialog(() => situacao = value);
              }
            },
          ),
        ];
      },
      onClearExtra: () {
        situacao = RegistroHoraSituacaoFilter.todos;
      },
    );
    if (relatorioResult == null) {
      return null;
    }
    return RegistroHoraListFilters(
      relatorioFilters: relatorioResult,
      situacao: situacao,
    );
  }
}
