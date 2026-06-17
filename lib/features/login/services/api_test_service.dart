import '../../../core/config/api_config.dart';

class ApiTestService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> testApiConnectivity() async {
    final Map<String, dynamic> results = <String, dynamic>{};
    final List<String> urls = <String>[
      ApiConfig.loginUrl,
    ];
    results['url_tests'] = <String, dynamic>{};
    for (final String url in urls) {
      try {
        results['url_tests'][url] = {
          'endpoint': url,
          'note': 'Use POST com email e senha para testar login',
        };
      } catch (e) {
        results['url_tests'][url] = {'error': e.toString()};
      }
    }
    results['base_url'] = ApiConfig.baseUrl;
    return results;
  }
}
