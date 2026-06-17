import 'dart:convert';
import 'dart:io';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';
import '../models/convenio_model.dart';

class ConvenioServicePaginado {

  Future<ConvenioPaginatedResponse> fetchConveniosPaginated({
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
          orderByField = 'nomcon';
          break;
        case 'id':
          orderByField = 'codcon';
          break;
        case 'cnpj':
          orderByField = 'cnpjcon';
          break;
        case 'address':
          orderByField = 'endcon';
          break;
        case 'phone':
          orderByField = 'fonecon';
          break;
        default:
          orderByField = 'nomcon';
      }
      queryParams['OrderBy'] = '$orderByField ${sortOrder ?? 'asc'}';
      print('📊 Ordenação configurada: $orderByField ${sortOrder ?? 'asc'}');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['NOMCON'] = searchQuery;
      print('🔍 Parâmetro de busca adicionado: NOMCON=$searchQuery');
      print('🔍 Query params atualizados: $queryParams');
    }

    final Map<String, String> paramsWithEmpresa =
        await HttpRequestHelper.withEmpresaId(queryParams);
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/convenio')
        .replace(queryParameters: paramsWithEmpresa);

    print('🔍 DEBUG PAGINAÇÃO CONVÊNIOS:');
    print('URL: $uri');
    print('Página: $page, Tamanho: $pageSize');
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
        print('✅ Dados paginados de convênios recebidos');
        print('Tipo de resposta: ${data.runtimeType}');

        ConvenioPaginatedResponse response;

        if (data is List) {
          print('📋 API retornou lista direta com ${data.length} convênios');
          response = ConvenioPaginatedResponse.fromList(data);
        } else if (data is Map<String, dynamic>) {
          print('📋 API retornou objeto com data e pagination');
          response = ConvenioPaginatedResponse.fromJson(data);
        } else {
          throw Exception(
              'Formato de resposta inesperado: ${data.runtimeType}');
        }

        print(
            '📊 Página ${response.pagination.currentPage} de ${response.pagination.totalPages}');
        print('📋 ${response.convenios.length} convênios nesta página');
        print('📈 Total de registros: ${response.pagination.totalRecords}');
        if (searchQuery != null && searchQuery.isNotEmpty) {
          print(
              '🔍 Busca por "$searchQuery" retornou ${response.convenios.length} resultados');
          if (response.convenios.isNotEmpty) {
            print(
                '📝 Primeiros resultados: ${response.convenios.take(3).map((p) => p.name).join(', ')}');
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

  Future<ConvenioPaginatedResponse> fetchNextPage(
    ConvenioPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasNextPage) {
      throw Exception('Não há mais páginas para carregar');
    }

    return fetchConveniosPaginated(
      page: currentPagination.currentPage + 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<ConvenioPaginatedResponse> fetchPreviousPage(
    ConvenioPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasPreviousPage) {
      throw Exception('Não há página anterior');
    }

    return fetchConveniosPaginated(
      page: currentPagination.currentPage - 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<ConvenioPaginatedResponse> fetchPage(
    int page, {
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    return fetchConveniosPaginated(
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }
}





























