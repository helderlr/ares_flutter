import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🔍 Testando token do app...\n');

  // Simula o processo de login do app
  print('1. Simulando login...');

  final baseUrl = 'https://45.162.242.43';
  final url = '$baseUrl/api/Usuario/login';

  final requestBody = {
    'nomusu': 'Administrador',
    'login': 'admin',
    'senhaw': '123456',
  };

  print('📤 Enviando requisição de login...');
  print('URL: $url');
  print('Body: ${jsonEncode(requestBody)}');

  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    final request = await httpClient.postUrl(Uri.parse(url));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', '*/*');
    request.write(jsonEncode(requestBody));

    final httpResponse = await request.close();
    final responseBody = await httpResponse.transform(utf8.decoder).join();

    print('📥 Status: ${httpResponse.statusCode}');

    if (httpResponse.statusCode == 200) {
      print('✅ Login bem-sucedido!');

      final data = json.decode(responseBody);
      if (data.containsKey('token')) {
        final token = data['token'] as String;
        print('✅ Token obtido: ${token.substring(0, 50)}...');

        // Simula o salvamento do token como no app
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        print('✅ Token salvo no SharedPreferences');

        // Testa a recuperação do token
        final savedToken = prefs.getString('jwt_token');
        print('✅ Token recuperado: ${savedToken?.substring(0, 50)}...');

        // Testa a API de pacientes com o token do app
        print('\n2. Testando API de pacientes com token do app...');

        final pacienteUrl =
            '$baseUrl/api/Paciente/paginated?PageNumber=1&PageSize=5&NOMPAC=AARON';
        final pacienteRequest = await httpClient.getUrl(Uri.parse(pacienteUrl));

        pacienteRequest.headers.set('Accept', '*/*');
        pacienteRequest.headers.set('Authorization', 'Bearer $savedToken');
        pacienteRequest.headers.set('Content-Type', 'application/json');

        print('📤 URL: $pacienteUrl');

        final pacienteResponse = await pacienteRequest.close();
        final pacienteBody =
            await pacienteResponse.transform(utf8.decoder).join();

        print('📥 Status: ${pacienteResponse.statusCode}');

        if (pacienteResponse.statusCode == 200) {
          print('✅ API de pacientes funcionando com token do app!');
          try {
            final pacientes = json.decode(pacienteBody);
            if (pacientes is List) {
              print('📊 ${pacientes.length} pacientes encontrados');
              if (pacientes.isNotEmpty) {
                print('📝 Primeiros pacientes:');
                for (int i = 0;
                    i < (pacientes.length > 3 ? 3 : pacientes.length);
                    i++) {
                  final paciente = pacientes[i];
                  final nome = paciente['nompac'] ?? paciente['nome'] ?? 'N/A';
                  print('   ${i + 1}. $nome');
                }
              }
            }
          } catch (e) {
            print('❌ Erro ao decodificar JSON: $e');
          }
        } else if (pacienteResponse.statusCode == 401) {
          print('❌ Erro 401: Token inválido ou expirado');
          print('💡 DICA: O token pode ter expirado, faça login novamente');
        } else {
          print('❌ Erro HTTP: ${pacienteResponse.statusCode}');
          print('Resposta: $pacienteBody');
        }
      } else {
        print('❌ Token não encontrado na resposta');
        print('Resposta: $responseBody');
      }
    } else {
      print('❌ Erro no login: ${httpResponse.statusCode}');
      print('Resposta: $responseBody');
    }

    httpClient.close();
  } catch (e) {
    print('❌ Erro de conexão: $e');
  }

  print('\n🔧 PRÓXIMOS PASSOS:');
  print(
      '1. Se o login funcionou mas a API de pacientes não, o token pode estar expirado');
  print(
      '2. Se ambos funcionaram, o problema pode estar na implementação do app');
  print('3. Execute o app e faça login para obter um token válido');
  print('4. Teste a busca de pacientes no app');
}
