import 'dart:convert';
import 'dart:io';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';

class TipoCirurgiaService {
  Future<Map<String, dynamic>> createTipoCirurgia({
    required String nome,
    String? descricao,
    double? valor,
  }) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final int? codusu = await AuthService.getCurrentCodusu();
    final String url = '${ApiConfig.apiUrl}/menu/tipo-cirurgia';
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'empresaId': empresaId,
      'nomcir': nome,
      if (codusu != null) 'cod_usu': codusu,
      if (descricao != null && descricao.isNotEmpty) 'descir': descricao,
      if (valor != null) 'valcir': valor,
    };

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.postUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(requestBody));

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        print('✅ Tipo de cirurgia criado com sucesso na API!');
        try {
          final data = json.decode(responseBody);
          return data;
        } catch (e) {
          return {
            'success': true,
            'message': 'Tipo de cirurgia criado com sucesso'
          };
        }
      } else if (httpResponse.statusCode == 400) {
        throw Exception('Dados inválidos: $responseBody');
      } else if (httpResponse.statusCode == 500) {
        throw Exception('Erro interno do servidor: $responseBody');
      } else {
        throw Exception(
            'Erro ao criar tipo de cirurgia: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  Future<void> updateTipoCirurgia({
    required int codcir,
    required String nome,
    String? descricao,
    double? valor,
  }) async {
    print('🔄 Atualizando tipo de cirurgia:');
    print('   Codcir: $codcir');
    print('   Nome: $nome');
    print('   Descrição: $descricao');
    print('   Valor: $valor');

    final String empresaId = await AuthService.requireEmpresaId();
    final requestBody = <String, dynamic>{
      'empresaId': empresaId,
      'codcir': codcir,
      'nomcir': nome.toUpperCase(),
    };

    if (descricao != null && descricao.isNotEmpty) {
      requestBody['descir'] = descricao;
    }
    if (valor != null) {
      requestBody['valcir'] = valor;
    }

    print('   Request body: $requestBody');

    final url =
        '${ApiConfig.apiUrl}/menu/tipo-cirurgia/$codcir';

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
        print('✅ Tipo de cirurgia atualizado com sucesso!');
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
        print('❌ Erro 404 - Tipo de cirurgia não encontrado');
        throw Exception('Tipo de cirurgia não encontrado.');
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

  Future<Map<String, dynamic>?> getTipoCirurgiaById(int id) async {
    final Map<String, String> queryParams =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/tipo-cirurgia/$id')
        .replace(queryParameters: queryParams);
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 200) {
        final dynamic decoded = json.decode(responseBody);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return null;
      }
      if (httpResponse.statusCode == 404) {
        return null;
      }
      if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      }
      throw Exception(
        'Erro ao buscar tipo de cirurgia: ${httpResponse.statusCode} - $responseBody',
      );
    } finally {
      httpClient.close();
    }
  }

  Future<bool> deleteTipoCirurgia(int id) async {
    final Map<String, String> queryParams =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/tipo-cirurgia/$id')
        .replace(queryParameters: queryParams);
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.deleteUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 204) {
        return true;
      }
      if (httpResponse.statusCode == 404) {
        throw Exception('Tipo de cirurgia não encontrado');
      }
      if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      }
      throw Exception(
        'Erro ao remover tipo de cirurgia: ${httpResponse.statusCode} - $responseBody',
      );
    } finally {
      httpClient.close();
    }
  }
}
