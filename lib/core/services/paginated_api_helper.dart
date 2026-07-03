import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import 'http_request_helper.dart';
import 'unauthorized_exception.dart';

class PaginatedApiDecoded {
  final List<dynamic> data;
  final Map<String, dynamic> pagination;

  const PaginatedApiDecoded({
    required this.data,
    required this.pagination,
  });
}

class PaginatedApiHelper {
  static Map<String, String> buildListQuery({
    required int page,
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? search,
    Map<String, String> extra = const <String, String>{},
  }) {
    final Map<String, String> query = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      ...extra,
    };
    if (sortBy != null && sortBy.isNotEmpty) {
      query['sortBy'] = _mapSortBy(sortBy);
    }
    if (sortOrder != null && sortOrder.isNotEmpty) {
      query['sortDir'] = sortOrder.toLowerCase() == 'desc' ? 'desc' : 'asc';
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    return query;
  }

  static String _mapSortBy(String sortBy) {
    switch (sortBy) {
      case 'name':
      case 'nompac':
      case 'nommed':
      case 'nomcon':
      case 'nomcir':
      case 'nomcli':
        return 'name';
      case 'id':
      case 'codpac':
      case 'codmed':
      case 'codcon':
      case 'codcir':
      case 'codcli':
        return 'id';
      case 'birthDate':
      case 'datnas':
        return 'birthdate';
      case 'address':
        return 'name';
      case 'fantasy':
        return 'name';
      default:
        return sortBy;
    }
  }

  static Future<PaginatedApiDecoded> fetchPage({
    required String menuPath,
    required Map<String, String> queryParams,
    Duration? connectionTimeout,
  }) async {
    final Map<String, String> paramsWithEmpresa =
        await HttpRequestHelper.withEmpresaId(queryParams);
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}$menuPath')
        .replace(queryParameters: paramsWithEmpresa);
    final HttpClient httpClient = HttpRequestHelper.createClient();
    if (connectionTimeout != null) {
      httpClient.connectionTimeout = connectionTimeout;
    }
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 401) {
        throw const UnauthorizedException();
      }
      if (httpResponse.statusCode != 200) {
        final String? apiError = _tryParseApiError(responseBody);
        if (apiError != null) {
          throw Exception(apiError);
        }
        throw Exception(
          'Erro na API: ${httpResponse.statusCode} - $responseBody',
        );
      }
      return _decodePaginatedBody(responseBody);
    } finally {
      httpClient.close();
    }
  }

  static PaginatedApiDecoded _decodePaginatedBody(String responseBody) {
    if (responseBody.isEmpty) {
      return const PaginatedApiDecoded(
        data: <dynamic>[],
        pagination: <String, dynamic>{},
      );
    }
    final dynamic decoded = json.decode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Formato de resposta inesperado da API');
    }
    if (decoded.containsKey('ok') && decoded['ok'] != true) {
      throw Exception(
        decoded['error']?.toString() ?? 'Erro desconhecido na API',
      );
    }
    final dynamic data = decoded['data'];
    final List<dynamic> rows = data is List ? data : <dynamic>[];
    final Map<String, dynamic> pagination =
        decoded['pagination'] is Map<String, dynamic>
            ? decoded['pagination'] as Map<String, dynamic>
            : <String, dynamic>{};
    return PaginatedApiDecoded(data: rows, pagination: pagination);
  }

  static String? _tryParseApiError(String body) {
    if (body.trim().isEmpty) {
      return null;
    }
    try {
      final dynamic decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final String? error = decoded['error']?.toString();
        if (error != null && error.isNotEmpty) {
          return error;
        }
      }
    } catch (_) {}
    return null;
  }

  static String formatIsoDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
