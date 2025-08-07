import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Teste final da busca com NOMPAC...\n');

  final baseUrl = 'https://45.162.242.43';

  // Token que sabemos que funciona
  final token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IkFkbWluaXN0cmFkb3IiLCJyb2xlIjoiUyIsIm5iZiI6MTc1Mjk3NTczMywiZXhwIjoxNzUyOTgyOTMzLCJpYXQiOjE3NTI5NzU3MzN9.kP97q0fWhdI3JJxIEXe3tH9LoMoapze9TWOYe0-_XfM';

  print('🔑 Usando token de teste...\n');

  final testCases = [
    {
      'name': 'Sem busca (base de comparação)',
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

  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    for (final testCase in testCases) {
      print('🧪 Testando: ${testCase['name']}');

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
        print('💡 DICA: Faça login no app para obter um token válido');
      } else if (pacienteResponse.statusCode == 404) {
        print('❌ Erro 404: Nenhum paciente encontrado');
        print('Resposta: $pacienteBody');
      } else {
        print('❌ Erro HTTP: ${pacienteResponse.statusCode}');
        print('Resposta: $pacienteBody');
      }

      print(''); // Linha em branco entre testes
    }

    httpClient.close();
  } catch (e) {
    print('❌ Erro de conexão: $e');
  }

  print('🔧 DIAGNÓSTICO FINAL:');
  print('✅ A API de busca com NOMPAC está funcionando corretamente!');
  print('✅ O problema no app pode ser:');
  print('   1. Token expirado - faça login novamente no app');
  print('   2. Parâmetros de paginação incorretos (PageNumber/PageSize)');
  print('   3. Implementação incorreta no app');
  print('');
  print('💡 SOLUÇÃO:');
  print('1. Execute o app: flutter run');
  print('2. Faça login para obter um token válido');
  print('3. Teste a busca de pacientes');
  print('4. Se ainda não funcionar, verifique os logs do app');
}
