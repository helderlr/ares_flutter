import '../../../core/services/paginated_api_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../models/hospital_model.dart';

class HospitalServicePaginado {
  Future<HospitalPaginatedResponse> fetchHospitaisPaginated({
    required int page,
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    try {
      final PaginatedApiDecoded decoded = await PaginatedApiHelper.fetchPage(
        menuPath: '/menu/cliente',
        queryParams: PaginatedApiHelper.buildListQuery(
          page: page,
          pageSize: pageSize,
          sortBy: sortBy ?? 'name',
          sortOrder: sortOrder ?? 'asc',
          search: searchQuery,
          extra: const <String, String>{'clihos': 'S'},
        ),
      );
      final List<Hospital> hospitais = decoded.data
          .map(
            (dynamic item) =>
                Hospital.fromJson(item as Map<String, dynamic>),
          )
          .where((Hospital item) => item.isHospital)
          .toList();
      return HospitalPaginatedResponse(
        hospitais: hospitais,
        pagination: HospitalPaginationInfo.fromJson(decoded.pagination),
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  void clearCache() {}

  Future<HospitalPaginatedResponse> fetchNextPage(
    HospitalPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasNextPage) {
      throw Exception('Não há mais páginas para carregar');
    }
    return fetchHospitaisPaginated(
      page: currentPagination.currentPage + 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<HospitalPaginatedResponse> fetchPreviousPage(
    HospitalPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasPreviousPage) {
      throw Exception('Não há página anterior');
    }
    return fetchHospitaisPaginated(
      page: currentPagination.currentPage - 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<HospitalPaginatedResponse> fetchPage(
    int page, {
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    return fetchHospitaisPaginated(
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }
}
