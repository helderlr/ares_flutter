import 'dart:convert';
import 'dart:io';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';

class PacienteService {
  Future<Map<String, dynamic>> createPaciente({
    required String nome,
    required String dataNascimento,
  }) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final int? codusu = await AuthService.getCurrentCodusu();
    final url = '${ApiConfig.apiUrl}/menu/paciente';
    final dataISO = dataNascimento.contains('/')
        ? convertDateToISO(dataNascimento)
        : dataNascimento;
    final requestBody = {
      'empresaId': empresaId,
      'nompac': nome,
      'datnas': dataISO,
      if (codusu != null) 'cod_usu': codusu,
    };

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.postUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(requestBody));

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      if (httpResponse.statusCode == 201) {
        print('✅ Paciente criado com sucesso na API!');
        try {
          final data = json.decode(responseBody);
          return data;
        } catch (e) {
          return {'success': true, 'message': 'Paciente criado com sucesso'};
        }
      } else if (httpResponse.statusCode == 400) {
        throw Exception('Dados inválidos: $responseBody');
      } else if (httpResponse.statusCode == 500) {
        throw Exception('Erro interno do servidor: $responseBody');
      } else {
        throw Exception(
            'Erro ao criar paciente: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  /// Atualiza um paciente existente na API
  Future<void> updatePaciente({
    required int codpac,
    required String nome,
    String? dataNascimento,
  }) async {
    print('🔄 Atualizando paciente:');
    print('   Codpac: $codpac');
    print('   Nome: $nome');
    print('   Data: $dataNascimento');

    // Converter data para ISO se fornecida
    String? dataISO;
    if (dataNascimento != null && dataNascimento.isNotEmpty) {
      try {
        dataISO = convertDateToISO(dataNascimento);
        print('   Data convertida para ISO: $dataISO');
      } catch (e) {
        print('❌ Erro ao converter data: $e');
        throw Exception('Erro na data de nascimento: $e');
      }
    }

    // Enviar apenas os campos aceitos pela API: nompac e datnas (minúsculo)
    final requestBody = <String, dynamic>{
      'nompac': nome.toUpperCase(),
    };

    // Adicionar data apenas se fornecida
    if (dataISO != null && dataISO.isNotEmpty) {
      requestBody['datnas'] = dataISO;
    }

    // Adicionar carteira se fornecida (se a API aceitar)
    // final carteira = _carteiraController.text.trim();
    // if (carteira.isNotEmpty) {
    //   requestBody['carteira'] = carteira;
    // }

    print('   Request body: $requestBody');

    final url = '${ApiConfig.apiUrl}/menu/paciente/$codpac';

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
        print('✅ Paciente atualizado com sucesso!');
      } else if (httpResponse.statusCode == 400) {
        print('❌ Erro 400 - Bad Request');
        print('   Response body: $responseBody');
        print('   Status code: ${httpResponse.statusCode}');
        print('   Request body enviado: $requestBody');

        // Tentar extrair mensagem de erro mais específica
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
              // Se houver erros de validação específicos
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

        // Adicionar contexto sobre o que foi enviado
        errorMessage += ' (Enviado: $requestBody)';
        throw Exception(errorMessage);
      } else if (httpResponse.statusCode == 401) {
        await AuthService.handleSessionExpired();
        throw const UnauthorizedException();
      } else if (httpResponse.statusCode == 404) {
        print('❌ Erro 404 - Paciente não encontrado');
        throw Exception('Paciente não encontrado.');
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

      // Se for uma exceção de rede, dar uma mensagem mais amigável
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

  /// Busca um paciente por ID na API
  Future<Map<String, dynamic>?> getPacienteById(int id) async {

    final url = '${ApiConfig.apiUrl}/menu/paciente/$id';

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
        return null; // Paciente não encontrado
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else {
        throw Exception(
            'Erro ao buscar paciente: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  /// Lista todos os pacientes da API
  Future<List<Map<String, dynamic>>> getAllPacientes() async {

    final url = '${ApiConfig.apiUrl}/menu/paciente/list_paciente';

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      if (httpResponse.statusCode == 200) {
        try {
          final data = json.decode(responseBody);
          if (data is List) {
            return data.cast<Map<String, dynamic>>();
          } else {
            throw Exception('Formato de resposta inesperado da API');
          }
        } catch (e) {
          throw Exception('Resposta inválida da API: $e');
        }
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else {
        throw Exception(
            'Erro ao listar pacientes: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  /// Busca pacientes por nome na API
  Future<List<Map<String, dynamic>>> searchPacientes(String nome) async {

    final url = '${ApiConfig.apiUrl}/menu/paciente/busca_paciente/$nome';

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      if (httpResponse.statusCode == 200) {
        try {
          final data = json.decode(responseBody);
          if (data is List) {
            return data.cast<Map<String, dynamic>>();
          } else {
            throw Exception('Formato de resposta inesperado da API');
          }
        } catch (e) {
          throw Exception('Resposta inválida da API: $e');
        }
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else {
        throw Exception(
            'Erro ao buscar pacientes: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  /// Lista pacientes com paginação
  Future<Map<String, dynamic>> getPacientesPaginados({
    required int pageNumber,
    required int pageSize,
    String? orderBy,
    String? nomeFiltro,
  }) async {

    final queryParams = <String, String>{
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };

    if (orderBy != null) {
      queryParams['OrderBy'] = orderBy;
    }

    if (nomeFiltro != null) {
      queryParams['NOMPAC'] = nomeFiltro;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final url = '${ApiConfig.apiUrl}/menu/paciente/paginated?$queryString';

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
        return {
          'items': [],
          'totalCount': 0,
          'pageNumber': pageNumber,
          'pageSize': pageSize
        };
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else {
        throw Exception(
            'Erro ao buscar pacientes paginados: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  /// Remove um paciente da API
  Future<bool> deletePaciente(int id) async {

    final url = '${ApiConfig.apiUrl}/menu/paciente/delete_paciente/$id';

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.deleteUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      if (httpResponse.statusCode == 204) {
        print('✅ Paciente removido com sucesso da API!');
        return true;
      } else if (httpResponse.statusCode == 404) {
        throw Exception('Paciente não encontrado');
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else if (httpResponse.statusCode == 500) {
        throw Exception('Erro interno do servidor: $responseBody');
      } else {
        throw Exception(
            'Erro ao remover paciente: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  /// Converte data do formato brasileiro (dd/mm/aaaa) para ISO (aaaa-mm-dd)
  String convertDateToISO(String dataBR) {
    if (dataBR.isEmpty) return '';

    try {
      final parts = dataBR.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        // Validar se a data é válida
        final date = DateTime(year, month, day);
        if (date.year != year || date.month != month || date.day != day) {
          print('⚠️ Data inválida: $dataBR');
          throw Exception('Data inválida: $dataBR');
        }

        // Validar ranges
        if (day < 1 ||
            day > 31 ||
            month < 1 ||
            month > 12 ||
            year < 1900 ||
            year > DateTime.now().year) {
          print('⚠️ Data fora do range válido: $dataBR');
          throw Exception('Data fora do range válido: $dataBR');
        }

        // Verificar se não é futura
        if (date.isAfter(DateTime.now())) {
          print('⚠️ Data futura não permitida: $dataBR');
          throw Exception('Data futura não permitida: $dataBR');
        }

        final dayStr = day.toString().padLeft(2, '0');
        final monthStr = month.toString().padLeft(2, '0');
        final yearStr = year.toString();

        final result = '$yearStr-$monthStr-$dayStr';
        print('✅ Data convertida: $dataBR -> $result');
        return result;
      } else {
        print('⚠️ Formato de data inválido: $dataBR (esperado: dd/mm/aaaa)');
        throw Exception(
            'Formato de data inválido: $dataBR (esperado: dd/mm/aaaa)');
      }
    } catch (e) {
      if (e.toString().contains('Data')) {
        rethrow;
      }
      print('❌ Erro ao converter data $dataBR: $e');
      throw Exception('Erro ao converter data: $e');
    }
  }

  /// Converte data do formato ISO (aaaa-mm-dd) para brasileiro (dd/mm/aaaa)
  String convertDateToBR(String dataISO) {
    if (dataISO.isEmpty) return '';

    try {
      if (dataISO.contains('T')) {
        dataISO = dataISO.split('T')[0]; // Remove parte do tempo se existir
      }

      final parts = dataISO.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = parts[1];
        final day = parts[2];
        return '$day/$month/$year';
      }
    } catch (e) {
      print('Erro ao converter data: $e');
    }
    return dataISO; // Retorna original se não conseguir converter
  }
}
