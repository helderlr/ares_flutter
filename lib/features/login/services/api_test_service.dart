import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiTestService {
  static const String baseUrl = 'http://45.162.242.43:3051';

  /// Testa a conectividade da API
  static Future<Map<String, dynamic>> testApiConnectivity() async {
    final results = <String, dynamic>{};

    // Testa se o Swagger está acessível
    try {
      final swaggerResponse = await http
          .get(
            Uri.parse('$baseUrl/swagger/index.html'),
          )
          .timeout(const Duration(seconds: 10));

      results['swagger_accessible'] = swaggerResponse.statusCode == 200;
      results['swagger_status'] = swaggerResponse.statusCode;
    } catch (e) {
      results['swagger_accessible'] = false;
      results['swagger_error'] = e.toString();
    }

    // Lista de possíveis URLs para testar
    final urls = [
      '$baseUrl/api/Usuario/login',
      '$baseUrl/api/usuario/login',
      '$baseUrl/Usuario/login',
      '$baseUrl/usuario/login',
      '$baseUrl/api/Usuario/Login',
      '$baseUrl/api/Usuario',
      '$baseUrl/api/usuarios/login',
      '$baseUrl/api/auth/login',
    ];

    results['url_tests'] = <String, dynamic>{};

    for (String url in urls) {
      try {
        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'nomusu': 'Administrador',
                'login': 'Administrador',
                'senha': 'adm\$10',
              }),
            )
            .timeout(const Duration(seconds: 10));

        results['url_tests'][url] = {
          'status_code': response.statusCode,
          'headers': response.headers,
          'body': response.body,
          'success': response.statusCode == 200,
        };

        // Se encontrou uma URL que funciona, para o teste
        if (response.statusCode == 200) {
          results['working_url'] = url;
          break;
        }
      } catch (e) {
        results['url_tests'][url] = {
          'error': e.toString(),
          'success': false,
        };
      }
    }

    return results;
  }

  /// Testa uma URL específica
  static Future<Map<String, dynamic>> testSpecificUrl(String url) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'nomusu': 'Administrador',
              'login': 'Administrador',
              'senha': 'adm\$10',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'status_code': response.statusCode,
          'data': data,
          'token': data['token'] ??
              data['accessToken'] ??
              data['jwt'] ??
              data['access_token'],
        };
      } else {
        return {
          'success': false,
          'status_code': response.statusCode,
          'body': response.body,
          'headers': response.headers,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
