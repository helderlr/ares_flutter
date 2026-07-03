import '../../../core/services/paginated_api_helper.dart';
import '../../../core/services/unauthorized_exception.dart';

class InstrumentadorItem {
  final int codins;
  final String nomins;

  const InstrumentadorItem({
    required this.codins,
    required this.nomins,
  });

  factory InstrumentadorItem.fromJson(Map<String, dynamic> json) {
    final dynamic codigo = json['codins'] ?? json['CODINS'];
    final dynamic nome = json['nomins'] ?? json['NOMINS'] ?? json['nominstru1'];
    return InstrumentadorItem(
      codins: codigo is int
          ? codigo
          : int.tryParse(codigo?.toString() ?? '') ?? 0,
      nomins: nome?.toString().trim().isNotEmpty == true
          ? nome.toString().trim()
          : 'Instrumentador ${codigo ?? ''}',
    );
  }
}

class InstrumentadorPaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;

  const InstrumentadorPaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
  });

  bool get hasNextPage => currentPage < totalPages;

  factory InstrumentadorPaginationInfo.fromJson(Map<String, dynamic> json) {
    return InstrumentadorPaginationInfo(
      currentPage: json['currentPage'] as int? ?? json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 50,
      totalRecords: json['totalRecords'] as int? ?? json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}

class InstrumentadorPaginatedResponse {
  final List<InstrumentadorItem> instrumentadores;
  final InstrumentadorPaginationInfo pagination;

  const InstrumentadorPaginatedResponse({
    required this.instrumentadores,
    required this.pagination,
  });
}

class InstrumentadorServicePaginado {
  Future<InstrumentadorPaginatedResponse> fetchInstrumentadoresPaginated({
    required int page,
    int pageSize = 50,
    String? searchQuery,
  }) async {
    try {
      final PaginatedApiDecoded decoded = await PaginatedApiHelper.fetchPage(
        menuPath: '/menu/instrumentador',
        queryParams: PaginatedApiHelper.buildListQuery(
          page: page,
          pageSize: pageSize,
          sortBy: 'name',
          sortOrder: 'asc',
          search: searchQuery,
        ),
      );
      final List<InstrumentadorItem> instrumentadores = decoded.data
          .map(
            (dynamic item) =>
                InstrumentadorItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      return InstrumentadorPaginatedResponse(
        instrumentadores: instrumentadores,
        pagination: InstrumentadorPaginationInfo.fromJson(decoded.pagination),
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }
}
