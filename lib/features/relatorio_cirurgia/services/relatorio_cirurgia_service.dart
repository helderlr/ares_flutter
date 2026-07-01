import 'dart:convert';
import 'dart:io';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../login/services/auth_service.dart';
import '../models/relatorio_cirurgia_model.dart';

class RelatorioCirurgiaService {
  Future<RelatorioCirurgia> create(RelatorioCirurgia item) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final int? codusu = await AuthService.getCurrentCodusu();
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/relatorio-cirurgia');
    final Map<String, dynamic> body = <String, dynamic>{
      'empresaId': empresaId,
      ...item.toWriteJson(),
      if (codusu != null) 'codusu': codusu,
      if (codusu != null) 'usulan': codusu,
    };
    final HttpClient client = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await client.postUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(body));
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      await HttpRequestHelper.throwIfUnauthorized(response.statusCode);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = json.decode(responseBody);
        final Map<String, dynamic> data = decoded is Map<String, dynamic> &&
                decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return RelatorioCirurgia.fromJson(data);
      }
      throw Exception('Erro ao criar relatório: ${response.statusCode} - $responseBody');
    } finally {
      client.close();
    }
  }

  Future<RelatorioCirurgia> update(int nummov, RelatorioCirurgia item) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/relatorio-cirurgia/$nummov');
    final Map<String, dynamic> body = <String, dynamic>{
      'empresaId': empresaId,
      ...item.toWriteJson(),
    };
    final HttpClient client = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await client.patchUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(body));
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      await HttpRequestHelper.throwIfUnauthorized(response.statusCode);
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(responseBody);
        final Map<String, dynamic> data = decoded is Map<String, dynamic> &&
                decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return RelatorioCirurgia.fromJson(data);
      }
      if (response.statusCode == 404) {
        throw Exception('Relatório não encontrado.');
      }
      throw Exception('Erro ao atualizar relatório: ${response.statusCode} - $responseBody');
    } finally {
      client.close();
    }
  }

  Future<RelatorioCirurgia?> getById(int nummov) async {
    final Map<String, String> query =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/relatorio-cirurgia/$nummov')
        .replace(queryParameters: query);
    final HttpClient client = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await client.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      await HttpRequestHelper.throwIfUnauthorized(response.statusCode);
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(responseBody);
        final Map<String, dynamic>? data = decoded is Map<String, dynamic> &&
                decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : (decoded is Map<String, dynamic> ? decoded : null);
        if (data == null) {
          return null;
        }
        return RelatorioCirurgia.fromJson(data);
      }
      if (response.statusCode == 404) {
        return null;
      }
      throw Exception('Erro ao buscar relatório: ${response.statusCode}');
    } finally {
      client.close();
    }
  }

  Future<void> delete(int nummov) async {
    final Map<String, String> query =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/relatorio-cirurgia/$nummov')
        .replace(queryParameters: query);
    final HttpClient client = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await client.deleteUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse response = await request.close();
      await HttpRequestHelper.throwIfUnauthorized(response.statusCode);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw Exception('Erro ao excluir relatório: ${response.statusCode}');
    } finally {
      client.close();
    }
  }
}
