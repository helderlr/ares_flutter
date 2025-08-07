import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Testando busca com nomes que existem na base...\n');

  final baseUrl = 'https://45.162.242.43';

  // Testa com nomes que existem na base (baseado no resultado anterior)
  final testCases = [
    {
      'name': 'Sem busca (base de comparação)',
      'params': <String, String>{
        'PageNumber': '1',
        'PageSize': '10',
      },
    },
    {
      'name': 'Com busca NOMPAC=AARON',
      'params': <String, String>{
        'PageNumber': '1',
        'PageSize': '10',
        'NOMPAC': 'AARON'
      },
    },
    {
      'name': 'Com busca NOMPAC=ABDOM',
      'params': <String, String>{
        'PageNumber': '1',
        'PageSize': '10',
        'NOMPAC': 'ABDOM'
      },
    },
    {
      'name': 'Com busca NOMPAC=KEVEN',
      'params': <String, String>{
        'PageNumber': '1',
        'PageSize': '10',
        'NOMPAC': 'KEVEN'
      },
    },
    {
      'name': 'Com busca NOMPAC=FERREIRA',
      'params': <String, String>{
        'PageNumber': '1',
        'PageSize': '10',
        'NOMPAC': 'FERREIRA'
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
              print('📝 Todos os pacientes:');
              for (int i = 0; i < data.length; i++) {
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
                print('📝 Todos os pacientes:');
                for (int i = 0; i < patients.length; i++) {
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
      } else if (httpResponse.statusCode == 401) {
        print('❌ Erro 401: Token inválido ou expirado');
        print('💡 DICA: Faça login no app para obter um token válido');
      } else if (httpResponse.statusCode == 404) {
        print('❌ Erro 404: Nenhum paciente encontrado');
        print('Resposta: $responseBody');
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
  print('1. Se a busca retorna pacientes filtrados, está funcionando');
  print(
      '2. Se todos retornam os mesmos pacientes, a busca não está funcionando');
  print('3. Se retorna 404, pode ser que a busca seja case-sensitive');
  print('4. Se retorna 401, o token expirou - faça login no app');
}
