import '../../../core/services/paginated_api_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../models/cartao_protese_model.dart';

class CartaoProteseServicePaginado {
  Future<CartaoProtesePaginatedResponse> fetchPaginated({
    required int page,
    int pageSize = 50,
    String? searchQuery,
  }) async {
    try {
      final PaginatedApiDecoded decoded = await PaginatedApiHelper.fetchPage(
        menuPath: '/menu/cartao-protese',
        queryParams: PaginatedApiHelper.buildListQuery(
          page: page,
          pageSize: pageSize,
          sortBy: 'date',
          sortOrder: 'desc',
          search: searchQuery?.trim().isNotEmpty == true
              ? searchQuery!.trim()
              : null,
        ),
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
      throw Exception('Erro de conexão: $error');
    }
  }

  Future<CartaoProtesePaginatedResponse> fetchNextPage(
    CartaoProtesePaginationInfo current, {
    String? searchQuery,
  }) async {
    if (!current.hasNextPage) {
      throw Exception('Não há mais páginas');
    }
    return fetchPaginated(
      page: current.currentPage + 1,
      pageSize: current.pageSize,
      searchQuery: searchQuery,
    );
  }
}
