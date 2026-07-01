import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../agendamento/models/agenda_list_filters.dart';
import '../../agendamento/models/agendamento_model.dart';
import '../../agendamento/services/agendamento_service_paginado.dart';
import '../../agendamento/widgets/agenda_filter_dialog.dart';
import '../widgets/cirurgia_day_details_sheet.dart';

class AtendimentoCirurgiaDiariaPage extends StatefulWidget {
  const AtendimentoCirurgiaDiariaPage({super.key});

  @override
  State<AtendimentoCirurgiaDiariaPage> createState() =>
      _AtendimentoCirurgiaDiariaPageState();
}

class _AtendimentoCirurgiaDiariaPageState
    extends State<AtendimentoCirurgiaDiariaPage> {
  static const List<String> _weekdayLabels = <String>[
    'dom.',
    'seg.',
    'ter.',
    'qua.',
    'qui.',
    'sex.',
    'sáb.',
  ];
  static const List<String> _monthLabels = <String>[
    'jan.',
    'fev.',
    'mar.',
    'abr.',
    'mai.',
    'jun.',
    'jul.',
    'ago.',
    'set.',
    'out.',
    'nov.',
    'dez.',
  ];
  final AgendamentoServicePaginado _agendaService =
      AgendamentoServicePaginado();
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;
  bool _filtersActive = false;
  AgendaListFilters _filters = AgendaListFilters(
    dateField: AgendaDateFilterField.dataCirurgia,
  );
  Map<DateTime, List<AgendaCirurgia>> _surgeriesByDay =
      <DateTime, List<AgendaCirurgia>>{};

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _loadMonthData();
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  AgendaListFilters _queryFiltersForMonth() {
    final DateTime monthStart =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final DateTime monthEnd =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    DateTime queryFrom = monthStart;
    DateTime queryTo = monthEnd;
    if (_filters.dateFrom != null || _filters.dateTo != null) {
      final DateTime filterFrom =
          _dateOnly(_filters.dateFrom ?? _filters.dateTo!);
      final DateTime filterTo =
          _dateOnly(_filters.dateTo ?? _filters.dateFrom!);
      queryFrom = filterFrom.isAfter(monthStart) ? filterFrom : monthStart;
      queryTo = filterTo.isBefore(monthEnd) ? filterTo : monthEnd;
    }
    return AgendaListFilters(
      dateFrom: queryFrom,
      dateTo: queryTo,
      dateField: _filters.dateField,
      pacienteQuery: _filters.pacienteQuery,
      nummovQuery: _filters.nummovQuery,
      medicoQuery: _filters.medicoQuery,
      convenioQuery: _filters.convenioQuery,
      hospitalQuery: _filters.hospitalQuery,
      tipoCirurgiaQuery: _filters.tipoCirurgiaQuery,
      instrumentadorQuery: _filters.instrumentadorQuery,
      vendedorQuery: _filters.vendedorQuery,
      agendaCancelada: _filters.agendaCancelada,
      agendaComPedido: _filters.agendaComPedido,
      agendaComRelatorio: _filters.agendaComRelatorio,
      agendaCopia: _filters.agendaCopia,
      tipoMarcacao: _filters.tipoMarcacao,
      lado: _filters.lado,
      situacaoAgenda: _filters.situacaoAgenda,
    );
  }

  bool _isDayWithinFilterPeriod(DateTime day) {
    final DateTime normalizedDay = _dateOnly(day);
    if (_filters.dateFrom != null) {
      final DateTime from = _dateOnly(_filters.dateFrom!);
      if (normalizedDay.isBefore(from)) {
        return false;
      }
    }
    if (_filters.dateTo != null) {
      final DateTime to = _dateOnly(_filters.dateTo!);
      if (normalizedDay.isAfter(to)) {
        return false;
      }
    }
    return true;
  }

  int _countForDay(DateTime day) {
    if (!_isDayWithinFilterPeriod(day)) {
      return 0;
    }
    return _surgeriesByDay[_dateOnly(day)]?.length ?? 0;
  }

  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);
    try {
      final AgendaListFilters queryFilters = _queryFiltersForMonth();
      if (queryFilters.dateFrom != null &&
          queryFilters.dateTo != null &&
          queryFilters.dateFrom!.isAfter(queryFilters.dateTo!)) {
        if (!mounted) {
          return;
        }
        setState(() {
          _surgeriesByDay = <DateTime, List<AgendaCirurgia>>{};
          _isLoading = false;
        });
        return;
      }
      final List<AgendaCirurgia> items = await _agendaService.fetchAllAgendamentos(
        filters: queryFilters,
      );
      final Map<DateTime, List<AgendaCirurgia>> grouped =
          <DateTime, List<AgendaCirurgia>>{};
      for (final AgendaCirurgia item in items) {
        final DateTime? surgeryDate = item.datcir;
        if (surgeryDate == null) {
          continue;
        }
        final DateTime key = _dateOnly(surgeryDate);
        grouped.putIfAbsent(key, () => <AgendaCirurgia>[]).add(item);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _surgeriesByDay = grouped;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _openFilters() async {
    final DateTime start = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final DateTime end = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final AgendaListFilters? result = await AgendaFilterDialog.show(
      context,
      initial: AgendaListFilters(
        dateFrom: _filters.dateFrom ?? start,
        dateTo: _filters.dateTo ?? end,
        dateField: _filters.dateField,
        pacienteQuery: _filters.pacienteQuery,
        nummovQuery: _filters.nummovQuery,
        medicoQuery: _filters.medicoQuery,
        convenioQuery: _filters.convenioQuery,
        hospitalQuery: _filters.hospitalQuery,
        tipoCirurgiaQuery: _filters.tipoCirurgiaQuery,
        instrumentadorQuery: _filters.instrumentadorQuery,
        vendedorQuery: _filters.vendedorQuery,
        agendaCancelada: _filters.agendaCancelada,
        agendaComPedido: _filters.agendaComPedido,
        agendaComRelatorio: _filters.agendaComRelatorio,
        agendaCopia: _filters.agendaCopia,
        tipoMarcacao: _filters.tipoMarcacao,
        lado: _filters.lado,
        situacaoAgenda: _filters.situacaoAgenda,
      ),
      requireDateRange: false,
      showClearButton: true,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _filters = result;
      _filtersActive = _hasActiveFilters(result);
      if (result.dateFrom != null) {
        _focusedMonth = DateTime(result.dateFrom!.year, result.dateFrom!.month, 1);
      }
    });
    await _loadMonthData();
  }

  bool _hasActiveFilters(AgendaListFilters filters) {
    return filters.dateFrom != null ||
        filters.dateTo != null ||
        filters.pacienteQuery != null ||
        filters.nummovQuery != null ||
        filters.medicoQuery != null ||
        filters.convenioQuery != null ||
        filters.hospitalQuery != null ||
        filters.tipoCirurgiaQuery != null ||
        filters.instrumentadorQuery != null ||
        filters.vendedorQuery != null ||
        filters.agendaCancelada != AgendaTriFilter.todas ||
        filters.agendaComPedido != AgendaTriFilter.todas ||
        filters.agendaComRelatorio != AgendaTriFilter.todas ||
        filters.agendaCopia != AgendaTriFilter.todas ||
        filters.tipoMarcacao != AgendaTipmarFilter.todas ||
        filters.lado != AgendaLadoFilter.todas ||
        filters.situacaoAgenda != AgendaSituacaoFilter.todos;
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    });
    _loadMonthData();
  }

  void _goToToday() {
    final DateTime now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDay = _dateOnly(now);
    });
    _loadMonthData();
  }

  Future<void> _openDayDetails(DateTime day) async {
    final DateTime key = _dateOnly(day);
    final List<AgendaCirurgia> surgeries = _surgeriesByDay[key] ?? const <AgendaCirurgia>[];
    if (surgeries.isEmpty) {
      return;
    }
    setState(() => _selectedDay = key);
    await CirurgiaDayDetailsSheet.show(
      context: context,
      day: key,
      surgeries: surgeries,
    );
  }

  String get _monthTitle {
    const List<String> months = <String>[
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}';
  }

  String? get _filterPeriodLabel {
    if (_filters.dateFrom == null && _filters.dateTo == null) {
      return null;
    }
    String format(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }
    if (_filters.dateFrom != null && _filters.dateTo != null) {
      return 'Período: ${format(_filters.dateFrom!)} até ${format(_filters.dateTo!)}';
    }
    if (_filters.dateFrom != null) {
      return 'Período: a partir de ${format(_filters.dateFrom!)}';
    }
    return 'Período: até ${format(_filters.dateTo!)}';
  }

  @override
  Widget build(BuildContext context) {
    final DateTime firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final int daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final int leadingEmpty = firstDay.weekday % 7;
    final int totalCells = leadingEmpty + daysInMonth;
    final int rowCount = (totalCells / 7).ceil();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cirurgia diária'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            onPressed: _isLoading ? null : _openFilters,
            icon: Icon(
              Icons.filter_list,
              color: _filtersActive ? Colors.orange : Colors.white,
            ),
            tooltip: 'Filtros',
          ),
          IconButton(
            onPressed: _isLoading ? null : _goToToday,
            icon: const Icon(Icons.today),
            tooltip: 'Hoje',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                if (_filterPeriodLabel != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: AppColors.lightBlue.withOpacity(0.12),
                    child: Text(
                      _filterPeriodLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightBlue,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          _monthTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: List<Widget>.generate(5, (int index) {
                      final int monthOffset = index - 2;
                      final DateTime month = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + monthOffset,
                        1,
                      );
                      final bool isCurrent = month.month == _focusedMonth.month &&
                          month.year == _focusedMonth.year;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          child: Text(
                            month.year == _focusedMonth.year
                                ? _monthLabels[month.month - 1]
                                : '${month.year}',
                            style: TextStyle(
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent
                                  ? AppColors.lightBlue
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: _weekdayLabels
                        .map(
                          (String label) => Expanded(
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: rowCount * 7,
                    itemBuilder: (BuildContext context, int index) {
                      final int dayIndex = index - leadingEmpty + 1;
                      if (dayIndex < 1 || dayIndex > daysInMonth) {
                        return const SizedBox.shrink();
                      }
                      final DateTime day = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month,
                        dayIndex,
                      );
                      final DateTime key = _dateOnly(day);
                      final int count = _countForDay(day);
                      final bool isInPeriod = _isDayWithinFilterPeriod(day);
                      final bool isSelected = _selectedDay != null &&
                          _dateOnly(_selectedDay!) == key;
                      final bool isToday = _dateOnly(DateTime.now()) == key;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: count > 0 ? () => _openDayDetails(day) : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.lightBlue.withOpacity(0.15)
                                  : isInPeriod
                                      ? Colors.grey.shade100
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isToday
                                    ? AppColors.lightBlue
                                    : Colors.transparent,
                                width: isToday ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Stack(
                              children: <Widget>[
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    '$dayIndex',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isInPeriod
                                          ? (isToday
                                              ? AppColors.lightBlue
                                              : Colors.black87)
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      width: count > 9 ? 20 : 16,
                                      height: count > 9 ? 20 : 16,
                                      decoration: const BoxDecoration(
                                        color: AppColors.lightBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        count > 99 ? '99' : '$count',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: count > 9 ? 8 : 9,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
