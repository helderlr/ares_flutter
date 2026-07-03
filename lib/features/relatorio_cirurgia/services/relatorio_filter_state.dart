import '../models/relatorio_list_filters.dart';

class RelatorioFilterState {
  static RelatorioListFilters? _activeFilters;

  static RelatorioListFilters? get activeFilters => _activeFilters;

  static bool get hasActiveFilters =>
      _activeFilters != null && _activeFilters!.hasActiveFilters;

  static void update(RelatorioListFilters filters) {
    if (filters.hasActiveFilters) {
      _activeFilters = filters;
      return;
    }
    _activeFilters = null;
  }

  static void clear() {
    _activeFilters = null;
  }
}
