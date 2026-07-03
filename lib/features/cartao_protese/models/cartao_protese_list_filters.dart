class CartaoProteseListFilters {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? pacienteQuery;
  final String? medicoQuery;
  final String? hospitalQuery;
  final String? nummovQuery;
  final String? numpedvQuery;

  const CartaoProteseListFilters({
    this.dateFrom,
    this.dateTo,
    this.pacienteQuery,
    this.medicoQuery,
    this.hospitalQuery,
    this.nummovQuery,
    this.numpedvQuery,
  });

  static DateTime minAllowedDate() => DateTime(2010, 1, 1);

  static DateTime maxAllowedDate() {
    return DateTime(DateTime.now().year + 1, 12, 31);
  }

  bool get hasActiveFilters {
    return dateFrom != null ||
        dateTo != null ||
        _hasQuery(pacienteQuery) ||
        _hasQuery(medicoQuery) ||
        _hasQuery(hospitalQuery) ||
        _hasQuery(nummovQuery) ||
        _hasQuery(numpedvQuery);
  }

  bool _hasQuery(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  CartaoProteseListFilters cleared() => const CartaoProteseListFilters();
}
