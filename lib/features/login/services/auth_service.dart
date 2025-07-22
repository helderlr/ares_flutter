import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'https://45.162.242.43';

  /// Realiza o login do usuário
  static Future<Map<String, dynamic>> login({
    required String login,
    required String senha,
    required String nomusu,
  }) async {
    // URL específica que funciona
    final url = '$baseUrl/api/Usuario/login';

    // Log dos dados sendo enviados
    print('🔍 DEBUG LOGIN:');
    print('URL: $url');
    print('Login: $login');
    print('Senha: $senha');
    print('Nomusu: $nomusu');

    final requestBody = {
      'nomusu': nomusu,
      'login': login,
      'senha': senha,
    };

    print('Body JSON: ${jsonEncode(requestBody)}');

    try {
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

      print('📤 Requisição enviada...');

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('📥 Resposta recebida:');
      print('Status: ${httpResponse.statusCode}');
      print('Headers: ${httpResponse.headers}');
      print('Body: $responseBody');

      if (httpResponse.statusCode == 200) {
        final data = json.decode(responseBody);

        if (data.containsKey('token') && data.containsKey('user')) {
          final token = data['token'] as String;
          final userData = data['user'] as Map<String, dynamic>;

          print('✅ Token encontrado: ${token.substring(0, 20)}...');
          print('✅ User data: $userData');

          if (token.isNotEmpty) {
            final user = UserModel.fromJson({
              ...userData,
              'login': userData['login'] ?? login,
              'nomusu': userData['nomusu'] ?? nomusu,
              'token': token,
            });

            print('✅ Login bem-sucedido!');
            httpClient.close();
            return {
              'success': true,
              'user': user,
              'token': token,
              'data': data,
              'workingUrl': url,
            };
          } else {
            print('❌ Token vazio');
            httpClient.close();
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
          httpClient.close();
          return {
            'success': false,
            'message':
                'Estrutura de resposta inválida. Esperado campos "token" e "user".',
            'data': data,
          };
        }
      } else {
        print('❌ Erro HTTP: ${httpResponse.statusCode}');
        httpClient.close();
        return {
          'success': false,
          'message': 'Erro na API: ${httpResponse.statusCode} - $responseBody',
          'statusCode': httpResponse.statusCode,
        };
      }
    } catch (e) {
      print('❌ Erro de conexão: $e');
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Salva os dados do usuário logado
  static Future<void> saveUserData({
    required UserModel user,
    bool rememberMe = false,
    String? savedPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('jwt_token', user.token ?? '');
    await prefs.setString('user_name', user.nome);
    await prefs.setString('user_login', user.login);
    if (user.codven != null) {
      await prefs.setString('user_codven', user.codven!);
    }

    if (rememberMe && savedPassword != null) {
      await prefs.setString('saved_login', user.login);
      await prefs.setString('saved_password', savedPassword);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_login');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  /// Verifica se o usuário está logado
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return token != null && token.isNotEmpty;
  }

  /// Obtém o token salvo
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Obtém o nome do usuário salvo
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  /// Obtém o login do usuário salvo
  static Future<String?> getUserLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_login');
  }

  /// Obtém o código do vendedor salvo
  static Future<String?> getUserCodven() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_codven');
  }

  /// Obtém o usuário completo salvo
  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final nome = prefs.getString('user_name');
    final login = prefs.getString('user_login');
    final codven = prefs.getString('user_codven');

    if (token != null && nome != null && login != null) {
      return UserModel(
        login: login,
        nome: nome,
        codven: codven,
        token: token,
      );
    }

    return null;
  }

  /// Faz logout do usuário
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    await prefs.remove('user_login');
    await prefs.remove('user_codven');
    // Não remove as credenciais salvas se "Me lembre" estiver ativo
  }

  /// Obtém as credenciais salvas se "Me lembre" estiver ativo
  static Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      return {
        'login': prefs.getString('saved_login'),
        'password': prefs.getString('saved_password'),
      };
    }

    return {'login': null, 'password': null};
  }

  /// Valida se o token ainda é válido (opcional - pode ser implementado no futuro)
  static Future<bool> validateToken() async {
    // Implementação futura para validar token com a API
    // Por enquanto, apenas verifica se existe
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
