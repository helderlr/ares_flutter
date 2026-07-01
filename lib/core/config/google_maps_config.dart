/// Google Maps API key configuration.
class GoogleMapsConfig {
  GoogleMapsConfig._();

  static const String defaultApiKey =
      'AIzaSyAItoYASbxcjaFVOrQ0zb6qgcS9z8i4o04';

  static const String sharedPreferencesKey = 'google_maps_api_key';

  /// Chave usada na tabela de parâmetros do projeto Aresia.
  static const String parametroChave = 'google_maps_api_key';

  static const String methodChannelName =
      'br.com.domina.aresia/google_maps';

  static bool isValidApiKey(String value) {
    final String trimmed = value.trim();
    return trimmed.startsWith('AIza') && trimmed.length >= 35;
  }
}
