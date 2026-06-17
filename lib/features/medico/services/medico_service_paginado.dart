import 'dart:convert';
import 'dart:io';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';
import '../models/medico_model.dart';
import 'especialidade_service.dart';

class MedicoServicePaginado {
  final EspecialidadeService _especialidadeService = EspecialidadeService();

  /// Busca médicos com paginação
  Future<MedicoPaginatedResponse> fetchMedicosPaginated({
    int page = 1,
    int pageSize = 50,
    String sortBy = 'nommed',
    String sortOrder = 'asc',
    String? searchQuery,
  }) async {
    print('🔍 Buscando médicos - Página: $page, Tamanho: $pageSize');
    print('📊 Ordenação: $sortBy $sortOrder');
    if (searchQuery != null && searchQuery.isNotEmpty) {
      print('🔎 Termo de busca: "$searchQuery"');
    }

    final Map<String, String> queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
    };
    final Map<String, String> paramsWithEmpresa =
        await HttpRequestHelper.withEmpresaId(queryParams);
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/medico')
        .replace(queryParameters: paramsWithEmpresa);
    print('🌐 URL: $uri');
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      print('📥 Status: ${httpResponse.statusCode}');
      if (httpResponse.statusCode == 200) {
        try {
          final dynamic decoded = HttpRequestHelper.decodeResponse(responseBody);
          final List<dynamic> data = decoded is List
              ? decoded
              : (decoded is Map<String, dynamic> && decoded['data'] is List
                  ? decoded['data'] as List<dynamic>
                  : []);
          print('✅ Dados recebidos: ${data.length} médicos');

          // Simular paginação se a API não retornar info de paginação
          final totalRecords = data.length;
          final totalPages = (totalRecords / pageSize).ceil();

          final List<Medico> medicos = await _enrichEspecialidades(
            data
                .map((dynamic item) =>
                    Medico.fromJson(item as Map<String, dynamic>))
                .toList(),
          );

          final pagination = MedicoPaginationInfo(
            currentPage: page,
            pageSize: pageSize,
            totalRecords: totalRecords,
            totalPages: totalPages,
            hasNextPage: page < totalPages,
            hasPreviousPage: page > 1,
          );

          return MedicoPaginatedResponse(
            medicos: medicos,
            pagination: pagination,
          );
        } catch (e) {
          print('❌ Erro ao decodificar JSON: $e');
          throw Exception('Erro ao processar resposta da API: $e');
        }
      } else if (httpResponse.statusCode == 404) {
        print('⚠️ Nenhum médico encontrado');
        return MedicoPaginatedResponse(
          medicos: [],
          pagination: MedicoPaginationInfo(
            currentPage: page,
            pageSize: pageSize,
            totalRecords: 0,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        );
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else {
        print('❌ Erro HTTP: ${httpResponse.statusCode}');
        print('📄 Response body: $responseBody');
        throw Exception(
            'Erro na API: ${httpResponse.statusCode} - $responseBody');
      }
    } catch (e) {
      print('❌ Exceção: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  /// Busca próxima página
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

  /// Busca médico por ID
  Future<Medico?> getMedicoById(int id) async {
    print('🔍 Buscando médico por ID: $id');
    final Map<String, String> paramsWithEmpresa =
        await HttpRequestHelper.withEmpresaId({});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/medico/$id')
        .replace(queryParameters: paramsWithEmpresa);
    print('🌐 URL: $uri');
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      print('📥 Status: ${httpResponse.statusCode}');
      if (httpResponse.statusCode == 200) {
        try {
          final dynamic data = HttpRequestHelper.decodeResponse(responseBody);
          print('✅ Médico encontrado');
          final Medico medico = Medico.fromJson(data as Map<String, dynamic>);
          final List<Medico> enriched =
              await _enrichEspecialidades(<Medico>[medico]);
          return enriched.first;
        } catch (e) {
          print('❌ Erro ao decodificar JSON: $e');
          throw Exception('Erro ao processar resposta da API: $e');
        }
      } else if (httpResponse.statusCode == 404) {
        print('⚠️ Médico não encontrado');
        return null;
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Sessão inválida. Faça login novamente.');
      } else {
        print('❌ Erro HTTP: ${httpResponse.statusCode}');
        throw Exception(
            'Erro na API: ${httpResponse.statusCode} - $responseBody');
      }
    } catch (e) {
      print('❌ Exceção: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
      rethrow;
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
            if (medico.especialidade != null && medico.especialidade!.isNotEmpty) {
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
}
