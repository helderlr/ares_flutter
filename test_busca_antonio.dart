import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Testando busca por "ANTONIO"...\n');

  final baseUrl = 'https://45.162.242.43';

  // Token que sabemos que funciona
  final token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NTQzODg5NzMsImlzcyI6IkFsZ3VtSXNzdWVyIiwiYXVkIjoiQWxndW1hQXVkaWVuY2UifQ.vAM1LsRcmRTIgW7q1PofbSIuv4VJFQW4q6h6BxrBEfc';

  print('🔑 Usando token do app...\n');

  final testCases = [
    {
      'name': 'Sem busca (base de comparação)',
      'params': <String, String>{
        'PageNumber': '1',
        'PageSize': '10',
      },
    },
    {
      'name': 'Busca por ANTONIO',
      'params': <String, String>{
        'PageNumber': '1',
        'PageSize': '10',
        'NOMPAC': 'ANTONIO'
      },
    },
    {
      'name': 'Busca por antonio (minúsculo)',
      'params': <String, String>{
        'PageNumber': '1',
        'PageSize': '10',
        'NOMPAC': 'antonio'
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

  print('🔧 CONCLUSÃO:');
  print('1. Se a busca por ANTONIO retorna pacientes, a busca funciona');
  print('2. Se retorna 404, pode ser que não existam pacientes com esse nome');
  print('3. Se retorna 401, o token expirou');
}
