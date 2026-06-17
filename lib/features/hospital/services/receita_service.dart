import 'dart:convert';
import 'dart:io';

class ReceitaService {
  // API principal da Receita Federal
  static const String baseUrl = 'https://receitaws.com.br/v1';
  // API alternativa (backup)
  static const String backupUrl = 'https://brasilapi.com.br/api/cnpj/v1';

  /// Busca dados de uma empresa pelo CNPJ
  /// Retorna os dados da Receita Federal ou null se não encontrar
  Future<Map<String, dynamic>?> buscarPorCnpj(String cnpj) async {
    // Remove caracteres especiais do CNPJ
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^\d]'), '');

    if (cnpjLimpo.length != 14) {
      throw Exception('CNPJ deve ter 14 dígitos');
    }

    print('🔍 Buscando CNPJ: $cnpjLimpo');

    // Tentar primeiro com a API principal
    try {
      print('   📡 Tentando API principal...');
      final dados = await _buscarNaApiPrincipal(cnpjLimpo);
      if (dados != null) {
        print('   ✅ Dados encontrados na API principal');
        return dados;
      }
    } catch (e) {
      print('   ❌ Erro na API principal: $e');
    }

    // Se falhar, tentar com a API alternativa
    try {
      print('   📡 Tentando API alternativa...');
      final dados = await _buscarNaApiAlternativa(cnpjLimpo);
      if (dados != null) {
        print('   ✅ Dados encontrados na API alternativa');
        return dados;
      }
    } catch (e) {
      print('   ❌ Erro na API alternativa: $e');
    }

    print('   ❌ Nenhuma API retornou dados');
    return null;
  }

  /// Busca na API principal da Receita
  Future<Map<String, dynamic>?> _buscarNaApiPrincipal(String cnpj) async {
    final url = '$baseUrl/$cnpj';

    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      request.headers.set('Accept', 'application/json');
      request.headers.set('User-Agent', 'AresFlutter/1.0');

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('   📥 Status: ${httpResponse.statusCode}');
      print(
          '   📥 Response: ${responseBody.substring(0, responseBody.length > 100 ? 100 : responseBody.length)}...');

      if (httpResponse.statusCode == 200) {
        try {
          final data = json.decode(responseBody);

          // Verifica se a resposta contém dados válidos
          if (data['status'] == 'ERROR') {
            throw Exception(data['message'] ?? 'Erro ao buscar CNPJ');
          }

          return data;
        } catch (e) {
          throw Exception('Resposta inválida da API: $e');
        }
      } else if (httpResponse.statusCode == 404) {
        return null; // CNPJ não encontrado
      } else if (httpResponse.statusCode == 429) {
        throw Exception(
            'Limite de requisições excedido. Tente novamente em alguns minutos.');
      } else {
        throw Exception(
            'Erro ao buscar CNPJ: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  /// Busca na API alternativa (Brasil API)
  Future<Map<String, dynamic>?> _buscarNaApiAlternativa(String cnpj) async {
    final url = '$backupUrl/$cnpj';

    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      request.headers.set('Accept', 'application/json');
      request.headers.set('User-Agent', 'AresFlutter/1.0');

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('   📥 Status: ${httpResponse.statusCode}');
      print(
          '   📥 Response: ${responseBody.substring(0, responseBody.length > 100 ? 100 : responseBody.length)}...');

      if (httpResponse.statusCode == 200) {
        try {
          final data = json.decode(responseBody);

          // Converter formato da Brasil API para o formato padrão
          return _converterFormatoBrasilApi(data);
        } catch (e) {
          throw Exception('Resposta inválida da API alternativa: $e');
        }
      } else if (httpResponse.statusCode == 404) {
        return null; // CNPJ não encontrado
      } else {
        throw Exception(
            'Erro na API alternativa: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  /// Converte formato da Brasil API para o formato padrão
  Map<String, dynamic> _converterFormatoBrasilApi(Map<String, dynamic> data) {
    return {
      'nome': data['razao_social'] ?? '',
      'fantasia': data['nome_fantasia'] ?? '',
      'logradouro': data['logradouro'] ?? '',
      'numero': data['numero'] ?? '',
      'complemento': data['complemento'] ?? '',
      'bairro': data['bairro'] ?? '',
      'municipio': data['municipio'] ?? '',
      'uf': data['uf'] ?? '',
      'cep': data['cep'] ?? '',
      'telefone': data['ddd_telefone'] != null && data['telefone'] != null
          ? '(${data['ddd_telefone']}) ${data['telefone']}'
          : '',
      'email': data['email'] ?? '',
      'situacao': data['situacao_cadastral'] ?? '',
      'abertura': data['data_inicio_atividade'] ?? '',
      'porte': data['porte'] ?? '',
      'natureza_juridica': data['natureza_juridica'] ?? '',
    };
  }

  /// Valida formato do CNPJ
  bool validarFormatoCnpj(String cnpj) {
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    return cnpjLimpo.length == 14;
  }

  /// Formata CNPJ para exibição (XX.XXX.XXX/XXXX-XX)
  String formatarCnpj(String cnpj) {
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^\d]'), '');

    if (cnpjLimpo.length != 14) return cnpj;

    return '${cnpjLimpo.substring(0, 2)}.${cnpjLimpo.substring(2, 5)}.${cnpjLimpo.substring(5, 8)}/${cnpjLimpo.substring(8, 12)}-${cnpjLimpo.substring(12)}';
  }

  /// Extrai dados relevantes da resposta da Receita
  Map<String, String> extrairDadosRelevantes(
      Map<String, dynamic> dadosReceita) {
    return {
      'nome': dadosReceita['nome'] ?? '',
      'fantasia': dadosReceita['fantasia'] ?? '',
      'logradouro': dadosReceita['logradouro'] ?? '',
      'numero': dadosReceita['numero'] ?? '',
      'complemento': dadosReceita['complemento'] ?? '',
      'bairro': dadosReceita['bairro'] ?? '',
      'municipio': dadosReceita['municipio'] ?? '',
      'uf': dadosReceita['uf'] ?? '',
      'cep': dadosReceita['cep'] ?? '',
      'telefone': dadosReceita['telefone'] ?? '',
      'email': dadosReceita['email'] ?? '',
      'situacao': dadosReceita['situacao'] ?? '',
      'data_abertura': dadosReceita['abertura'] ?? '',
      'porte': dadosReceita['porte'] ?? '',
      'natureza_juridica': dadosReceita['natureza_juridica'] ?? '',
    };
  }
}
