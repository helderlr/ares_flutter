import 'dart:convert';
import 'dart:io';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';

class ConvenioService {
  Future<Map<String, dynamic>> createConvenio({
    required String nome,
    String? cnpj,
    String? endereco,
    String? telefone,
  }) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final int? codusu = await AuthService.getCurrentCodusu();
    final url = '${ApiConfig.apiUrl}/menu/convenio';
    final requestBody = {
      'empresaId': empresaId,
      'nomcon': nome,
      if (codusu != null) 'cod_usu': codusu,
      if (cnpj != null && cnpj.isNotEmpty) 'cnpjcon': cnpj,
      if (endereco != null && endereco.isNotEmpty) 'endcon': endereco,
      if (telefone != null && telefone.isNotEmpty) 'fonecon': telefone,
    };

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.postUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(requestBody));

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      if (httpResponse.statusCode == 201) {
        print('✅ Convênio criado com sucesso na API!');
        try {
          final data = json.decode(responseBody);
          return data;
        } catch (e) {
          return {'success': true, 'message': 'Convênio criado com sucesso'};
        }
      } else if (httpResponse.statusCode == 400) {
        throw Exception('Dados inválidos: $responseBody');
      } else if (httpResponse.statusCode == 500) {
        throw Exception('Erro interno do servidor: $responseBody');
      } else {
        throw Exception(
            'Erro ao criar convênio: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  Future<void> updateConvenio({
    required int codcon,
    required String nome,
    String? cnpj,
    String? endereco,
    String? telefone,
  }) async {
    print('🔄 Atualizando convênio:');
    print('   Codcon: $codcon');
    print('   Nome: $nome');
    print('   CNPJ: $cnpj');
    print('   Endereço: $endereco');
    print('   Telefone: $telefone');

    final requestBody = <String, dynamic>{
      'codcon': codcon,
      'nomcon': nome.toUpperCase(),
    };

    if (cnpj != null && cnpj.isNotEmpty) {
      requestBody['cnpjcon'] = cnpj;
    }
    if (endereco != null && endereco.isNotEmpty) {
      requestBody['endcon'] = endereco;
    }
    if (telefone != null && telefone.isNotEmpty) {
      requestBody['fonecon'] = telefone;
    }

    print('   Request body: $requestBody');

    final url = '${ApiConfig.apiUrl}/menu/convenio/$codcon';

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.putUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);

      print('   Headers configurados');
      print('   Enviando requisição...');

      request.write(jsonEncode(requestBody));

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('   Response body: $responseBody');
      print('   Status code: ${httpResponse.statusCode}');

      if (httpResponse.statusCode == 204) {
        print('✅ Convênio atualizado com sucesso!');
      } else if (httpResponse.statusCode == 400) {
        print('❌ Erro 400 - Bad Request');
        print('   Response body: $responseBody');
        print('   Status code: ${httpResponse.statusCode}');
        print('   Request body enviado: $requestBody');

        String errorMessage = 'Dados inválidos';
        if (responseBody.isNotEmpty) {
          try {
            final errorData = jsonDecode(responseBody);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            } else if (errorData['error'] != null) {
              errorMessage = errorData['error'];
            } else if (errorData['title'] != null) {
              errorMessage = errorData['title'];
            } else if (errorData['errors'] != null) {
              final errors = errorData['errors'] as Map<String, dynamic>?;
              if (errors != null && errors.isNotEmpty) {
                final errorList =
                    errors.values.map((e) => e.toString()).join(', ');
                errorMessage = 'Erros de validação: $errorList';
              }
            }
          } catch (e) {
            print('   Não foi possível decodificar a resposta de erro: $e');
          }
        }

        errorMessage += ' (Enviado: $requestBody)';
        throw Exception(errorMessage);
      } else if (httpResponse.statusCode == 401) {
        await AuthService.handleSessionExpired();
        throw const UnauthorizedException();
      } else if (httpResponse.statusCode == 404) {
        print('❌ Erro 404 - Convênio não encontrado');
        throw Exception('Convênio não encontrado.');
      } else if (httpResponse.statusCode == 500) {
        print('❌ Erro 500 - Erro interno do servidor');
        throw Exception(
            'Erro interno do servidor. Tente novamente mais tarde.');
      } else {
        print('❌ Erro desconhecido: ${httpResponse.statusCode}');
        throw Exception('Erro desconhecido: ${httpResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Exceção durante atualização: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
            'Erro de conexão. Verifique sua internet e tente novamente.');
      }

      rethrow;
    } finally {
      httpClient.close();
    }
  }

  Future<Map<String, dynamic>?> getConvenioById(int id) async {

    final url = '${ApiConfig.apiUrl}/menu/convenio/$id';

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      if (httpResponse.statusCode == 200) {
        try {
          final data = json.decode(responseBody);
          return data;
        } catch (e) {
          throw Exception('Resposta inválida da API: $e');
        }
      } else if (httpResponse.statusCode == 404) {
        return null;
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else {
        throw Exception(
            'Erro ao buscar convênio: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  Future<bool> deleteConvenio(int id) async {
    print('🗑️ Iniciando exclusão do convênio ID: $id');

    final url = '${ApiConfig.apiUrl}/menu/convenio/delete_convenio/$id';
    print('🔗 URL: $url');

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.deleteUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);

      print('📤 Enviando requisição DELETE...');

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('📥 Resposta recebida:');
      print('   Status: ${httpResponse.statusCode}');
      print('   Body: $responseBody');

      if (httpResponse.statusCode == 204) {
        print('✅ Convênio removido com sucesso da API!');
        return true;
      } else if (httpResponse.statusCode == 404) {
        print('❌ Convênio não encontrado (404)');
        throw Exception('Convênio não encontrado');
      } else if (httpResponse.statusCode == 401) {
        print('❌ Token inválido ou expirado (401)');
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else if (httpResponse.statusCode == 500) {
        print('❌ Erro interno do servidor (500)');
        print('   Resposta completa: $responseBody');
        throw Exception(
            'Erro interno do servidor. Pode haver relacionamentos no banco de dados.');
      } else {
        print('❌ Erro inesperado: ${httpResponse.statusCode}');
        throw Exception(
            'Erro ao remover convênio: ${httpResponse.statusCode} - $responseBody');
      }
    } catch (e) {
      print('❌ Exceção durante exclusão: $e');
      rethrow;
    } finally {
      httpClient.close();
    }
  }
}





























