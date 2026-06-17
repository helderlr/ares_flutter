import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../features/login/services/auth_service.dart';
import 'forbidden_exception.dart';
import 'unauthorized_exception.dart';
import 'unauthorized_exception.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static Future<Map<String, String>> _mergeQueryParams({
    Map<String, String>? queryParameters,
    bool requireEmpresaId = true,
  }) async {
    final Map<String, String> params = Map<String, String>.from(
      queryParameters ?? {},
    );
    if (requireEmpresaId && !params.containsKey('empresaId')) {
      final String empresaId = await AuthService.requireEmpresaId();
      params['empresaId'] = empresaId;
    }
    return params;
  }

  static dynamic parseResponseBody(String responseBody) {
    if (responseBody.isEmpty) {
      return null;
    }
    final dynamic decoded = json.decode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      return decoded;
    }
    if (decoded.containsKey('ok')) {
      final bool isOk = decoded['ok'] == true;
      if (!isOk) {
        final String errorMessage = decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            'Erro desconhecido na API';
        throw ApiException(errorMessage);
      }
      if (decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }
    return decoded;
  }

  static Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool requireEmpresaId = true,
  }) async {
    final Map<String, String> params = await _mergeQueryParams(
      queryParameters: queryParameters,
      requireEmpresaId: requireEmpresaId,
    );
    final Uri uri = ApiConfig.buildUri(path, queryParameters: params);
    final http.Response response = await http.get(
      uri,
      headers: await AuthService.buildAuthHeaders(),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requireEmpresaId = true,
  }) async {
    final Map<String, String> params = await _mergeQueryParams(
      queryParameters: queryParameters,
      requireEmpresaId: requireEmpresaId,
    );
    final Uri uri = ApiConfig.buildUri(path, queryParameters: params);
    final http.Response response = await http.post(
      uri,
      headers: await AuthService.buildAuthHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requireEmpresaId = true,
  }) async {
    final Map<String, String> params = await _mergeQueryParams(
      queryParameters: queryParameters,
      requireEmpresaId: requireEmpresaId,
    );
    final Uri uri = ApiConfig.buildUri(path, queryParameters: params);
    final http.Response response = await http.patch(
      uri,
      headers: await AuthService.buildAuthHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(
    String path, {
    Map<String, String>? queryParameters,
    bool requireEmpresaId = true,
  }) async {
    final Map<String, String> params = await _mergeQueryParams(
      queryParameters: queryParameters,
      requireEmpresaId: requireEmpresaId,
    );
    final Uri uri = ApiConfig.buildUri(path, queryParameters: params);
    final http.Response response = await http.delete(
      uri,
      headers: await AuthService.buildAuthHeaders(),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await AuthService.handleSessionExpired();
      throw const UnauthorizedException();
    }
    if (response.statusCode == 403) {
      throw const ForbiddenException();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parseResponseBody(response.body);
    }
    String errorMessage = 'Erro na API: ${response.statusCode}';
    try {
      final dynamic decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        errorMessage = decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            errorMessage;
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        errorMessage = response.body;
      }
    }
    throw ApiException(errorMessage, statusCode: response.statusCode);
  }
}
