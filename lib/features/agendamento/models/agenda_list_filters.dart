enum AgendaTriFilter {
  todas,
  sim,
  nao,
}

enum AgendaDateFilterField {
  dataCirurgia,
  dataMovto,
}

class AgendaListFilters {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final AgendaDateFilterField dateField;
  final String? pacienteQuery;
  final String? nummovQuery;
  final String? medicoQuery;
  final String? convenioQuery;
  final String? hospitalQuery;
  final String? tipoCirurgiaQuery;
  final String? instrumentadorQuery;
  final String? vendedorQuery;
  final AgendaTriFilter agendaCancelada;
  final AgendaTriFilter agendaComPedido;

  const AgendaListFilters({
    this.dateFrom,
    this.dateTo,
    this.dateField = AgendaDateFilterField.dataCirurgia,
    this.pacienteQuery,
    this.nummovQuery,
    this.medicoQuery,
    this.convenioQuery,
    this.hospitalQuery,
    this.tipoCirurgiaQuery,
    this.instrumentadorQuery,
    this.vendedorQuery,
    this.agendaCancelada = AgendaTriFilter.todas,
    this.agendaComPedido = AgendaTriFilter.todas,
  });

  static DateTime minAllowedSurgeryDate() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime minAllowedMovementDate() {
    final DateTime now = DateTime.now();
    return DateTime(now.year - 5, 1, 1);
  }

  static DateTime maxAllowedSurgeryDate() {
    final int year = DateTime.now().year + 1;
    return DateTime(year, 12, 31);
  }

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime minDateForField() {
    if (dateField == AgendaDateFilterField.dataMovto) {
      return minAllowedMovementDate();
    }
    return minAllowedSurgeryDate();
  }

  bool get hasUserDateRange => dateFrom != null || dateTo != null;

  bool get hasTextFilters =>
      _hasQuery(pacienteQuery) ||
      _hasQuery(nummovQuery) ||
      _hasQuery(medicoQuery) ||
      _hasQuery(convenioQuery) ||
      _hasQuery(hospitalQuery) ||
      _hasQuery(tipoCirurgiaQuery) ||
      _hasQuery(instrumentadorQuery) ||
      _hasQuery(vendedorQuery);

  bool get hasTriFilters =>
      agendaCancelada != AgendaTriFilter.todas ||
      agendaComPedido != AgendaTriFilter.todas;

  bool get hasActiveFilters =>
      hasUserDateRange || hasTextFilters || hasTriFilters;

  bool _hasQuery(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
