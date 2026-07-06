import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';
import '../models/performance_activity_model.dart';
import '../models/performance_comparativo_model.dart';
import '../models/performance_desempenho_model.dart';
import '../models/performance_evolution_model.dart';
import '../models/performance_frequency_model.dart';
import '../models/performance_home_model.dart';
import '../models/performance_medal_model.dart';
import '../models/performance_metas_model.dart';
import '../models/performance_ranking_model.dart';
import '../utils/performance_formatters.dart';
import 'performance_api_paths.dart';
import 'performance_mock_data.dart';

class PerformanceOperacionalService {
  Future<int?> _resolveCodusu(int? codusu) async {
    if (codusu != null) {
      return codusu;
    }
    return AuthService.getCurrentCodusu();
  }

  Future<PerformanceHomeData> fetchHome({
    DateTime? referenceMonth,
    int? codusu,
  }) async {
    try {
      final Map<String, String> params = await _buildMonthParams(referenceMonth);
      await _applyCodusu(params, codusu);
      final dynamic decoded = await _getJson(PerformanceApiPaths.home, params);
      return PerformanceHomeData.fromJson(decoded as Map<String, dynamic>);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      final String? userName = await AuthService.getUserName();
      return PerformanceMockData.buildHomeData(
        userName: _firstName(userName ?? 'Usuário'),
      );
    }
  }

  Future<PerformanceRankingData> fetchRanking({
    DateTime? referenceMonth,
    String? search,
    int limit = 100,
  }) async {
    try {
      final Map<String, String> params = await _buildMonthParams(referenceMonth);
      params['limit'] = limit.toString();
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      final dynamic decoded = await _getJson(PerformanceApiPaths.ranking, params);
      return PerformanceRankingData.fromJson(decoded as Map<String, dynamic>);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      return PerformanceMockData.buildRankingData();
    }
  }

  Future<PerformanceDesempenhoData> fetchDesempenho({
    int? codusu,
    DateTime? referenceMonth,
  }) async {
    try {
      final Map<String, String> params = await _buildMonthParams(referenceMonth);
      await _applyCodusu(params, codusu);
      final dynamic decoded = await _getJson(PerformanceApiPaths.desempenho, params);
      return PerformanceDesempenhoData.fromJson(decoded as Map<String, dynamic>);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      final int? currentCodusu = await AuthService.getCurrentCodusu();
      final String? userName = await AuthService.getUserName();
      return PerformanceMockData.buildDesempenhoData(
        codusu: codusu ?? currentCodusu ?? 1,
        nome: userName ?? 'Usuário',
      );
    }
  }

  Future<PerformanceEvolutionData> fetchEvolution({
    required PerformanceEvolutionPeriod period,
    int? codusu,
    DateTime? referenceMonth,
  }) async {
    try {
      final Map<String, String> params = await _buildMonthParams(referenceMonth);
      params['period'] = period.apiValue;
      await _applyCodusu(params, codusu);
      final dynamic decoded = await _getJson(PerformanceApiPaths.evolution, params);
      return PerformanceEvolutionData.fromJson(decoded as Map<String, dynamic>);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      return PerformanceMockData.buildEvolutionData(period);
    }
  }

  Future<PerformanceMedalhasData> fetchMedalhas({
    int? codusu,
    DateTime? referenceMonth,
  }) async {
    try {
      final Map<String, String> params = await _buildMonthParams(referenceMonth);
      await _applyCodusu(params, codusu);
      final dynamic decoded = await _getJson(PerformanceApiPaths.medalhas, params);
      return PerformanceMedalhasData.fromJson(decoded as Map<String, dynamic>);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      return PerformanceMockData.buildMedalhasData();
    }
  }

  Future<PerformanceHorasData> fetchHoras({
    DateTime? referenceDay,
    int? codusu,
  }) async {
    try {
      final Map<String, String> params = <String, String>{};
      if (referenceDay != null) {
        params['date'] = PerformanceFormatters.formatIsoDate(referenceDay);
      }
      final Map<String, String> withEmpresa =
          await HttpRequestHelper.withEmpresaId(params);
      await _applyCodusu(withEmpresa, codusu);
      final dynamic decoded = await _getJson(PerformanceApiPaths.horas, withEmpresa);
      return PerformanceHorasData.fromJson(decoded as Map<String, dynamic>);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      return PerformanceMockData.buildHorasData();
    }
  }

