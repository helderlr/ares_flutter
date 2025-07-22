import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testando conectividade da API...');

  // Testa se o Swagger está acessível
  print('\n1. Testando acesso ao Swagger...');
  try {
    final swaggerResponse = await http
        .get(
          Uri.parse('http://45.162.242.43:3051/swagger/index.html'),
        )
        .timeout(const Duration(seconds: 10));

    print('Swagger Status: ${swaggerResponse.statusCode}');
    if (swaggerResponse.statusCode == 200) {
      print('✅ Swagger está acessível');
    } else {
      print(
          '❌ Swagger não está acessível - Status: ${swaggerResponse.statusCode}');
    }
  } catch (e) {
    print('❌ Erro ao acessar Swagger: $e');
  }

  // Lista de URLs para tentar (HTTP e HTTPS com diferentes endpoints)
  final urls = [
    'http://45.162.242.43:3051/api/Usuario',
    'http://45.162.242.43:3051/api/Usuario/login',
    'http://45.162.242.43:3051/api/usuario',
    'http://45.162.242.43:3051/api/usuario/login',
    'http://45.162.242.43:3051/Usuario',
    'http://45.162.242.43:3051/usuario',
    'https://45.162.242.43/api/Usuario',
    'https://45.162.242.43/api/Usuario/login',
    'https://45.162.242.43/api/usuario',
    'https://45.162.242.43/api/usuario/login',
    'https://45.162.242.43/Usuario',
    'https://45.162.242.43/usuario',
  ];

  print('\n2. Testando login na API...');
  print('Método: POST');
  print(
      'Body: {"nomusu": "Administrador", "login": "Administrador", "senha": "adm\$10"}');

  String? workingUrl;

  for (String url in urls) {
    print('\n--- Testando: $url ---');

    try {
      if (url.startsWith('https://')) {
        // Para HTTPS, usa HttpClient customizado
        final httpClient = HttpClient()
          ..badCertificateCallback = (cert, host, port) => true;

        final request = await httpClient.postUrl(Uri.parse(url));
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Accept', '*/*');
        request.write(jsonEncode({
          'nomusu': 'Administrador',
          'login': 'Administrador',
          'senha': 'adm\$10',
        }));

        final httpResponse = await request.close();
        final responseBody = await httpResponse.transform(utf8.decoder).join();

        print('Status: ${httpResponse.statusCode}');

        if (httpResponse.statusCode == 200) {
          print('✅ Login realizado com sucesso!');
          workingUrl = url;

          final data = json.decode(responseBody);
          print('Resposta: $data');

          if (data.containsKey('token') && data.containsKey('user')) {
            print('✅ Estrutura da resposta correta');

            final token = data['token'] as String;
            final user = data['user'] as Map<String, dynamic>;

            if (token.isNotEmpty) {
              print('✅ Token encontrado: ${token.substring(0, 20)}...');
              print('✅ Usuário: ${user['login']} (ID: ${user['codusu']})');
              print('✅ Admin: ${user['admsis']}');
              print('✅ Login funcionando perfeitamente!');
            } else {
              print('❌ Token vazio');
            }
          } else {
            print('❌ Estrutura da resposta incorreta');
            print('Esperado: campos "token" e "user"');
            print('Encontrado: ${data.keys.toList()}');
          }

          httpClient.close();
          break;
        } else {
          print('❌ Erro: ${httpResponse.statusCode}');
          if (responseBody.isNotEmpty) {
            print('Resposta: $responseBody');
          }
        }

        httpClient.close();
      } else {
        // Para HTTP, usa o cliente normal
        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': '*/*',
              },
              body: jsonEncode({
                'nomusu': 'Administrador',
                'login': 'Administrador',
                'senha': 'adm\$10',
              }),
            )
            .timeout(const Duration(seconds: 10));

        print('Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          print('✅ Login realizado com sucesso!');
          workingUrl = url;

          final data = json.decode(response.body);
          print('Resposta: $data');

          if (data.containsKey('token') && data.containsKey('user')) {
            print('✅ Estrutura da resposta correta');

            final token = data['token'] as String;
            final user = data['user'] as Map<String, dynamic>;

            if (token.isNotEmpty) {
              print('✅ Token encontrado: ${token.substring(0, 20)}...');
              print('✅ Usuário: ${user['login']} (ID: ${user['codusu']})');
              print('✅ Admin: ${user['admsis']}');
              print('✅ Login funcionando perfeitamente!');
            } else {
              print('❌ Token vazio');
            }
          } else {
            print('❌ Estrutura da resposta incorreta');
            print('Esperado: campos "token" e "user"');
            print('Encontrado: ${data.keys.toList()}');
          }

          break;
        } else if (response.statusCode == 307 || response.statusCode == 302) {
          print('⚠️ Redirecionamento detectado');
          final location = response.headers['location'];
          if (location != null) {
            print('Location: $location');
          }
          // Continua para a próxima URL
        } else {
          print('❌ Erro: ${response.statusCode}');
          if (response.body.isNotEmpty) {
            print('Resposta: ${response.body}');
          }
        }
      }
    } catch (e) {
      print('❌ Erro de conexão: $e');
    }
  }

  print('\n📋 RESUMO:');
  if (workingUrl != null) {
    print('✅ URL funcionando: $workingUrl');
    print('✅ O login deve funcionar no app Flutter');
    print('✅ Credenciais: Administrador / adm\$10');
  } else {
    print('❌ Nenhuma URL funcionou');
    print('❌ Verifique se a API está rodando e acessível');
    print('❌ Verifique se a URL está correta');
    print('❌ Verifique se há firewall ou proxy bloqueando');
  }

  print('\n🔧 PRÓXIMOS PASSOS:');
  print('1. Se o teste passou, o login no app Flutter deve funcionar');
  print('2. Execute: flutter run');
  print('3. Use as credenciais: Administrador / adm\$10');
  print('4. Se houver problemas, verifique os logs do app');
}
