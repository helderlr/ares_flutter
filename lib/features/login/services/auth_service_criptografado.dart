// ✅ HABILITADO - API implementada com criptografia AES
// Este serviço de autenticação criptografada está funcionando com a API
// que espera o campo 'senhaw' já criptografado.
//
// Parâmetros de criptografia:
// - Chave: ARES_FLUTTER_2025
// - Algoritmo: AES-256-CBC
// - IV: 16 bytes com zeros (compatível com Delphi)

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/encryption_service.dart';
import '../models/user_model.dart';

class AuthServiceCriptografado {
  static const String baseUrl = 'https://45.162.242.43';
  static const String _chaveCriptografia = 'ARES_FLUTTER_2025';

  /// Realiza o login do usuário com criptografia AES
  static Future<Map<String, dynamic>> loginComCriptografia({
    required String login,
    required String senha,
    String? chaveCriptografia,
  }) async {
    print('🔍 INICIANDO LOGIN COM CRIPTOGRAFIA:');
    print('Usuário: $login');
    print('Senha (texto plano): $senha');

    try {
      // 1. Criptografar a senha informada pelo usuário
      final senhaCriptografada = EncryptionService.criptografarAES(senha);
      print('🔐 Senha criptografada: $senhaCriptografada');
      print(
          '📝 Processo: usuário digita "$senha" → sistema criptografa → "$senhaCriptografada"');

      // 2. Fazer login diretamente na API com senha criptografada
      final url = '$baseUrl/api/Usuario/login';
      final requestBody = {
        'login': login,
        'senhaw': senhaCriptografada, // Campo com senha criptografada
      };

      print('📤 Enviando para API:');
      print('URL: $url');
      print('Body: ${jsonEncode(requestBody)}');
      print(
          '💡 A API vai comparar "$senhaCriptografada" com a senhaw do banco');

      // Para HTTPS, usa HttpClient customizado para aceitar certificados auto-assinados
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) {
          print('🔒 Aceitando certificado auto-assinado para $host:$port');
          return true;
        };

      final request = await httpClient.postUrl(Uri.parse(url));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', '*/*');
      request.write(jsonEncode(requestBody));

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('📥 Resposta da API:');
      print('Status: ${httpResponse.statusCode}');
      print('Body: $responseBody');

      if (httpResponse.statusCode == 200) {
        final data = json.decode(responseBody);

        if (data.containsKey('token') && data.containsKey('user')) {
          final token = data['token'] as String;
          final userData = data['user'] as Map<String, dynamic>;

          print('✅ Token encontrado: ${token.substring(0, 20)}...');
          print('✅ User data: $userData');
          print(
              '🎉 Autenticação bem-sucedida! Senha criptografada foi aceita pela API');

          if (token.isNotEmpty) {
            final user = UserModel.fromJson({
              ...userData,
              'login': userData['login'] ?? login,
              'token': token,
            });

            // Salvar dados do usuário
            await _salvarDadosUsuario(user, token);

            print('✅ Login realizado com sucesso');
            return {
              'success': true,
              'user': user,
              'token': token,
              'data': data,
            };
          } else {
            print('❌ Token vazio');
            return {
              'success': false,
              'message': 'Token vazio na resposta da API.',
              'data': data,
            };
          }
        } else {
          print('❌ Estrutura de resposta inválida');
          print('Esperado: campos "token" e "user"');
          print('Encontrado: ${data.keys.toList()}');
          return {
            'success': false,
            'message': 'Estrutura de resposta inválida da API.',
            'data': data,
          };
        }
      } else {
        print('❌ Erro HTTP: ${httpResponse.statusCode}');
        print(
            '💡 Possível causa: senha criptografada não corresponde à senhaw do banco');
        return {
          'success': false,
          'message':
              'Credenciais inválidas ou erro na API: ${httpResponse.statusCode}',
          'response': responseBody,
        };
      }
    } catch (e) {
      print('❌ Erro no login: $e');
      return {
        'success': false,
        'message': 'Erro interno: $e',
      };
    }
  }

  /// Testa a criptografia de uma senha específica
  static Future<Map<String, dynamic>> testarCriptografiaSenha({
    required String senha,
  }) async {
    print('🧪 TESTANDO CRIPTOGRAFIA DE SENHA:');
    print('Senha original: $senha');

    try {
      final senhaCriptografada = EncryptionService.criptografarAES(senha);
      print('✅ Senha criptografada: $senhaCriptografada');

      // Teste de descriptografia (apenas para verificar se funciona)
      final senhaDescriptografada =
          EncryptionService.descriptografarAES(senhaCriptografada);
      print('✅ Senha descriptografada: $senhaDescriptografada');

      return {
        'success': true,
        'senhaOriginal': senha,
        'senhaCriptografada': senhaCriptografada,
        'senhaDescriptografada': senhaDescriptografada,
      };
    } catch (e) {
      print('❌ Erro no teste: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<UserModel?> _buscarUsuarioPorLogin(String login) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;

      final uri = Uri.parse('$baseUrl/api/Usuario/buscar_por_login/$login');
      final request = await httpClient.getUrl(uri);

      request.headers.set('Accept', '*/*');
      request.headers.set('Content-Type', 'application/json');

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('🔍 DEBUG BUSCA USUÁRIO:');
      print('URL: $uri');
      print('Status: ${httpResponse.statusCode}');
      print('Body: $responseBody');

      httpClient.close();

      if (httpResponse.statusCode == 200) {
        final data = json.decode(responseBody);
        return UserModel.fromJson(data);
      } else {
        print('❌ Erro ao buscar usuário: ${httpResponse.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao buscar usuário: $e');
      return null;
    }
  }

  static Future<String?> _gerarTokenJWT(UserModel usuario) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;

      final uri = Uri.parse('$baseUrl/api/Usuario/gerar_token');
      final request = await httpClient.postUrl(uri);

      request.headers.set('Accept', '*/*');
      request.headers.set('Content-Type', 'application/json');

      final body = {
        'codusu': usuario.codusu,
        'login': usuario.login,
        'nome': usuario.nome,
      };

      request.write(json.encode(body));

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('🔐 DEBUG GERAÇÃO TOKEN:');
      print('URL: $uri');
      print('Status: ${httpResponse.statusCode}');
      print('Body: $responseBody');

      httpClient.close();

      if (httpResponse.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['token'] as String?;
      } else {
        print('❌ Erro ao gerar token: ${httpResponse.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao gerar token: $e');
      return null;
    }
  }

  static Future<void> _salvarDadosUsuario(
      UserModel usuario, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('user_name', usuario.nome ?? '');
    await prefs.setInt('user_id', usuario.codusu ?? 0);
    await prefs.setString('user_login', usuario.login ?? '');

    print('✅ Dados do usuário salvos');
  }

  static Future<Map<String, dynamic>> testarAutenticacaoCriptografada({
    required String login,
    required String senha,
  }) async {
    print('🧪 TESTANDO AUTENTICAÇÃO CRIPTOGRAFADA');
    print('Login: $login');
    print('Senha: $senha');

    // Testa a criptografia
    final hashSenha = EncryptionService.gerarHashSenha(senha);
    print('🔐 Hash gerado: $hashSenha');

    // Testa a verificação
    final senhaValida = EncryptionService.verificarSenha(senha, hashSenha);
    print('✅ Verificação: $senhaValida');

    // Testa o login completo
    final resultado = await loginComCriptografia(
      login: login,
      senha: senha,
    );

    return resultado;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    await prefs.remove('user_id');
    await prefs.remove('user_login');
    print('✅ Logout realizado');
  }
}
