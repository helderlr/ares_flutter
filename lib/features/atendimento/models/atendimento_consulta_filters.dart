import 'atendimento_consulta_model.dart';

class AtendimentoConsultaFilters {
  final DateTime dateFrom;
  final DateTime dateTo;
  final AtendimentoConsultaGroupBy groupBy;
  final String? medico;
  final String? hospital;
  final String? convenio;
  final String? tipoCirurgia;
  final String? vendedor;
  final String? instrumentador;

  const AtendimentoConsultaFilters({
    required this.dateFrom,
    required this.dateTo,
    required this.groupBy,
    this.medico,
    this.hospital,
    this.convenio,
    this.tipoCirurgia,
    this.vendedor,
    this.instrumentador,
  });

  factory AtendimentoConsultaFilters.currentMonth({
    AtendimentoConsultaGroupBy groupBy = AtendimentoConsultaGroupBy.medico,
  }) {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, 1);
    final DateTime end = DateTime(now.year, now.month + 1, 0);
    return AtendimentoConsultaFilters(
      dateFrom: start,
      dateTo: end,
      groupBy: groupBy,
    );
  }

  AtendimentoConsultaFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    AtendimentoConsultaGroupBy? groupBy,
    String? medico,
    String? hospital,
    String? convenio,
    String? tipoCirurgia,
    String? vendedor,
    String? instrumentador,
    bool clearMedico = false,
    bool clearHospital = false,
    bool clearConvenio = false,
    bool clearTipoCirurgia = false,
    bool clearVendedor = false,
    bool clearInstrumentador = false,
  }) {
    return AtendimentoConsultaFilters(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      groupBy: groupBy ?? this.groupBy,
      medico: clearMedico ? null : (medico ?? this.medico),
      hospital: clearHospital ? null : (hospital ?? this.hospital),
      convenio: clearConvenio ? null : (convenio ?? this.convenio),
      tipoCirurgia: clearTipoCirurgia ? null : (tipoCirurgia ?? this.tipoCirurgia),
      vendedor: clearVendedor ? null : (vendedor ?? this.vendedor),
      instrumentador:
          clearInstrumentador ? null : (instrumentador ?? this.instrumentador),
    );
  }

  AtendimentoConsultaFilters applyLast30Days() {
    final DateTime end = DateTime.now();
    final DateTime start = end.subtract(const Duration(days: 29));
    return copyWith(dateFrom: start, dateTo: end);
  }

  Map<String, String> toQueryParams() {
    final Map<String, String> params = <String, String>{
      'dateFrom': _formatIsoDate(dateFrom),
      'dateTo': _formatIsoDate(dateTo),
      'groupBy': groupBy.apiValue,
    };
    _putIfNotEmpty(params, 'medico', medico);
    _putIfNotEmpty(params, 'hospital', hospital);
    _putIfNotEmpty(params, 'convenio', convenio);
    _putIfNotEmpty(params, 'tipoCirurgia', tipoCirurgia);
    _putIfNotEmpty(params, 'vendedor', vendedor);
    _putIfNotEmpty(params, 'instrumentador', instrumentador);
    return params;
  }

  static String _formatIsoDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static void _putIfNotEmpty(
    Map<String, String> params,
    String key,
    String? value,
  ) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      params[key] = trimmed;
    }
  }
}
