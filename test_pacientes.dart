import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Testando API de Pacientes...\n');

  final baseUrl = 'https://45.162.242.43';
  final url = '$baseUrl/api/Paciente/list_paciente';

  print('URL: $url\n');

  // Simula o token JWT (você pode substituir por um token real se tiver)
  final token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IkFkbWluaXN0cmFkb3IiLCJyb2xlIjoiUyIsIm5iZiI6MTc1Mjk3NTczMywiZXhwIjoxNzUyOTgyOTMzLCJpYXQiOjE3NTI5NzU3MzN9.kP97q0fWhdI3JJxIEXe3tH9LoMoapze9TWOYe0-_XfM';

  print('🔑 Usando token de teste...');

  try {
    // Para HTTPS, usa HttpClient customizado para aceitar certificados auto-assinados
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        print('🔒 Aceitando certificado auto-assinado para $host:$port');
        return true;
      };

    final request = await httpClient.getUrl(Uri.parse(url));
    request.headers.set('Accept', '*/*');
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Content-Type', 'application/json');

    print('📤 Enviando requisição com token...');

    final httpResponse = await request.close();
    final responseBody = await httpResponse.transform(utf8.decoder).join();

    print('📥 Resposta recebida:');
    print('Status: ${httpResponse.statusCode}');
    print('Headers: ${httpResponse.headers}');

    if (httpResponse.statusCode == 200) {
      print('✅ Sucesso! Status 200');

      try {
        final List<dynamic> data = json.decode(responseBody);
        print('✅ Dados JSON válidos');
        print('📊 Total de pacientes: ${data.length}');

        if (data.isNotEmpty) {
          print('\n📋 Primeiro paciente:');
          print('Dados: ${data.first}');

          // Testa o parsing do primeiro paciente
          try {
            final paciente = {
              'codigo': data.first['codigo'],
              'nome': data.first['nome'],
              'dataNascimento': data.first['dataNascimento'],
              'carteira': data.first['carteira'],
            };
            print('✅ Estrutura do paciente válida');
            print('Nome: ${paciente['nome']}');
            print('Código: ${paciente['codigo']}');
            print('Data Nascimento: ${paciente['dataNascimento']}');
            print('Carteira: ${paciente['carteira']}');
          } catch (e) {
            print('❌ Erro ao processar dados do paciente: $e');
          }
        } else {
          print('⚠️ Lista de pacientes vazia');
        }

        print('\n✅ API de pacientes funcionando perfeitamente!');
      } catch (e) {
        print('❌ Erro ao decodificar JSON: $e');
        print(
            'Resposta: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...');
      }
    } else if (httpResponse.statusCode == 401) {
      print('❌ Erro 401: Token inválido ou expirado');
      print('Resposta: $responseBody');
      print(
          '\n💡 DICA: O token pode ter expirado. Faça login novamente no app para obter um novo token.');
    } else {
      print('❌ Erro HTTP: ${httpResponse.statusCode}');
      print('Resposta: $responseBody');
    }

    httpClient.close();
  } catch (e) {
    print('❌ Erro de conexão: $e');
  }

  print('\n🔧 PRÓXIMOS PASSOS:');
  print('1. Se o teste passou, a API de pacientes deve funcionar no app');
  print('2. Execute: flutter run');
  print('3. Faça login primeiro para obter o token JWT');
  print('4. Navegue para a tela de pacientes');
  print('5. Se houver problemas, verifique os logs do app');
}
