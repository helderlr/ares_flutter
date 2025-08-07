import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Testando busca de pacientes - DEBUG\n');

  final baseUrl = 'https://45.162.242.43';

  // Testa diferentes cenários de busca
  final testCases = <Map<String, dynamic>>[
    {
      'name': 'Busca vazia (sem parâmetro)',
      'url': '$baseUrl/api/Paciente/paginated',
      'params': <String, String>{'page': '1', 'pageSize': '5'},
    },
    {
      'name': 'Busca por "jose"',
      'url': '$baseUrl/api/Paciente/paginated',
      'params': <String, String>{'page': '1', 'pageSize': '5', 'Nome': 'jose'},
    },
    {
      'name': 'Busca por "maria"',
      'url': '$baseUrl/api/Paciente/paginated',
      'params': <String, String>{'page': '1', 'pageSize': '5', 'Nome': 'maria'},
    },
    {
      'name': 'Busca por "silva"',
      'url': '$baseUrl/api/Paciente/paginated',
      'params': <String, String>{'page': '1', 'pageSize': '5', 'Nome': 'silva'},
    },
    {
      'name': 'Busca por termo inexistente "xyz123"',
      'url': '$baseUrl/api/Paciente/paginated',
      'params': <String, String>{
        'page': '1',
        'pageSize': '5',
        'Nome': 'xyz123'
      },
    },
  ];

  // Token JWT de teste
  final token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IkFkbWluaXN0cmFkb3IiLCJyb2xlIjoiUyIsIm5iZiI6MTc1Mjk3NTczMywiZXhwIjoxNzUyOTgyOTMzLCJpYXQiOjE3NTI5NzU3MzN9.kP97q0fWhdI3JJxIEXe3tH9LoMoapze9TWOYe0-_XfM';

  print('🔑 Usando token de teste...\n');

  for (final testCase in testCases) {
    print('🧪 Testando: ${testCase['name']}');

    try {
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;

      final uri = Uri.parse(testCase['url']!)
          .replace(queryParameters: testCase['params'] as Map<String, String>);
      final request = await httpClient.getUrl(uri);

      request.headers.set('Accept', '*/*');
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');

      print('📤 URL: ${uri.toString()}');
      print('📋 Parâmetros: ${testCase['params']}');

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('📥 Status: ${httpResponse.statusCode}');

      if (httpResponse.statusCode == 200) {
        print('✅ Sucesso!');

        try {
          final data = json.decode(responseBody);

          if (data is List) {
            print('📊 Lista com ${data.length} pacientes');
            if (data.isNotEmpty) {
              print('📝 Primeiros 3 pacientes:');
              for (int i = 0; i < (data.length > 3 ? 3 : data.length); i++) {
                final paciente = data[i];
                final nome = paciente['nompac'] ?? paciente['nome'] ?? 'N/A';
                final codigo =
                    paciente['codpac'] ?? paciente['codigo'] ?? 'N/A';
                print('   ${i + 1}. $nome (Código: $codigo)');
              }
            }
          } else if (data is Map) {
            if (data.containsKey('data') && data.containsKey('pagination')) {
              final patients = data['data'] as List;
              final pagination = data['pagination'];
              print(
                  '📊 Paginado: ${patients.length} pacientes na página ${pagination['currentPage']}');
              if (patients.isNotEmpty) {
                print('📝 Primeiros 3 pacientes:');
                for (int i = 0;
                    i < (patients.length > 3 ? 3 : patients.length);
                    i++) {
                  final paciente = patients[i];
                  final nome = paciente['nompac'] ?? paciente['nome'] ?? 'N/A';
                  final codigo =
                      paciente['codpac'] ?? paciente['codigo'] ?? 'N/A';
                  print('   ${i + 1}. $nome (Código: $codigo)');
                }
              }
            } else {
              print('📊 Objeto com ${data.length} campos');
            }
          }
        } catch (e) {
          print('❌ Erro ao decodificar JSON: $e');
          print(
              'Resposta: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...');
        }
      } else {
        print('❌ Erro HTTP: ${httpResponse.statusCode}');
        print('Resposta: $responseBody');
      }

      httpClient.close();
    } catch (e) {
      print('❌ Erro de conexão: $e');
    }

    print(''); // Linha em branco entre testes
  }

  print('🔧 ANÁLISE DOS RESULTADOS:');
  print('1. Se a busca vazia retorna pacientes, a API está funcionando');
  print(
      '2. Se as buscas específicas retornam resultados filtrados, a busca está funcionando');
  print(
      '3. Se a busca por termo inexistente retorna lista vazia, está correto');
  print('4. Se todos falharam com 401, o token expirou');
  print('5. Se falharam com outros erros, verifique a documentação da API');
}
