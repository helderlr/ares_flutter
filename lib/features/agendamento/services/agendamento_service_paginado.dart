import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';
import '../models/agendamento_model.dart';

class AgendamentoServicePaginado {
  List<AgendaCirurgia>? _cachedAgendamentos;

  Future<AgendaCirurgiaPaginatedResponse> fetchAgendamentosPaginated({
    required int page,
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    try {
      final List<AgendaCirurgia> allItems = await _fetchAllAgendamentos();
      List<AgendaCirurgia> filtered = _applySearch(allItems, searchQuery);
      filtered = _applySort(filtered, sortBy, sortOrder);
      final int totalRecords = filtered.length;
      final int totalPages =
          totalRecords == 0 ? 0 : (totalRecords / pageSize).ceil();
      final int safePage = page < 1 ? 1 : page;
      final int startIndex = (safePage - 1) * pageSize;
      final List<AgendaCirurgia> pageItems = startIndex >= totalRecords
          ? <AgendaCirurgia>[]
          : filtered.skip(startIndex).take(pageSize).toList();
      final AgendaCirurgiaPaginationInfo pagination =
          AgendaCirurgiaPaginationInfo(
        currentPage: safePage,
        pageSize: pageSize,
        totalRecords: totalRecords,
        totalPages: totalPages,
        hasNextPage: safePage < totalPages,
        hasPreviousPage: safePage > 1,
      );
      return AgendaCirurgiaPaginatedResponse(
        agendamentos: pageItems,
        pagination: pagination,
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception(_formatError(error));
    }
  }

  Future<List<AgendaCirurgia>> _fetchAllAgendamentos() async {
    if (_cachedAgendamentos != null) {
      return List<AgendaCirurgia>.from(_cachedAgendamentos!);
    }
    final Map<String, String> paramsWithEmpresa =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/agenda-cirurgia')
        .replace(queryParameters: paramsWithEmpresa);
    final HttpClient httpClient = HttpRequestHelper.createClient();
    httpClient.connectionTimeout = const Duration(seconds: 60);
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 200) {
        try {
          final dynamic data = HttpRequestHelper.decodeResponse(responseBody);
          final List<dynamic> rows = data is List
              ? data
              : (data is Map<String, dynamic> && data['data'] is List
                  ? data['data'] as List<dynamic>
                  : <dynamic>[]);
          final List<AgendaCirurgia> agendamentos = rows
              .map(
                (dynamic item) =>
                    AgendaCirurgia.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          _cachedAgendamentos = agendamentos;
          return agendamentos;
        } catch (error) {
          throw Exception(_formatHttpError(httpResponse.statusCode, responseBody));
        }
      }
      if (httpResponse.statusCode == 401) {
        await AuthService.handleSessionExpired();
        throw const UnauthorizedException();
      }
      throw Exception(
        _formatHttpError(httpResponse.statusCode, responseBody),
      );
    } finally {
      httpClient.close();
    }
  }

  List<AgendaCirurgia> _applySearch(
    List<AgendaCirurgia> items,
    String? searchQuery,
  ) {
    if (searchQuery == null || searchQuery.trim().isEmpty) {
      return items;
    }
    final String query = searchQuery.trim().toLowerCase();
    return items
        .where(
          (AgendaCirurgia item) =>
              item.pacienteName.toLowerCase().contains(query),
        )
        .toList();
  }

  List<AgendaCirurgia> _applySort(
    List<AgendaCirurgia> items,
    String? sortBy,
    String? sortOrder,
  ) {
    final List<AgendaCirurgia> sorted = List<AgendaCirurgia>.from(items);
    final bool isDescending = (sortOrder ?? 'desc').toLowerCase() == 'desc';
    int compareDates(AgendaCirurgia a, AgendaCirurgia b) {
      final DateTime dateA = a.datcir ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime dateB = b.datcir ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateA.compareTo(dateB);
    }
    switch (sortBy) {
      case 'patient':
        sorted.sort(
          (AgendaCirurgia a, AgendaCirurgia b) =>
              a.pacienteName.compareTo(b.pacienteName),
        );
        break;
      case 'medico':
        sorted.sort(
          (AgendaCirurgia a, AgendaCirurgia b) =>
              a.medicoName.compareTo(b.medicoName),
        );
        break;
      case 'hospital':
        sorted.sort(
          (AgendaCirurgia a, AgendaCirurgia b) =>
              a.hospitalName.compareTo(b.hospitalName),
        );
        break;
      case 'cirurgia':
        sorted.sort(
          (AgendaCirurgia a, AgendaCirurgia b) =>
              a.cirurgiaName.compareTo(b.cirurgiaName),
        );
        break;
      case 'situacao':
        sorted.sort(
          (AgendaCirurgia a, AgendaCirurgia b) => a.status.compareTo(b.status),
        );
        break;
      case 'date':
      default:
        sorted.sort(compareDates);
        break;
    }
    if (isDescending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  String _formatHttpError(int statusCode, String responseBody) {
    if (statusCode == 502 || responseBody.contains('502')) {
      return 'Servidor da agenda indisponível (502). A consulta usa várias tabelas (paciente, médico, hospital...) e pode falhar quando o servidor está sobrecarregado. Tente novamente em alguns minutos.';
    }
    if (statusCode == 503) {
      return 'Serviço indisponível no momento. Tente novamente mais tarde.';
    }
    if (statusCode >= 500) {
      return 'Erro no servidor ($statusCode). Tente novamente mais tarde.';
    }
    return 'Erro na API ($statusCode)';
  }

  String _formatError(Object error) {
    final String message = error.toString();
    if (message.contains('502')) {
      return 'Servidor temporariamente indisponível (502). Tente novamente em alguns minutos.';
    }
    if (message.contains('503')) {
      return 'Serviço indisponível no momento. Tente novamente mais tarde.';
    }
    if (message.contains('SocketException') ||
        message.contains('HandshakeException') ||
        message.contains('Connection refused')) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    }
    return message.replaceAll('Exception: ', '');
  }

  void clearCache() {
    _cachedAgendamentos = null;
  }

  Future<AgendaCirurgiaPaginatedResponse> fetchNextPage(
    AgendaCirurgiaPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasNextPage) {
      throw Exception('Não há mais páginas para carregar');
    }
    return fetchAgendamentosPaginated(
      page: currentPagination.currentPage + 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<AgendaCirurgiaPaginatedResponse> fetchPreviousPage(
    AgendaCirurgiaPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasPreviousPage) {
      throw Exception('Não há página anterior');
    }
    return fetchAgendamentosPaginated(
      page: currentPagination.currentPage - 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<AgendaCirurgiaPaginatedResponse> fetchPage(
    int page, {
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    return fetchAgendamentosPaginated(
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }
}
