import 'dart:convert';
import 'dart:io';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';
import '../models/tipo_cirurgia_model.dart';

class TipoCirurgiaServicePaginado {

  Future<TipoCirurgiaPaginatedResponse> fetchTiposCirurgiaPaginated({
    required int page,
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    final queryParams = <String, String>{
      'PageNumber': page.toString(),
      'PageSize': pageSize.toString(),
    };

    if (sortBy != null) {
      String orderByField;
      switch (sortBy) {
        case 'name':
          orderByField = 'nomcir';
          break;
        case 'id':
          orderByField = 'codcir';
          break;
        case 'description':
          orderByField = 'descir';
          break;
        case 'value':
          orderByField = 'valcir';
          break;
        default:
          orderByField = 'nomcir';
      }
      queryParams['OrderBy'] = '$orderByField ${sortOrder ?? 'asc'}';
      print('📊 Ordenação configurada: $orderByField ${sortOrder ?? 'asc'}');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['NOMCIR'] = searchQuery;
      print('🔍 Parâmetro de busca adicionado: NOMCIR=$searchQuery');
      print('🔍 Query params atualizados: $queryParams');
    }

    final Map<String, String> paramsWithEmpresa =
        await HttpRequestHelper.withEmpresaId(queryParams);
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/tipo-cirurgia')
        .replace(queryParameters: paramsWithEmpresa);

    print('🔍 DEBUG PAGINAÇÃO TIPOS DE CIRURGIA:');
    print('URL: $uri');
    print('📋 Parâmetros enviados: $paramsWithEmpresa');

    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      print('📥 Resposta recebida:');
      print('Status: ${httpResponse.statusCode}');
      if (httpResponse.statusCode == 200) {
        final dynamic data = HttpRequestHelper.decodeResponse(responseBody);
        print('✅ Dados paginados de tipos de cirurgia recebidos');
        print('Tipo de resposta: ${data.runtimeType}');

        TipoCirurgiaPaginatedResponse response;

        if (data is List) {
          print(
              '📋 API retornou lista direta com ${data.length} tipos de cirurgia');
          response = TipoCirurgiaPaginatedResponse.fromList(data);
        } else if (data is Map<String, dynamic>) {
          print('📋 API retornou objeto com data e pagination');
          response = TipoCirurgiaPaginatedResponse.fromJson(data);
        } else {
          throw Exception(
              'Formato de resposta inesperado: ${data.runtimeType}');
        }

        print(
            '📊 Página ${response.pagination.currentPage} de ${response.pagination.totalPages}');
        print(
            '📋 ${response.tiposCirurgia.length} tipos de cirurgia nesta página');
        print('📈 Total de registros: ${response.pagination.totalRecords}');
        if (searchQuery != null && searchQuery.isNotEmpty) {
          print(
              '🔍 Busca por "$searchQuery" retornou ${response.tiposCirurgia.length} resultados');
          if (response.tiposCirurgia.isNotEmpty) {
            print(
                '📝 Primeiros resultados: ${response.tiposCirurgia.take(3).map((p) => p.name).join(', ')}');
          }
        }

        httpClient.close();
        return response;
      } else if (httpResponse.statusCode == 401) {
        httpClient.close();
        await AuthService.handleSessionExpired();
        throw const UnauthorizedException();
      } else {
        httpClient.close();
        throw Exception(
            'Erro na API: ${httpResponse.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
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
}
