import '../../../core/services/paginated_api_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../../core/utils/api_error_formatter.dart';
import '../models/cartao_protese_list_filters.dart';
import '../models/cartao_protese_model.dart';
import 'cartao_protese_api_paths.dart';

class CartaoProteseServicePaginado {
  String? _resolvedListPath;

  Future<CartaoProtesePaginatedResponse> fetchPaginated({
    required int page,
    int pageSize = 50,
    String? searchQuery,
    CartaoProteseListFilters? filters,
  }) async {
    try {
      final Map<String, String> extra = _buildFilterExtra(filters);
      if (filters?.dateFrom != null) {
        extra['dateFrom'] =
            PaginatedApiHelper.formatIsoDate(filters!.dateFrom!);
      }
      if (filters?.dateTo != null) {
        extra['dateTo'] = PaginatedApiHelper.formatIsoDate(filters!.dateTo!);
      }
      extra['dateField'] = 'datcir';
      extra['sortDir'] = 'desc';
      final Map<String, String> queryParams = PaginatedApiHelper.buildListQuery(
        page: page,
        pageSize: pageSize,
        sortBy: 'date',
        sortOrder: 'desc',
        search: searchQuery?.trim().isNotEmpty == true
            ? searchQuery!.trim()
            : null,
        extra: extra,
      );
      final PaginatedApiDecoded decoded = await _fetchPageWithFallback(
        queryParams: queryParams,
      );
      final List<CartaoProtese> itens = decoded.data
          .map(
            (dynamic item) =>
                CartaoProtese.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      return CartaoProtesePaginatedResponse(
        itens: itens,
        pagination: CartaoProtesePaginationInfo.fromJson(decoded.pagination),
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception(ApiErrorFormatter.format(error));
    }
  }

  Future<PaginatedApiDecoded> _fetchPageWithFallback({
    required Map<String, String> queryParams,
  }) async {
    final List<String> paths = _resolvedListPath != null
        ? <String>[_resolvedListPath!]
        : CartaoProteseApiPaths.listPaths;
    Object? lastError;
    for (final String path in paths) {
      try {
        final PaginatedApiDecoded decoded = await PaginatedApiHelper.fetchPage(
          menuPath: path,
          queryParams: queryParams,
        );
        _resolvedListPath = path;
        return decoded;
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? Exception('Não foi possível carregar cartões prótese.');
  }

  Future<CartaoProtese?> findByNumpedv(
    int numpedv, {
    int? excludeNummov,
  }) async {
    final CartaoProtesePaginatedResponse response = await fetchPaginated(
      page: 1,
      pageSize: 50,
      filters: CartaoProteseListFilters(numpedvQuery: numpedv.toString()),
    );
    for (final CartaoProtese item in response.itens) {
      if (item.numpedv == numpedv &&
          (excludeNummov == null || item.nummov != excludeNummov)) {
        return item;
      }
    }
    return null;
  }

  Map<String, String> _buildFilterExtra(CartaoProteseListFilters? filters) {
    final Map<String, String> extra = <String, String>{};
    if (filters == null) {
      return extra;
    }
    _appendQueryParam(extra, 'paciente', filters.pacienteQuery);
    _appendQueryParam(extra, 'medico', filters.medicoQuery);
    _appendQueryParam(extra, 'hospital', filters.hospitalQuery);
    _appendQueryParam(extra, 'nummov', filters.nummovQuery);
    _appendQueryParam(extra, 'numpedv', filters.numpedvQuery);
    return extra;
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

  Future<CartaoProtesePaginatedResponse> fetchNextPage(
    CartaoProtesePaginationInfo current, {
    String? searchQuery,
    CartaoProteseListFilters? filters,
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

  Future<List<CartaoProtese>> fetchAll({
    CartaoProteseListFilters? filters,
    String? searchQuery,
    int pageSize = 200,
  }) async {
    final List<CartaoProtese> allItems = <CartaoProtese>[];
    int page = 1;
    while (true) {
      final CartaoProtesePaginatedResponse response = await fetchPaginated(
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
}
