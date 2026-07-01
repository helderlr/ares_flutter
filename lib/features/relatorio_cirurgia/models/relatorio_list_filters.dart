import '../../agendamento/models/agenda_list_filters.dart';

enum RelatorioDateFilterField {
  dataCirurgia,
  dataEmissao,
}

enum RelatorioSexoFilter {
  todos,
  masculino,
  feminino,
}

enum RelatorioLadoFilter {
  todos,
  esquerdo,
  direito,
  ambos,
}

extension RelatorioSexoFilterApi on RelatorioSexoFilter {
  String get apiCode {
    switch (this) {
      case RelatorioSexoFilter.masculino:
        return 'M';
      case RelatorioSexoFilter.feminino:
        return 'F';
      case RelatorioSexoFilter.todos:
        return 'T';
    }
  }
}

extension RelatorioLadoFilterApi on RelatorioLadoFilter {
  String get apiCode {
    switch (this) {
      case RelatorioLadoFilter.esquerdo:
        return 'E';
      case RelatorioLadoFilter.direito:
        return 'D';
      case RelatorioLadoFilter.ambos:
        return 'A';
      case RelatorioLadoFilter.todos:
        return 'T';
    }
  }
}

class RelatorioListFilters {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final RelatorioDateFilterField dateField;
  final String? hospitalQuery;
  final String? medicoQuery;
  final String? convenioQuery;
  final String? pacienteQuery;
  final String? digitadoPorQuery;
  final String? numrelQuery;
  final String? nagecirQuery;
  final String? codinsQuery;
  final String? codcirQuery;
  final String? codProdutoQuery;
  final String? tipoQuery;
  final RelatorioLadoFilter lado;
  final RelatorioSexoFilter sexo;
  final AgendaTriFilter darVisto;
  final AgendaTriFilter relProblema;
  final AgendaTriFilter relComAgenda;
  final AgendaTriFilter relComPedido;

  const RelatorioListFilters({
    this.dateFrom,
    this.dateTo,
    this.dateField = RelatorioDateFilterField.dataCirurgia,
    this.hospitalQuery,
    this.medicoQuery,
    this.convenioQuery,
    this.pacienteQuery,
    this.digitadoPorQuery,
    this.numrelQuery,
    this.nagecirQuery,
    this.codinsQuery,
    this.codcirQuery,
    this.codProdutoQuery,
    this.tipoQuery,
    this.lado = RelatorioLadoFilter.todos,
    this.sexo = RelatorioSexoFilter.todos,
    this.darVisto = AgendaTriFilter.todas,
    this.relProblema = AgendaTriFilter.todas,
    this.relComAgenda = AgendaTriFilter.todas,
    this.relComPedido = AgendaTriFilter.todas,
  });

  static DateTime minAllowedDate() {
    return DateTime(2010, 1, 1);
  }

  static DateTime maxAllowedDate() {
    return DateTime(DateTime.now().year + 1, 12, 31);
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool get hasNonDefaultDateRange {
    if (dateFrom == null && dateTo == null) {
      return false;
    }
    final DateTime today = _dateOnly(DateTime.now());
    final DateTime defaultTo = _dateOnly(maxAllowedDate());
    final DateTime? from =
        dateFrom != null ? _dateOnly(dateFrom!) : null;
    final DateTime? to = dateTo != null ? _dateOnly(dateTo!) : null;
    return from != today || to != defaultTo;
  }

  bool get hasTextFilters {
    return _hasQuery(hospitalQuery) ||
        _hasQuery(medicoQuery) ||
        _hasQuery(convenioQuery) ||
        _hasQuery(pacienteQuery) ||
        _hasQuery(digitadoPorQuery) ||
        _hasQuery(numrelQuery) ||
        _hasQuery(nagecirQuery) ||
        _hasQuery(codinsQuery) ||
        _hasQuery(codcirQuery) ||
        _hasQuery(codProdutoQuery) ||
        _hasQuery(tipoQuery);
  }

  bool get hasTriFilters {
    return lado != RelatorioLadoFilter.todos ||
        sexo != RelatorioSexoFilter.todos ||
        darVisto != AgendaTriFilter.todas ||
        relProblema != AgendaTriFilter.todas ||
        relComAgenda != AgendaTriFilter.todas ||
        relComPedido != AgendaTriFilter.todas;
  }

  bool get hasActiveFilters {
    return hasNonDefaultDateRange ||
        hasTextFilters ||
        hasTriFilters ||
        dateField != RelatorioDateFilterField.dataCirurgia;
  }

  bool _hasQuery(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  RelatorioListFilters cleared() {
    return const RelatorioListFilters();
  }
}
