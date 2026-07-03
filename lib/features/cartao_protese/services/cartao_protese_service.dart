import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/utils/api_error_formatter.dart';
import '../../agendamento/models/agendamento_model.dart';
import '../../agendamento/services/agendamento_service_paginado.dart';
import '../../login/services/auth_service.dart';
import '../models/cartao_protese_model.dart';
import 'cartao_protese_api_paths.dart';
import 'cartao_protese_service_paginado.dart';

class CartaoProteseService {
  final CartaoProteseServicePaginado _listService = CartaoProteseServicePaginado();
  final AgendamentoServicePaginado _agendaService = AgendamentoServicePaginado();

  Future<CartaoProtese> create(CartaoProtese item) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final int? codusu = await AuthService.getCurrentCodusu();
    final Uri uri = Uri.parse(
      '${ApiConfig.apiUrl}${CartaoProteseApiPaths.listPaths.first}',
    );
    final Map<String, dynamic> body = <String, dynamic>{
      'empresaId': empresaId,
      ...item.toWriteJson(),
      if (codusu != null) 'codusu': codusu,
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
        return _parseSingle(responseBody);
      }
      throw Exception(
        'Erro ao criar cartão prótese: ${response.statusCode}',
      );
    } finally {
      client.close();
    }
  }

  Future<CartaoProtese> update(int nummov, CartaoProtese item) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final Uri uri = Uri.parse(
      '${ApiConfig.apiUrl}${CartaoProteseApiPaths.listPaths.first}/$nummov',
    );
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
        return _parseSingle(responseBody);
      }
      if (response.statusCode == 404) {
        throw Exception('Cartão prótese não encontrado.');
      }
      throw Exception(
        'Erro ao atualizar cartão prótese: ${response.statusCode}',
      );
    } finally {
      client.close();
    }
  }

  Future<CartaoProtese?> getById(int nummov) async {
    final Map<String, String> query =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final Uri uri = Uri.parse(
      '${ApiConfig.apiUrl}${CartaoProteseApiPaths.listPaths.first}/$nummov',
    ).replace(queryParameters: query);
    final HttpClient client = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await client.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      await HttpRequestHelper.throwIfUnauthorized(response.statusCode);
      if (response.statusCode == 404) {
        return null;
      }
      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao buscar cartão prótese: ${response.statusCode}',
        );
      }
      return _parseSingle(responseBody);
    } finally {
      client.close();
    }
  }

  Future<CartaoProtese?> findExistingByPedido(
    int numpedv, {
    int? excludeNummov,
  }) async {
    try {
      return await _listService.findByNumpedv(
        numpedv,
        excludeNummov: excludeNummov,
      );
    } catch (_) {
      return null;
    }
  }

  Future<CartaoProtese?> fetchDadosPorPedido(int numpedv) async {
    final Map<String, String> query =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final List<String> paths = <String>[
      '${CartaoProteseApiPaths.listPaths.first}/pedido/$numpedv',
      '${CartaoProteseApiPaths.listPaths.first}/por-pedido/$numpedv',
      '/menu/pedido/$numpedv',
    ];
    for (final String path in paths) {
      final CartaoProtese? result = await _tryGetCartao(path, query);
      if (result != null) {
        return result;
      }
    }
    return _fetchDadosFromAgenda(numpedv);
  }

  Future<CartaoProtese?> _fetchDadosFromAgenda(int numpedv) async {
    try {
      final response = await _agendaService.fetchAgendamentosPaginated(
        page: 1,
        pageSize: 100,
        searchQuery: numpedv.toString(),
      );
      AgendaCirurgia? match;
      for (final AgendaCirurgia agenda in response.agendamentos) {
        if (agenda.numpedv == numpedv) {
          match = agenda;
          break;
        }
      }
      if (match == null) {
        return null;
      }
      return CartaoProtese(
        nummov: 0,
        numpedv: numpedv,
        datcir: match.datcir,
        codpac: match.codpac,
        codmed: match.codmed,
        codcli: match.codcli,
        codcir: match.codcir,
        nnompac: match.nompac,
        nnommed: match.nommed,
        nnomcli: match.nomcli,
        nomcirTipo: match.tipoCirurgiaDisplay,
        lado: match.lado,
        priRev: match.primrev,
        sistemaAplicado: match.reportMaterialRaw,
      );
    } catch (error) {
      throw Exception(ApiErrorFormatter.format(error));
    }
  }

  Future<CartaoProtese?> _tryGetCartao(
    String path,
    Map<String, String> query,
  ) async {
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}$path')
        .replace(queryParameters: query);
    final HttpClient client = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await client.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      await HttpRequestHelper.throwIfUnauthorized(response.statusCode);
      if (response.statusCode == 404) {
        return null;
      }
      if (response.statusCode != 200) {
        return null;
      }
      return _parseSingle(responseBody);
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  CartaoProtese _parseSingle(String responseBody) {
    final dynamic decoded = json.decode(responseBody);
    final Map<String, dynamic> data = decoded is Map<String, dynamic> &&
            decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : decoded as Map<String, dynamic>;
    return CartaoProtese.fromJson(data);
  }
}
