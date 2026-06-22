import '../../../core/services/paginated_api_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../models/tipo_cirurgia_model.dart';

class TipoCirurgiaServicePaginado {
  Future<TipoCirurgiaPaginatedResponse> fetchTiposCirurgiaPaginated({
    required int page,
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    try {
      final PaginatedApiDecoded decoded = await PaginatedApiHelper.fetchPage(
        menuPath: '/menu/tipo-cirurgia',
        queryParams: PaginatedApiHelper.buildListQuery(
          page: page,
          pageSize: pageSize,
          sortBy: sortBy ?? 'name',
          sortOrder: sortOrder ?? 'asc',
          search: searchQuery,
        ),
      );
      final List<TipoCirurgia> tipos = decoded.data
          .map(
            (dynamic item) =>
                TipoCirurgia.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      return TipoCirurgiaPaginatedResponse(
        tiposCirurgia: tipos,
        pagination: TipoCirurgiaPaginationInfo.fromJson(decoded.pagination),
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  Future<TipoCirurgiaPaginatedResponse> fetchNextPage(
    TipoCirurgiaPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasNextPage) {
      throw Exception('Não há mais páginas para carregar');
    }
    return fetchTiposCirurgiaPaginated(
      page: currentPagination.currentPage + 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<TipoCirurgiaPaginatedResponse> fetchPreviousPage(
    TipoCirurgiaPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasPreviousPage) {
      throw Exception('Não há página anterior');
    }
    return fetchTiposCirurgiaPaginated(
      page: currentPagination.currentPage - 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<TipoCirurgiaPaginatedResponse> fetchPage(
    int page, {
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    return fetchTiposCirurgiaPaginated(
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  void clearCache() {}
}
