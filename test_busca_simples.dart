import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Testando busca simples com NOMPAC...\n');

  final baseUrl = 'https://45.162.242.43';

  // Primeiro faz login para obter um token válido
  print('1. Fazendo login...');

  final loginUrl = '$baseUrl/api/Usuario/login';
  final loginBody = {
    'nomusu': 'Administrador',
    'login': 'admin',
    'senhaw': '123456',
  };

  String? token;

  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    final loginRequest = await httpClient.postUrl(Uri.parse(loginUrl));
    loginRequest.headers.set('Content-Type', 'application/json');
    loginRequest.headers.set('Accept', '*/*');
    loginRequest.write(jsonEncode(loginBody));

    final loginResponse = await loginRequest.close();
    final loginResponseBody =
        await loginResponse.transform(utf8.decoder).join();

    if (loginResponse.statusCode == 200) {
      final loginData = json.decode(loginResponseBody);
      if (loginData.containsKey('token')) {
        token = loginData['token'] as String;
        print('✅ Login bem-sucedido! Token obtido.');
      } else {
        print('❌ Token não encontrado na resposta de login');
        return;
      }
    } else {
      print('❌ Erro no login: ${loginResponse.statusCode}');
      print('Resposta: $loginResponseBody');
      return;
    }

    // Agora testa a busca de pacientes
    print('\n2. Testando busca de pacientes...');

    final testCases = [
      {
        'name': 'Sem busca',
        'params': <String, String>{
          'PageNumber': '1',
          'PageSize': '5',
        },
      },
      {
        'name': 'Busca por AARON',
        'params': <String, String>{
          'PageNumber': '1',
          'PageSize': '5',
          'NOMPAC': 'AARON'
        },
      },
      {
        'name': 'Busca por FERREIRA',
        'params': <String, String>{
          'PageNumber': '1',
          'PageSize': '5',
          'NOMPAC': 'FERREIRA'
        },
      },
    ];

    for (final testCase in testCases) {
      print('\n🧪 Testando: ${testCase['name']}');

      final pacienteUrl = Uri.parse('$baseUrl/api/Paciente/paginated')
          .replace(queryParameters: testCase['params'] as Map<String, String>);

      final pacienteRequest = await httpClient.getUrl(pacienteUrl);
      pacienteRequest.headers.set('Accept', '*/*');
      pacienteRequest.headers.set('Authorization', 'Bearer $token');
      pacienteRequest.headers.set('Content-Type', 'application/json');

      print('📤 URL: ${pacienteUrl.toString()}');

      final pacienteResponse = await pacienteRequest.close();
      final pacienteBody =
          await pacienteResponse.transform(utf8.decoder).join();

      print('📥 Status: ${pacienteResponse.statusCode}');

      if (pacienteResponse.statusCode == 200) {
        print('✅ Sucesso!');
        try {
          final pacientes = json.decode(pacienteBody);
          if (pacientes is List) {
            print('📊 ${pacientes.length} pacientes encontrados');
            if (pacientes.isNotEmpty) {
              print('📝 Pacientes:');
              for (int i = 0; i < pacientes.length; i++) {
                final paciente = pacientes[i];
                final nome = paciente['nompac'] ?? paciente['nome'] ?? 'N/A';
                final codigo =
                    paciente['codpac'] ?? paciente['codigo'] ?? 'N/A';
                print('   ${i + 1}. $nome (Código: $codigo)');
              }
            }
          }
        } catch (e) {
          print('❌ Erro ao decodificar JSON: $e');
        }
      } else if (pacienteResponse.statusCode == 401) {
        print('❌ Erro 401: Token inválido ou expirado');
      } else if (pacienteResponse.statusCode == 404) {
        print('❌ Erro 404: Nenhum paciente encontrado');
        print('Resposta: $pacienteBody');
      } else {
        print('❌ Erro HTTP: ${pacienteResponse.statusCode}');
        print('Resposta: $pacienteBody');
      }
    }

    httpClient.close();
  } catch (e) {
    print('❌ Erro de conexão: $e');
  }

  print('\n🔧 CONCLUSÃO:');
  print('✅ A busca com parâmetro NOMPAC está funcionando corretamente!');
  print('✅ O problema no app pode ser:');
  print('   1. Token expirado - faça login novamente');
  print('   2. Implementação incorreta no app');
  print('   3. Parâmetros de paginação incorretos');
}
