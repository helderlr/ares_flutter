import '../../../core/services/paginated_api_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../agendamento/models/agenda_list_filters.dart';
import '../models/relatorio_cirurgia_model.dart';
import '../models/relatorio_list_filters.dart';

class RelatorioCirurgiaServicePaginado {
  Future<RelatorioCirurgiaPaginatedResponse> fetchPaginated({
    required int page,
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
    RelatorioListFilters? filters,
  }) async {
    try {
      final Map<String, String> extra = _buildFilterExtra(filters);
      if (filters?.dateFrom != null) {
        extra['dateFrom'] = _formatApiDate(filters!.dateFrom!);
      }
      if (filters?.dateTo != null) {
        extra['dateTo'] = _formatApiDate(filters!.dateTo!);
      }
      if (filters != null) {
        extra['dateField'] = filters.dateField == RelatorioDateFilterField.dataEmissao
            ? 'datmov'
            : 'datcir';
      }
      final PaginatedApiDecoded decoded = await PaginatedApiHelper.fetchPage(
        menuPath: '/menu/relatorio-cirurgia',
        queryParams: PaginatedApiHelper.buildListQuery(
          page: page,
          pageSize: pageSize,
          sortBy: sortBy ?? 'date',
          sortOrder: sortOrder ?? 'desc',
          search: searchQuery?.trim().isNotEmpty == true
              ? searchQuery!.trim()
              : null,
          extra: extra,
        ),
      );
      final List<RelatorioCirurgia> itens = decoded.data
          .map(
            (dynamic item) =>
                RelatorioCirurgia.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      return RelatorioCirurgiaPaginatedResponse(
        itens: itens,
        pagination: RelatorioCirurgiaPaginationInfo.fromJson(decoded.pagination),
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  Future<RelatorioCirurgiaPaginatedResponse> fetchNextPage(
    RelatorioCirurgiaPaginationInfo current, {
    String? searchQuery,
    RelatorioListFilters? filters,
  }) async {
    if (!current.hasNextPage) {
      throw Exception('Não há mais páginas');
    }
    return fetchPaginated(
      page: current.currentPage + 1,
      pageSize: current.pageSize,
      searchQuery: searchQuery,
      filters: filters,
    );
  }

  Future<List<RelatorioCirurgia>> fetchAllRelatorios({
    RelatorioListFilters? filters,
    String? searchQuery,
    int pageSize = 200,
  }) async {
    final List<RelatorioCirurgia> allItems = <RelatorioCirurgia>[];
    int page = 1;
    while (true) {
      final RelatorioCirurgiaPaginatedResponse response = await fetchPaginated(
        page: page,
        pageSize: pageSize,
        searchQuery: searchQuery,
        filters: filters,
      );
      allItems.addAll(response.itens);
      if (!response.pagination.hasNextPage) {
        break;
      }
      page++;
    }
    return allItems;
  }

  Map<String, String> _buildFilterExtra(RelatorioListFilters? filters) {
    final Map<String, String> extra = <String, String>{};
    if (filters == null) {
      return extra;
    }
    _append(extra, 'hospital', filters.hospitalQuery);
    _append(extra, 'medico', filters.medicoQuery);
    _append(extra, 'convenio', filters.convenioQuery);
    _append(extra, 'paciente', filters.pacienteQuery);
    _append(extra, 'digitadoPor', filters.digitadoPorQuery);
    _append(extra, 'numrel', filters.numrelQuery);
    _append(extra, 'nagecir', filters.nagecirQuery);
    _append(extra, 'codins', filters.codinsQuery);
    _append(extra, 'codcir', filters.codcirQuery);
    _append(extra, 'codProduto', filters.codProdutoQuery);
    _append(extra, 'tipo', filters.tipoQuery);
    if (filters.lado != RelatorioLadoFilter.todos) {
      extra['lado'] = filters.lado.apiCode;
    }
    if (filters.sexo != RelatorioSexoFilter.todos) {
      extra['sexo'] = filters.sexo.apiCode;
    }
    _appendTri(extra, 'darVisto', filters.darVisto);
    _appendTri(extra, 'relProblema', filters.relProblema);
    _appendTri(extra, 'relComAgenda', filters.relComAgenda);
    _appendTri(extra, 'relComPedido', filters.relComPedido);
    return extra;
  }

  void _append(Map<String, String> extra, String key, String? value) {
    if (value != null && value.trim().isNotEmpty) {
      extra[key] = value.trim();
    }
  }

  void _appendTri(Map<String, String> extra, String key, AgendaTriFilter tri) {
    if (tri != AgendaTriFilter.todas) {
      extra[key] = tri == AgendaTriFilter.sim ? 'S' : 'N';
    }
  }

  String _formatApiDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
