import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';

class MedicoService {
  Future<Map<String, dynamic>> createMedico({
    required String nome,
    String? crm,
    int? codesp,
  }) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final int? codusu = await AuthService.getCurrentCodusu();
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/medico');
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'empresaId': empresaId,
      'nommed': nome.toUpperCase(),
      if (codusu != null) 'cod_usu': codusu,
      if (crm != null && crm.isNotEmpty) 'crmmed': crm,
      if (codesp != null && codesp > 0) 'codesp': codesp,
    };
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.postUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(requestBody));
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        final dynamic decoded = HttpRequestHelper.decodeResponse(responseBody);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return <String, dynamic>{'success': true};
      }
      if (httpResponse.statusCode == 401) {
        await AuthService.handleSessionExpired();
        throw const UnauthorizedException();
      }
      throw Exception(_extractErrorMessage(responseBody, httpResponse.statusCode));
    } finally {
      httpClient.close();
    }
  }

  Future<void> updateMedico({
    required int codmed,
    required String nome,
    String? crm,
    int? codesp,
  }) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/medico/$codmed');
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'empresaId': empresaId,
      'nommed': nome.toUpperCase(),
      if (crm != null && crm.isNotEmpty) 'crmmed': crm,
      if (codesp != null && codesp > 0) 'codesp': codesp,
    };
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.patchUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(requestBody));
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 200) {
        return;
      }
      if (httpResponse.statusCode == 401) {
        await AuthService.handleSessionExpired();
        throw const UnauthorizedException();
      }
      if (httpResponse.statusCode == 404) {
        throw Exception('Médico não encontrado.');
      }
      throw Exception(_extractErrorMessage(responseBody, httpResponse.statusCode));
    } catch (error) {
      if (error is UnauthorizedException) {
        rethrow;
      }
      if (error.toString().contains('SocketException') ||
          error.toString().contains('HandshakeException') ||
          error.toString().contains('Connection refused')) {
        throw Exception(
          'Erro de conexão. Verifique sua internet e tente novamente.',
        );
      }
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  Future<bool> deleteMedico(int id) async {
    final Map<String, String> paramsWithEmpresa =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/medico/$id')
        .replace(queryParameters: paramsWithEmpresa);
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.deleteUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 200) {
        return true;
      }
      if (httpResponse.statusCode == 404) {
        throw Exception('Médico não encontrado');
      }
      if (httpResponse.statusCode == 401) {
        await AuthService.handleSessionExpired();
        throw const UnauthorizedException();
      }
      throw Exception(_extractErrorMessage(responseBody, httpResponse.statusCode));
    } finally {
      httpClient.close();
    }
  }

  String _extractErrorMessage(String responseBody, int statusCode) {
    if (responseBody.isEmpty) {
      return 'Erro ao processar médico ($statusCode)';
    }
    try {
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final String? error = decoded['error']?.toString();
        if (error != null && error.isNotEmpty) {
          return error;
        }
        final String? message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}
    return 'Erro ao processar médico ($statusCode)';
  }
}
