import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/paginated_api_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../models/medico_model.dart';
import 'especialidade_service.dart';

class MedicoServicePaginado {
  final EspecialidadeService _especialidadeService = EspecialidadeService();

  Future<MedicoPaginatedResponse> fetchMedicosPaginated({
    int page = 1,
    int pageSize = 50,
    String sortBy = 'nommed',
    String sortOrder = 'asc',
    String? searchQuery,
  }) async {
    try {
      final PaginatedApiDecoded decoded = await PaginatedApiHelper.fetchPage(
        menuPath: '/menu/medico',
        queryParams: PaginatedApiHelper.buildListQuery(
          page: page,
          pageSize: pageSize,
          sortBy: sortBy,
          sortOrder: sortOrder,
          search: searchQuery,
        ),
      );
      final List<Medico> medicos = await _enrichEspecialidades(
        decoded.data
            .map(
              (dynamic item) =>
                  Medico.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
      return MedicoPaginatedResponse(
        medicos: medicos,
        pagination: MedicoPaginationInfo.fromJson(decoded.pagination),
      );
    } on UnauthorizedException {
      rethrow;
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  Future<MedicoPaginatedResponse> fetchNextPage(
    MedicoPaginationInfo currentPagination, {
    String sortBy = 'nommed',
    String sortOrder = 'asc',
    String? searchQuery,
  }) async {
    if (!currentPagination.hasNextPage) {
      throw Exception('Não há próxima página disponível');
    }
    return fetchMedicosPaginated(
      page: currentPagination.currentPage + 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<Medico?> getMedicoById(int id) async {
    final Map<String, String> paramsWithEmpresa =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/medico/$id')
        .replace(queryParameters: paramsWithEmpresa);
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 404) {
        return null;
      }
      if (httpResponse.statusCode == 401) {
        throw const UnauthorizedException();
      }
      if (httpResponse.statusCode != 200) {
        throw Exception(
          'Erro na API: ${httpResponse.statusCode} - $responseBody',
        );
      }
      final dynamic data = HttpRequestHelper.decodeResponse(responseBody);
      if (data is! Map<String, dynamic>) {
        return null;
      }
      final List<Medico> medicos = await _enrichEspecialidades(
        <Medico>[Medico.fromJson(data)],
      );
      return medicos.isEmpty ? null : medicos.first;
    } finally {
      httpClient.close();
    }
  }

  Future<List<Medico>> _enrichEspecialidades(List<Medico> medicos) async {
    if (medicos.isEmpty) {
      return medicos;
    }
    try {
      final Map<int, String> especialidadeMap =
          await _especialidadeService.getCachedMap();
      return medicos
          .map((Medico medico) {
            if (medico.especialidade != null &&
                medico.especialidade!.isNotEmpty) {
              return medico;
            }
            final String? nome = especialidadeMap[medico.codesp];
            return medico.withEspecialidadeNome(nome);
          })
          .toList();
    } catch (_) {
      return medicos;
    }
  }

  void clearCache() {}
}
