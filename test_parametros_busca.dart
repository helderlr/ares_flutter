import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Testando diferentes parâmetros de busca...\n');

  final baseUrl = 'https://45.162.242.43';

  // Testa diferentes parâmetros de busca
  final testCases = [
    {
      'name': 'Parâmetro "Nome"',
      'params': <String, String>{'page': '1', 'pageSize': '3', 'Nome': 'jose'},
    },
    {
      'name': 'Parâmetro "nome" (minúsculo)',
      'params': <String, String>{'page': '1', 'pageSize': '3', 'nome': 'jose'},
    },
    {
      'name': 'Parâmetro "NOMPAC"',
      'params': <String, String>{
        'page': '1',
        'pageSize': '3',
        'NOMPAC': 'jose'
      },
    },
    {
      'name': 'Parâmetro "nompac" (minúsculo)',
      'params': <String, String>{
        'page': '1',
        'pageSize': '3',
        'nompac': 'jose'
      },
    },
    {
      'name': 'Parâmetro "search"',
      'params': <String, String>{
        'page': '1',
        'pageSize': '3',
        'search': 'jose'
      },
    },
    {
      'name': 'Parâmetro "q" (query)',
      'params': <String, String>{'page': '1', 'pageSize': '3', 'q': 'jose'},
    },
    {
      'name': 'Parâmetro "term"',
      'params': <String, String>{'page': '1', 'pageSize': '3', 'term': 'jose'},
    },
    {
      'name': 'Parâmetro "filter"',
      'params': <String, String>{
        'page': '1',
        'pageSize': '3',
        'filter': 'jose'
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

      final uri = Uri.parse('$baseUrl/api/Paciente/paginated')
          .replace(queryParameters: testCase['params'] as Map<String, String>);
      final request = await httpClient.getUrl(uri);

      request.headers.set('Accept', '*/*');
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');

      print('📤 URL: ${uri.toString()}');

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
              print('📝 Primeiros 2 pacientes:');
              for (int i = 0; i < (data.length > 2 ? 2 : data.length); i++) {
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
                print('📝 Primeiros 2 pacientes:');
                for (int i = 0;
                    i < (patients.length > 2 ? 2 : patients.length);
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
  print(
      '1. Se todos retornam os mesmos pacientes, a busca não está funcionando');
  print('2. Se algum retorna resultados diferentes, esse parâmetro funciona');
  print('3. Se alguns retornam erro 400/404, esses parâmetros não existem');
}
