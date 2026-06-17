/// Central API configuration for the Next.js backend.
///
/// Override at build/run time:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`
/// `flutter run --dart-define=JWT_REQUIRED=false` (dev sem token no backend)
class ApiConfig {
  static const String _defaultBaseUrl = 'https://aresia.com.br';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static const bool jwtRequired = bool.fromEnvironment(
    'JWT_REQUIRED',
    defaultValue: false,
  );

  static String get apiUrl => '$baseUrl/api';

  static String get loginUrl => '$apiUrl/auth/login';

  static String get meUrl => '$apiUrl/auth/me';

  static String get dominaLogoUrl => '$baseUrl/logo.png';

  static Uri buildUri(String path, {Map<String, String>? queryParameters}) {
    final String normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(
      queryParameters: queryParameters,
    );
  }
}
