import '../../../core/services/paginated_api_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../models/agendamento_model.dart';
import '../models/agenda_list_filters.dart';

class AgendamentoServicePaginado {

  Future<AgendaCirurgiaPaginatedResponse> fetchAgendamentosPaginated({
    required int page,
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
    AgendaListFilters? filters,
  }) async {
    try {
      return _fetchAgendamentosServerPaginated(
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        sortOrder: sortOrder,
        searchQuery: searchQuery,
        filters: filters,
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception(_formatError(error));
    }
  }

  Future<AgendaCirurgiaPaginatedResponse> _fetchAgendamentosServerPaginated({
    required int page,
    required int pageSize,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
    AgendaListFilters? filters,
  }) async {
    final Map<String, String> extra = _buildAgendaFilterExtra(filters);
    final AgendaDateFilterField dateField =
        filters?.dateField ?? AgendaDateFilterField.dataCirurgia;
    extra['dateField'] =
        dateField == AgendaDateFilterField.dataMovto ? 'datlan' : 'datcir';
    final String effectiveSort = sortOrder ?? 'desc';
    extra['sortDir'] = effectiveSort.toLowerCase() == 'asc' ? 'asc' : 'desc';
    if (filters?.hasUserDateRange == true) {
      if (filters?.dateFrom != null) {
        extra['dateFrom'] =
            PaginatedApiHelper.formatIsoDate(filters!.dateFrom!);
      }
      if (filters?.dateTo != null) {
        extra['dateTo'] = PaginatedApiHelper.formatIsoDate(filters!.dateTo!);
      }
    }
    final PaginatedApiDecoded decoded = await PaginatedApiHelper.fetchPage(
      menuPath: '/menu/agenda-cirurgia',
      queryParams: PaginatedApiHelper.buildListQuery(
        page: page,
        pageSize: pageSize,
        search: searchQuery?.trim().isNotEmpty == true
            ? searchQuery!.trim()
            : null,
        extra: extra,
      ),
      connectionTimeout: const Duration(seconds: 60),
    );
    List<AgendaCirurgia> agendamentos = decoded.data
        .map(
          (dynamic item) =>
              AgendaCirurgia.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    if (sortBy != null && sortBy != 'date') {
      agendamentos = _applySort(agendamentos, sortBy, sortOrder);
    }
    if (filters?.situacaoAgenda != null &&
        filters!.situacaoAgenda != AgendaSituacaoFilter.todos) {
      agendamentos = agendamentos
          .where(
            (AgendaCirurgia item) => matchesSituacaoFilter(
              item,
              filters.situacaoAgenda,
            ),
          )
          .toList();
    }
    return AgendaCirurgiaPaginatedResponse(
      agendamentos: agendamentos,
      pagination: AgendaCirurgiaPaginationInfo.fromJson(decoded.pagination),
    );
  }

  Map<String, String> _buildAgendaFilterExtra(AgendaListFilters? filters) {
    final Map<String, String> extra = <String, String>{};
    if (filters == null) {
      return extra;
    }
    _appendQueryParam(extra, 'paciente', filters.pacienteQuery);
    _appendQueryParam(extra, 'nummov', filters.nummovQuery);
    _appendQueryParam(extra, 'medico', filters.medicoQuery);
    _appendQueryParam(extra, 'convenio', filters.convenioQuery);
    _appendQueryParam(extra, 'hospital', filters.hospitalQuery);
    _appendQueryParam(extra, 'tipoCirurgia', filters.tipoCirurgiaQuery);
    _appendQueryParam(extra, 'instrumentador', filters.instrumentadorQuery);
    _appendQueryParam(extra, 'vendedor', filters.vendedorQuery);
    extra['agendaCancelada'] = _triFilterToParam(filters.agendaCancelada);
    extra['agendaComPedido'] = _triFilterToParam(filters.agendaComPedido);
    _appendTriFilter(extra, 'agendaComRelatorio', filters.agendaComRelatorio);
    _appendTriFilter(extra, 'agendaCopia', filters.agendaCopia);
    if (filters.tipoMarcacao != AgendaTipmarFilter.todas) {
      extra['tipoMarcacao'] = _tipmarFilterToParam(filters.tipoMarcacao);
    }
    if (filters.lado != AgendaLadoFilter.todas) {
      extra['lado'] = _ladoFilterToParam(filters.lado);
    }
    if (filters.situacaoAgenda != AgendaSituacaoFilter.todos) {
      extra['situacao'] = filters.situacaoAgenda.apiCode;
    }
    return extra;
  }

  static bool matchesSituacaoFilter(
    AgendaCirurgia item,
    AgendaSituacaoFilter filter,
  ) {
    if (filter == AgendaSituacaoFilter.todos) {
      return true;
    }
    return item.situacaoDisplayCode == filter.apiCode;
  }

  void _appendTriFilter(
    Map<String, String> extra,
    String key,
    AgendaTriFilter filter,
  ) {
    if (filter != AgendaTriFilter.todas) {
      extra[key] = _triFilterToParam(filter);
    }
  }

  String _ladoFilterToParam(AgendaLadoFilter filter) {
    switch (filter) {
      case AgendaLadoFilter.esquerdo:
        return 'E';
      case AgendaLadoFilter.direito:
        return 'D';
      case AgendaLadoFilter.vazio:
        return 'V';
      case AgendaLadoFilter.todas:
        return 'T';
    }
  }

  String _tipmarFilterToParam(AgendaTipmarFilter filter) {
    switch (filter) {
      case AgendaTipmarFilter.app:
        return 'A';
      case AgendaTipmarFilter.web:
        return 'W';
      case AgendaTipmarFilter.desktop:
        return 'D';
      case AgendaTipmarFilter.googleAgenda:
        return 'G';
      case AgendaTipmarFilter.todas:
        return 'T';
    }
  }

  void _appendQueryParam(
    Map<String, String> extra,
    String key,
    String? value,
  ) {
    if (value != null && value.trim().isNotEmpty) {
      extra[key] = value.trim();
    }
  }

  String _triFilterToParam(AgendaTriFilter tri) {
    switch (tri) {
      case AgendaTriFilter.sim:
        return 'S';
      case AgendaTriFilter.nao:
        return 'N';
      case AgendaTriFilter.todas:
        return 'T';
    }
  }

  int _compareHorcir(String? horaA, String? horaB) {
    final String normalizedA = _normalizeHorcir(horaA);
    final String normalizedB = _normalizeHorcir(horaB);
    return normalizedA.compareTo(normalizedB);
  }

  String _normalizeHorcir(String? hora) {
    if (hora == null || hora.trim().isEmpty) {
      return '99:99:99';
    }
    final List<String> parts = hora.trim().split(':');
    if (parts.length < 2) {
      return hora.trim();
    }
    final String hour = parts[0].padLeft(2, '0');
    final String minute = parts[1].padLeft(2, '0');
    final String second =
        parts.length >= 3 ? parts[2].padLeft(2, '0') : '00';
    return '$hour:$minute:$second';
  }

  List<AgendaCirurgia> _applySort(
    List<AgendaCirurgia> items,
    String? sortBy,
    String? sortOrder,
  ) {
    final List<AgendaCirurgia> sorted = List<AgendaCirurgia>.from(items);
    final bool isDescending = (sortOrder ?? 'desc').toLowerCase() == 'desc';
    switch (sortBy) {
      case 'patient':
        sorted.sort(
          (AgendaCirurgia a, AgendaCirurgia b) =>
              a.pacienteName.compareTo(b.pacienteName),
        );
        break;
      case 'medico':
        sorted.sort(
          (AgendaCirurgia a, AgendaCirurgia b) =>
              a.medicoName.compareTo(b.medicoName),
        );
        break;
      case 'hospital':
        sorted.sort(
          (AgendaCirurgia a, AgendaCirurgia b) =>
              a.hospitalName.compareTo(b.hospitalName),
        );
        break;
      case 'cirurgia':
        sorted.sort(
          (AgendaCirurgia a, AgendaCirurgia b) =>
              a.cirurgiaName.compareTo(b.cirurgiaName),
        );
        break;
      case 'situacao':
        sorted.sort(
          (AgendaCirurgia a, AgendaCirurgia b) => a.status.compareTo(b.status),
        );
        break;
      case 'date':
      default:
        sorted.sort(
          (AgendaCirurgia a, AgendaCirurgia b) =>
              compareAgendas(a, b, dateDescending: isDescending),
        );
        return sorted;
    }
    if (isDescending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  int compareAgendas(
    AgendaCirurgia a,
    AgendaCirurgia b, {
    bool dateDescending = true,
  }) {
    final DateTime? dateA = a.datcir;
    final DateTime? dateB = b.datcir;
    if (dateA == null && dateB == null) {
      return _compareHorcir(a.horcir, b.horcir);
    }
    if (dateA == null) {
      return 1;
    }
    if (dateB == null) {
      return -1;
    }
    final int dateCompare = dateDescending
        ? dateB.compareTo(dateA)
        : dateA.compareTo(dateB);
    if (dateCompare != 0) {
      return dateCompare;
    }
    final int horaCompare = _compareHorcir(a.horcir, b.horcir);
    if (horaCompare != 0) {
      return horaCompare;
    }
    return dateDescending
        ? b.nummov.compareTo(a.nummov)
        : a.nummov.compareTo(b.nummov);
  }

  void clearCache() {}

  String _formatError(Object error) {
    final String message = error.toString();
    if (message.contains('502')) {
      return 'Servidor temporariamente indisponível (502). Tente novamente em alguns minutos.';
    }
    if (message.contains('503')) {
      return 'Serviço indisponível no momento. Tente novamente mais tarde.';
    }
    if (message.contains('SocketException') ||
        message.contains('HandshakeException') ||
        message.contains('Connection refused')) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    }
    return message.replaceAll('Exception: ', '');
  }

  Future<AgendaCirurgiaPaginatedResponse> fetchNextPage(
    AgendaCirurgiaPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
    AgendaListFilters? filters,
  }) async {
    if (!currentPagination.hasNextPage) {
      throw Exception('Não há mais páginas para carregar');
    }
    return fetchAgendamentosPaginated(
      page: currentPagination.currentPage + 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
      filters: filters,
    );
  }

  Future<AgendaCirurgiaPaginatedResponse> fetchPreviousPage(
    AgendaCirurgiaPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
    AgendaListFilters? filters,
  }) async {
    if (!currentPagination.hasPreviousPage) {
      throw Exception('Não há página anterior');
    }
    return fetchAgendamentosPaginated(
      page: currentPagination.currentPage - 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
      filters: filters,
    );
  }

  Future<AgendaCirurgiaPaginatedResponse> fetchPage(
    int page, {
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
    AgendaListFilters? filters,
  }) async {
    return fetchAgendamentosPaginated(
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
      filters: filters,
    );
  }

  Future<List<AgendaCirurgia>> fetchAllAgendamentos({
    AgendaListFilters? filters,
    String? searchQuery,
    int pageSize = 200,
  }) async {
    final List<AgendaCirurgia> allItems = <AgendaCirurgia>[];
    int page = 1;
    while (true) {
      final AgendaCirurgiaPaginatedResponse response =
          await fetchAgendamentosPaginated(
        page: page,
        pageSize: pageSize,
        sortBy: 'date',
        sortOrder: 'asc',
        searchQuery: searchQuery,
        filters: filters,
      );
      allItems.addAll(response.agendamentos);
      if (!response.pagination.hasNextPage) {
        break;
      }
      page++;
    }
    return allItems;
  }
}
