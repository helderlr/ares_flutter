import 'dart:convert';
import 'dart:io';
import '../../features/login/services/auth_service.dart';
import 'forbidden_exception.dart';
import 'unauthorized_exception.dart';

class HttpRequestHelper {
  static HttpClient createClient() {
    return HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
  }

  static Future<void> applyJsonHeaders(HttpClientRequest request) async {
    final Map<String, String> headers = await AuthService.buildAuthHeaders();
    headers.forEach(request.headers.set);
  }

  static Future<Map<String, String>> withEmpresaId(
    Map<String, String> queryParams,
  ) async {
    final String empresaId = await AuthService.requireEmpresaId();
    return {
      ...queryParams,
      'empresaId': empresaId,
    };
  }

  static Future<void> throwIfUnauthorized(int statusCode) async {
    if (statusCode == 401) {
      throw const UnauthorizedException();
    }
    if (statusCode == 403) {
      throw const ForbiddenException();
    }
  }

  static dynamic decodeResponse(String responseBody) {
    if (responseBody.isEmpty) {
      return null;
    }
    final dynamic decoded = json.decode(responseBody);
    if (decoded is Map<String, dynamic> && decoded.containsKey('ok')) {
      if (decoded['ok'] != true) {
        throw Exception(
          decoded['error']?.toString() ?? 'Erro desconhecido na API',
        );
      }
      if (decoded.containsKey('data')) {
        return decoded['data'];
      }
    }
    return decoded;
  }
}
