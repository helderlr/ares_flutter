import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../hospital/models/hospital_model.dart';
import '../../hospital/services/hospital_service_paginado.dart';
import '../models/atendimento_consulta_filters.dart';
import '../models/atendimento_consulta_model.dart';
import '../models/atendimento_dashboard_model.dart';
import '../models/atendimento_evolution_model.dart';
import '../models/atendimento_mapa_model.dart';

class AtendimentoAnalyticsService {
  Future<AtendimentoDashboardData> fetchDashboard({
    DateTime? referenceMonth,
  }) async {
    try {
      final Map<String, String> params = <String, String>{};
      _applyMonthParams(params, referenceMonth);
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
      throw Exception(formatUserError(error));
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
      throw Exception(formatUserError(error));
    }
  }

  Future<AtendimentoEvolutionData> fetchEvolution({
    required AtendimentoConsultaGroupBy groupBy,
    DateTime? referenceMonth,
    int topN = 5,
    int monthsBack = 6,
  }) async {
    try {
      final Map<String, String> params = <String, String>{
        'groupBy': groupBy.apiValue,
        'topN': topN.toString(),
        'monthsBack': monthsBack.toString(),
      };
      _applyMonthParams(params, referenceMonth);
      final dynamic decoded = await _getJson(
        '/menu/agenda-cirurgia/charts/evolution',
        params,
      );
      return AtendimentoEvolutionData.fromJson(
        decoded as Map<String, dynamic>,
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception(formatUserError(error));
    }
  }

  Future<AtendimentoCirurgiaMapaData> fetchCirurgiaMapa({
    DateTime? referenceDay,
  }) async {
    try {
      final Map<String, String> params = <String, String>{};
      if (referenceDay != null) {
        _applyDayParams(params, referenceDay);
      }
      final dynamic decoded = await _getJson(
        '/menu/agenda-cirurgia/charts/mapa',
        params,
      );
      return AtendimentoCirurgiaMapaData.fromJson(
        decoded as Map<String, dynamic>,
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      try {
        return await _fetchCirurgiaMapaFallback(referenceDay);
      } catch (_) {
        throw Exception(formatUserError(error));
      }
    }
  }

  Future<AtendimentoCirurgiaMapaData> _fetchCirurgiaMapaFallback(
    DateTime? referenceDay,
  ) async {
    final DateTime ref = referenceDay ?? DateTime.now();
    final AtendimentoConsultaFilters filters = AtendimentoConsultaFilters(
      dateFrom: DateTime(ref.year, ref.month, ref.day),
      dateTo: DateTime(ref.year, ref.month, ref.day),
      groupBy: AtendimentoConsultaGroupBy.hospital,
    );
    final AtendimentoConsultaData consultas = await fetchConsultas(filters);
    final HospitalServicePaginado hospitalService = HospitalServicePaginado();
    final HospitalPaginatedResponse hospitalsResponse =
        await hospitalService.fetchHospitaisPaginated(
      page: 1,
      pageSize: 500,
    );
    final Map<int, Hospital> hospitalsById = <int, Hospital>{
      for (final Hospital hospital in hospitalsResponse.hospitais)
        hospital.codcli: hospital,
    };
    final List<AtendimentoMapaHospital> hospitais = consultas.items
        .map((AtendimentoConsultaItem item) {
          final Hospital? hospital =
              item.id != null ? hospitalsById[item.id!] : null;
          return AtendimentoMapaHospital(
            codcli: item.id,
            nome: item.nome,
            endereco: hospital?.address ?? '',
            bairro: hospital?.bairroFormatado,
            cidade: hospital?.cidadeFormatada,
            estado: hospital?.estadoFormatado,
            cep: hospital?.cepFormatado,
            total: item.qtd,
          );
        })
        .toList();
    return AtendimentoCirurgiaMapaData(hospitais: hospitais);
  }

  String formatUserError(Object error) {
    final String message = error is Exception
        ? error.toString().replaceFirst('Exception: ', '')
        : error.toString();
    if (message.contains('HTTP 404') || message.contains('<!DOCTYPE html>')) {
      return 'Recurso não disponível no servidor. '
          'Atualize a API no Coolify e tente novamente.';
    }
    if (message.contains('empresaId inválido') ||
        message.contains('empresaId invalido')) {
      return 'Sessão da empresa inválida. Saia e faça login novamente.';
    }
    if (message.length > 180) {
      return '${message.substring(0, 180)}...';
    }
    return message;
  }

  void _applyMonthParams(
    Map<String, String> params,
    DateTime? referenceMonth,
  ) {
    if (referenceMonth == null) {
      return;
    }
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

  void _applyDayParams(
    Map<String, String> params,
    DateTime referenceDay,
  ) {
    final String iso = _formatIsoDate(referenceDay);
    params['dateFrom'] = iso;
    params['dateTo'] = iso;
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
}
