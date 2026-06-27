enum AgendaTriFilter {
  todas,
  sim,
  nao,
}

enum AgendaDateFilterField {
  dataCirurgia,
  dataMovto,
}

enum AgendaTipmarFilter {
  todas,
  app,
  web,
  desktop,
  googleAgenda,
}

enum AgendaLadoFilter {
  todas,
  esquerdo,
  direito,
  vazio,
}

enum AgendaSituacaoFilter {
  todos,
  saiu,
  emAberto,
  cancelado,
  retornou,
}

extension AgendaSituacaoFilterLabels on AgendaSituacaoFilter {
  String get label {
    switch (this) {
      case AgendaSituacaoFilter.todos:
        return 'Todos';
      case AgendaSituacaoFilter.saiu:
        return 'S - Saiu';
      case AgendaSituacaoFilter.emAberto:
        return 'A - Em aberto';
      case AgendaSituacaoFilter.cancelado:
        return 'C - Cancelado';
      case AgendaSituacaoFilter.retornou:
        return 'R - Retornou';
    }
  }

  String get apiCode {
    switch (this) {
      case AgendaSituacaoFilter.todos:
        return 'T';
      case AgendaSituacaoFilter.saiu:
        return 'S';
      case AgendaSituacaoFilter.emAberto:
        return 'A';
      case AgendaSituacaoFilter.cancelado:
        return 'C';
      case AgendaSituacaoFilter.retornou:
        return 'R';
    }
  }
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
  final AgendaTriFilter agendaComRelatorio;
  final AgendaTriFilter agendaCopia;
  final AgendaTipmarFilter tipoMarcacao;
  final AgendaLadoFilter lado;
  final AgendaSituacaoFilter situacaoAgenda;

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
    this.agendaComRelatorio = AgendaTriFilter.todas,
    this.agendaCopia = AgendaTriFilter.todas,
    this.tipoMarcacao = AgendaTipmarFilter.todas,
    this.lado = AgendaLadoFilter.todas,
    this.situacaoAgenda = AgendaSituacaoFilter.todos,
  });

  static DateTime minAllowedSurgeryDate() {
    return DateTime(2010, 1, 1);
  }

  static DateTime minAllowedMovementDate() {
    return DateTime(2010, 1, 1);
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
      agendaComPedido != AgendaTriFilter.todas ||
      agendaComRelatorio != AgendaTriFilter.todas ||
      agendaCopia != AgendaTriFilter.todas ||
      tipoMarcacao != AgendaTipmarFilter.todas ||
      lado != AgendaLadoFilter.todas ||
      situacaoAgenda != AgendaSituacaoFilter.todos;

  bool get hasActiveFilters =>
      hasUserDateRange || hasTextFilters || hasTriFilters;

  bool _hasQuery(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