  Future<PerformanceFrequenciaData> fetchFrequencia({
    DateTime? referenceMonth,
    int? codusu,
  }) async {
    try {
      final Map<String, String> params = await _buildMonthParams(referenceMonth);
      await _applyCodusu(params, codusu);
      final dynamic decoded = await _getJson(PerformanceApiPaths.frequencia, params);
      return PerformanceFrequenciaData.fromJson(decoded as Map<String, dynamic>);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      return PerformanceMockData.buildFrequenciaData();
    }
  }

  Future<PerformanceAtividadesData> fetchAtividades({
    int? codusu,
    int limit = 50,
  }) async {
    try {
      final Map<String, String> params = <String, String>{
        'limit': limit.toString(),
      };
      final Map<String, String> withEmpresa =
          await HttpRequestHelper.withEmpresaId(params);
      await _applyCodusu(withEmpresa, codusu);
      final dynamic decoded =
          await _getJson(PerformanceApiPaths.atividades, withEmpresa);
      return PerformanceAtividadesData.fromJson(decoded as Map<String, dynamic>);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      return PerformanceMockData.buildAtividadesData();
    }
  }

  Future<PerformanceGestorData> fetchGestorDashboard({
    DateTime? referenceMonth,
  }) async {
    try {
      final Map<String, String> params = await _buildMonthParams(referenceMonth);
      final dynamic decoded = await _getJson(PerformanceApiPaths.gestor, params);
      return PerformanceGestorData.fromJson(decoded as Map<String, dynamic>);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      return PerformanceMockData.buildGestorData();
    }
  }

  Future<PerformanceMetasData> fetchMetas({
    DateTime? referenceMonth,
    int? codusu,
  }) async {
    try {
      final Map<String, String> params = await _buildMonthParams(referenceMonth);
      await _applyCodusu(params, codusu);
      final dynamic decoded = await _getJson(PerformanceApiPaths.metas, params);
      return PerformanceMetasData.fromJson(decoded as Map<String, dynamic>);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      final PerformanceHomeData home = PerformanceMockData.buildHomeData();
      final PerformanceDesempenhoData desempenho = PerformanceMockData.buildDesempenhoData();
      return PerformanceMetasData(
        goalTarget: home.goalTarget,
        goalCurrent: home.goalCurrent,
        goalPercent: home.goalPercent,
        score: home.score,
        scorePercent: home.scorePercent,
        starCount: home.starCount,
        dailyAverage: desempenho.daysWorked > 0
            ? desempenho.totalOperations ~/ desempenho.daysWorked
            : 0,
        operationsByType: desempenho.operations
            .map(
              (PerformanceOperationCount op) => PerformanceMetasOperation(
                operacao: op.operacao,
                count: op.count,
                percent: op.percent,
              ),
            )
            .toList(),
      );
    }
  }

  Future<PerformanceComparativoData> fetchComparativo({
    required int codusuB,
    int? codusu,
    DateTime? referenceMonth,
  }) async {
    try {
      final Map<String, String> params = await _buildMonthParams(referenceMonth);
      final int? codusuA = await _resolveCodusu(codusu);
      if (codusuA == null) {
        throw Exception('codusu não encontrado');
      }
      params['codusu'] = codusuA.toString();
      params['codusuB'] = codusuB.toString();
      final dynamic decoded = await _getJson(PerformanceApiPaths.comparativo, params);
      return PerformanceComparativoData.fromJson(decoded as Map<String, dynamic>);
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      return PerformanceMockData.buildComparativoData(codusuB: codusuB);
    }
  }

  Future<void> _applyCodusu(Map<String, String> params, int? codusu) async {
    final int? resolved = await _resolveCodusu(codusu);
    if (resolved != null) {
      params['codusu'] = resolved.toString();
    }
  }

  Future<Map<String, String>> _buildMonthParams(DateTime? referenceMonth) async {
    final Map<String, String> params = <String, String>{};
    if (referenceMonth != null) {
      final DateTime start = DateTime(referenceMonth.year, referenceMonth.month, 1);
      final DateTime end = DateTime(referenceMonth.year, referenceMonth.month + 1, 0);
      params['dateFrom'] = PerformanceFormatters.formatIsoDate(start);
      params['dateTo'] = PerformanceFormatters.formatIsoDate(end);
    }
    return HttpRequestHelper.withEmpresaId(params);
  }

  Future<dynamic> _getJson(
    String menuPath,
    Map<String, String> queryParams,
  ) async {
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}$menuPath')
        .replace(queryParameters: queryParams);
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

  String _firstName(String fullName) {
    final List<String> parts = fullName.trim().split(' ');
    if (parts.isEmpty) {
      return fullName;
    }
    return parts.first;
  }
}
