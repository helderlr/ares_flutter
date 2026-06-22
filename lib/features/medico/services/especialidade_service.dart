import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';
import '../models/especialidade_model.dart';

class EspecialidadeService {
  static final Map<String, Map<int, String>> _cacheByEmpresa =
      <String, Map<int, String>>{};

  Future<List<Especialidade>> fetchEspecialidades() async {
    final String empresaId = await AuthService.requireEmpresaId();
    final Map<String, String> queryParams =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/lookup/especialidade')
        .replace(queryParameters: queryParams);
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      await HttpRequestHelper.throwIfUnauthorized(httpResponse.statusCode);
      if (httpResponse.statusCode != 200) {
        throw Exception(
          _formatFetchError(httpResponse.statusCode, responseBody),
        );
      }
      final List<dynamic> rows = _extractRows(
        HttpRequestHelper.decodeResponse(responseBody),
      );
      final List<Especialidade> items = rows
          .whereType<Map<String, dynamic>>()
          .map(Especialidade.fromJson)
          .where(
            (Especialidade item) => item.codesp > 0 && item.nome.isNotEmpty,
          )
          .toList()
        ..sort(
          (Especialidade a, Especialidade b) =>
              a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
        );
      _cacheByEmpresa[empresaId] = {
        for (final Especialidade item in items) item.codesp: item.nome,
      };
      return items;
    } on UnauthorizedException {
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  List<dynamic> _extractRows(dynamic decoded) {
    if (decoded is List<dynamic>) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final dynamic data = decoded['data'];
      if (data is List<dynamic>) {
        return data;
      }
      final dynamic items = decoded['items'];
      if (items is List<dynamic>) {
        return items;
      }
    }
    return <dynamic>[];
  }

  Future<Map<int, String>> fetchMapByCodigo() async {
    final List<Especialidade> items = await fetchEspecialidades();
    return {
      for (final Especialidade item in items) item.codesp: item.nome,
    };
  }

  Future<String?> resolveNomeByCodigo(int? codesp) async {
    if (codesp == null || codesp <= 0) {
      return null;
    }
    final Map<int, String> map = await getCachedMap();
    return map[codesp];
  }

  Future<Map<int, String>> getCachedMap() async {
    final String empresaId = await AuthService.requireEmpresaId();
    final Map<int, String>? cached = _cacheByEmpresa[empresaId];
    if (cached != null) {
      return cached;
    }
    return fetchMapByCodigo();
  }

  static void clearCache() {
    _cacheByEmpresa.clear();
  }

  String _formatFetchError(int statusCode, String responseBody) {
    String apiError = '';
    try {
      final dynamic decoded = json.decode(responseBody);
      if (decoded is Map<String, dynamic>) {
        apiError = decoded['error']?.toString().trim() ?? '';
      }
    } catch (_) {}
    if (statusCode == 503) {
      return 'Especialidades indisponíveis no servidor. '
          'Você pode salvar o médico sem especialidade.';
    }
    if (statusCode == 502) {
      return 'Servidor indisponível ao carregar especialidades. '
          'Tente novamente em instantes.';
    }
    if (apiError.isNotEmpty) {
      return apiError;
    }
    return 'Erro ao carregar especialidades ($statusCode).';
  }
}
