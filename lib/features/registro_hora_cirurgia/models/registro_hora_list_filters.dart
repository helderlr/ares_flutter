import '../../relatorio_cirurgia/models/relatorio_list_filters.dart';
import 'registro_hora_situacao_filter.dart';

class RegistroHoraListFilters {
  final RelatorioListFilters relatorioFilters;
  final RegistroHoraSituacaoFilter situacao;

  const RegistroHoraListFilters({
    this.relatorioFilters = const RelatorioListFilters(),
    this.situacao = RegistroHoraSituacaoFilter.todos,
  });

  bool get hasActiveFilters {
    return relatorioFilters.hasActiveFilters ||
        situacao != RegistroHoraSituacaoFilter.todos;
  }

  RegistroHoraListFilters cleared() {
    return const RegistroHoraListFilters();
  }
}
