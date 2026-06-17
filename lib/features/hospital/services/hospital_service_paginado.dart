import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';
import '../models/hospital_model.dart';

class HospitalServicePaginado {
  List<Hospital>? _cachedHospitais;

  Future<HospitalPaginatedResponse> fetchHospitaisPaginated({
    required int page,
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    try {
      final List<Hospital> allHospitais = await _fetchAllHospitais();
      List<Hospital> filtered = allHospitais
          .where((Hospital item) => item.isHospital)
          .toList();
      filtered = _applySearch(filtered, searchQuery);
      filtered = _applySort(filtered, sortBy, sortOrder);
      final int totalRecords = filtered.length;
      final int totalPages =
          totalRecords == 0 ? 0 : (totalRecords / pageSize).ceil();
      final int safePage = page < 1 ? 1 : page;
      final int startIndex = (safePage - 1) * pageSize;
      final List<Hospital> pageItems = startIndex >= totalRecords
          ? <Hospital>[]
          : filtered.skip(startIndex).take(pageSize).toList();
      final HospitalPaginationInfo pagination = HospitalPaginationInfo(
        currentPage: safePage,
        pageSize: pageSize,
        totalRecords: totalRecords,
        totalPages: totalPages,
        hasNextPage: safePage < totalPages,
        hasPreviousPage: safePage > 1,
      );
      return HospitalPaginatedResponse(
        hospitais: pageItems,
        pagination: pagination,
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  Future<List<Hospital>> _fetchAllHospitais() async {
    if (_cachedHospitais != null) {
      return List<Hospital>.from(_cachedHospitais!);
    }
    final Map<String, String> paramsWithEmpresa =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/cliente')
        .replace(queryParameters: paramsWithEmpresa);
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 200) {
        final dynamic data = HttpRequestHelper.decodeResponse(responseBody);
        final List<dynamic> rows = data is List
            ? data
            : (data is Map<String, dynamic> && data['data'] is List
                ? data['data'] as List<dynamic>
                : <dynamic>[]);
        final List<Hospital> hospitais = rows
            .map(
              (dynamic item) =>
                  Hospital.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        _cachedHospitais = hospitais;
        return hospitais;
      }
      if (httpResponse.statusCode == 401) {
        await AuthService.handleSessionExpired();
        throw const UnauthorizedException();
      }
      throw Exception(
        'Erro na API: ${httpResponse.statusCode} - $responseBody',
      );
    } finally {
      httpClient.close();
    }
  }

  List<Hospital> _applySearch(List<Hospital> items, String? searchQuery) {
    if (searchQuery == null || searchQuery.trim().isEmpty) {
      return items;
    }
    final String query = searchQuery.trim().toLowerCase();
    return items
        .where(
          (Hospital item) =>
              item.nomcli.toLowerCase().contains(query) ||
              (item.nomfan ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  List<Hospital> _applySort(
    List<Hospital> items,
    String? sortBy,
    String? sortOrder,
  ) {
    final List<Hospital> sorted = List<Hospital>.from(items);
    final bool isDescending = (sortOrder ?? 'asc').toLowerCase() == 'desc';
    switch (sortBy) {
      case 'id':
        sorted.sort((Hospital a, Hospital b) => a.codcli.compareTo(b.codcli));
        break;
      case 'address':
        sorted.sort(
          (Hospital a, Hospital b) =>
              (a.endcli ?? '').compareTo(b.endcli ?? ''),
        );
        break;
      case 'fantasy':
        sorted.sort(
          (Hospital a, Hospital b) =>
              (a.nomfan ?? '').compareTo(b.nomfan ?? ''),
        );
        break;
      case 'name':
      default:
        sorted.sort(
          (Hospital a, Hospital b) => a.nomcli.compareTo(b.nomcli),
        );
        break;
    }
    if (isDescending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  void clearCache() {
    _cachedHospitais = null;
  }

  Future<HospitalPaginatedResponse> fetchNextPage(
    HospitalPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasNextPage) {
      throw Exception('Não há mais páginas para carregar');
    }
    return fetchHospitaisPaginated(
      page: currentPagination.currentPage + 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<HospitalPaginatedResponse> fetchPreviousPage(
    HospitalPaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasPreviousPage) {
      throw Exception('Não há página anterior');
    }
    return fetchHospitaisPaginated(
      page: currentPagination.currentPage - 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<HospitalPaginatedResponse> fetchPage(
    int page, {
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    return fetchHospitaisPaginated(
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }
}
