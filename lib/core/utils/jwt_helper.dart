import 'dart:convert';

class JwtHelper {
  static Map<String, dynamic>? decodePayload(String token) {
    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }
    try {
      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final int mod = normalized.length % 4;
      if (mod > 0) {
        normalized += '=' * (4 - mod);
      }
      final String decoded = utf8.decode(base64.decode(normalized));
      final dynamic json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) {
        return json;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static List<String> extractEmpresaIds(String token) {
    final Map<String, dynamic>? payload = decodePayload(token);
    if (payload == null) {
      return <String>[];
    }
    final dynamic empresas = payload['empresas'];
    if (empresas is! List) {
      return <String>[];
    }
    return empresas
        .map((dynamic item) => item.toString().trim())
        .where((String id) => id.isNotEmpty)
        .toList();
  }

  static bool isEmpresaAuthorized(String token, String empresaId) {
    final List<String> authorizedIds = extractEmpresaIds(token);
    return authorizedIds.contains(empresaId);
  }
}
