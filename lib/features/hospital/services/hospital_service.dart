import 'dart:convert';
import 'dart:io';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../login/services/auth_service.dart';

class HospitalService {
  Future<Map<String, dynamic>> createHospital({
    required String nome,
    String? endereco,
    String? telefone,
    String? nomeFantasia,
    String? cnpj,
    String? cpf,
    String? bairro,
    String? cidade,
    String? cep,
    String? complemento,
    String? estado,
  }) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final int? codusu = await AuthService.getCurrentCodusu();
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/cliente');
    final Map<String, dynamic> requestBody = {
      'empresaId': empresaId,
      'nomcli': nome.toUpperCase(),
      'clihos': 'S',
      if (codusu != null) 'cod_usu': codusu,
      if (nomeFantasia != null && nomeFantasia.isNotEmpty)
        'nomfan': nomeFantasia.toUpperCase(),
      if (endereco != null && endereco.isNotEmpty) 'endcli': endereco,
      if (telefone != null && telefone.isNotEmpty) 'f01cli': telefone,
      if (cnpj != null && cnpj.isNotEmpty) 'cgccli': cnpj,
      if (cpf != null && cpf.isNotEmpty) 'cpfcli': cpf,
      if (bairro != null && bairro.isNotEmpty) 'baicli': bairro,
      if (cidade != null && cidade.isNotEmpty) 'cidcli': cidade,
      if (cep != null && cep.isNotEmpty) 'cepcli': cep,
      if (complemento != null && complemento.isNotEmpty) 'comple': complemento,
      if (estado != null && estado.isNotEmpty) 'estcli': estado,
    };
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.postUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(requestBody));
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 201 || httpResponse.statusCode == 200) {
        try {
          return HttpRequestHelper.decodeResponse(responseBody)
              as Map<String, dynamic>;
        } catch (_) {
          return {'success': true, 'message': 'Cliente/Hospital criado com sucesso'};
        }
      } else if (httpResponse.statusCode == 400) {
        throw Exception('Dados inválidos: $responseBody');
      } else {
        throw Exception(
          'Erro ao criar cliente/hospital: ${httpResponse.statusCode} - $responseBody',
        );
      }
    } finally {
      httpClient.close();
    }
  }

  Future<void> updateHospital({
    required int codcli,
    required String nome,
    String? endereco,
    String? telefone,
    String? nomeFantasia,
    String? cnpj,
    String? cpf,
    String? bairro,
    String? cidade,
    String? cep,
    String? complemento,
    String? estado,
  }) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'empresaId': empresaId,
      'codcli': codcli,
      'nomcli': nome.toUpperCase(),
      'clihos': 'S',
    };
    if (nomeFantasia != null && nomeFantasia.isNotEmpty) {
      requestBody['nomfan'] = nomeFantasia;
    }
    if (endereco != null && endereco.isNotEmpty) {
      requestBody['endcli'] = endereco;
    }
    if (telefone != null && telefone.isNotEmpty) {
      requestBody['f01cli'] = telefone;
    }
    if (cnpj != null && cnpj.isNotEmpty) {
      requestBody['cgccli'] = cnpj;
    }
    if (cpf != null && cpf.isNotEmpty) {
      requestBody['cpfcli'] = cpf;
    }
    if (bairro != null && bairro.isNotEmpty) {
      requestBody['baicli'] = bairro;
    }
    if (cidade != null && cidade.isNotEmpty) {
      requestBody['cidcli'] = cidade;
    }
    if (cep != null && cep.isNotEmpty) {
      requestBody['cepcli'] = cep;
    }
    if (complemento != null && complemento.isNotEmpty) {
      requestBody['comple'] = complemento;
    }
    if (estado != null && estado.isNotEmpty) {
      requestBody['estcli'] = estado;
    }
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/cliente/$codcli');
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.patchUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(requestBody));
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 204 ||
          httpResponse.statusCode == 200) {
        return;
      } else if (httpResponse.statusCode == 400) {
        throw Exception('Dados inválidos: $responseBody');
      } else if (httpResponse.statusCode == 404) {
        throw Exception('Cliente/Hospital não encontrado.');
      } else {
        throw Exception('Erro desconhecido: ${httpResponse.statusCode}');
      }
    } finally {
      httpClient.close();
    }
  }

  Future<bool> deleteHospital(int id) async {
    final Map<String, String> paramsWithEmpresa =
        await HttpRequestHelper.withEmpresaId({});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/cliente/$id')
        .replace(queryParameters: paramsWithEmpresa);
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.deleteUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 204 ||
          httpResponse.statusCode == 200) {
        return true;
      } else if (httpResponse.statusCode == 404) {
        throw Exception('Cliente/Hospital não encontrado');
      } else {
        throw Exception(
          'Erro ao remover cliente/hospital: ${httpResponse.statusCode} - $responseBody',
        );
      }
    } finally {
      httpClient.close();
    }
  }
}
