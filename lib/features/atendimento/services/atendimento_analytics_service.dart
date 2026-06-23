import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../models/atendimento_consulta_filters.dart';
import '../models/atendimento_consulta_model.dart';
import '../models/atendimento_dashboard_model.dart';

class AtendimentoAnalyticsService {
  Future<AtendimentoDashboardData> fetchDashboard({
    DateTime? referenceMonth,
  }) async {
    try {
      final Map<String, String> params = <String, String>{};
      if (referenceMonth != null) {
        final DateTime start = DateTime(
          referenceMonth.year,
          referenceMonth.month,
          1,
        );
        final DateTime end = DateTime(
          referenceMonth.year,
          referenceMonth.month + 1,
          0,
        );
        params['dateFrom'] = _formatIsoDate(start);
        params['dateTo'] = _formatIsoDate(end);
      }
      final dynamic decoded = await _getJson(
        '/menu/agenda-cirurgia/dashboard',
        params,
      );
      return AtendimentoDashboardData.fromJson(
        decoded as Map<String, dynamic>,
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception(_formatError(error));
    }
  }

  Future<AtendimentoConsultaData> fetchConsultas(
    AtendimentoConsultaFilters filters,
  ) async {
    try {
      final dynamic decoded = await _getJson(
        '/menu/agenda-cirurgia/consultas',
        filters.toQueryParams(),
      );
      return AtendimentoConsultaData.fromJson(
        decoded as Map<String, dynamic>,
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception(_formatError(error));
    }
  }

  Future<dynamic> _getJson(
    String menuPath,
    Map<String, String> queryParams,
  ) async {
    final Map<String, String> params =
        await HttpRequestHelper.withEmpresaId(queryParams);
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}$menuPath')
        .replace(queryParameters: params);
    final HttpClient client = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await client.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();
      await HttpRequestHelper.throwIfUnauthorized(response.statusCode);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: $body');
      }
      return HttpRequestHelper.decodeResponse(body);
    } finally {
      client.close(force: true);
    }
  }

  static String _formatIsoDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatError(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }
}
