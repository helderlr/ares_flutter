import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../login/services/auth_service.dart';

class ProjetoParametroService {
  static const String googleMapsApiKeyChave = 'google_maps_api_key';

  Future<String?> fetchValor(String chave) async {
    try {
      final String empresaId = await AuthService.requireEmpresaId();
      final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/parametro').replace(
        queryParameters: <String, String>{
          'empresaId': empresaId,
          'chave': chave,
        },
      );
      final HttpClient client = HttpRequestHelper.createClient();
      try {
        final HttpClientRequest request = await client.getUrl(uri);
        await HttpRequestHelper.applyJsonHeaders(request);
        final HttpClientResponse response = await request.close();
        final String body = await response.transform(utf8.decoder).join();
        if (response.statusCode == 404) {
          return null;
        }
        await HttpRequestHelper.throwIfUnauthorized(response.statusCode);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final dynamic decoded = HttpRequestHelper.decodeResponse(body);
          if (decoded is Map<String, dynamic>) {
            final dynamic valor = decoded['valor'] ?? decoded['value'];
            if (valor != null && valor.toString().trim().isNotEmpty) {
              return valor.toString().trim();
            }
          }
        }
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<bool> saveValor({
    required String chave,
    required String valor,
  }) async {
    try {
      final String empresaId = await AuthService.requireEmpresaId();
      final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/parametro').replace(
        queryParameters: <String, String>{'empresaId': empresaId},
      );
      final HttpClient client = HttpRequestHelper.createClient();
      try {
        final HttpClientRequest request = await client.putUrl(uri);
        await HttpRequestHelper.applyJsonHeaders(request);
        request.headers.contentType = ContentType.json;
        request.write(
          jsonEncode(<String, String>{
            'chave': chave,
            'valor': valor,
          }),
        );
        final HttpClientResponse response = await request.close();
        await HttpRequestHelper.throwIfUnauthorized(response.statusCode);
        return response.statusCode >= 200 && response.statusCode < 300;
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return false;
    }
  }
}
