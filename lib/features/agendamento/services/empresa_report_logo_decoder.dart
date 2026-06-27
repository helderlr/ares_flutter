import 'dart:convert';
import 'dart:typed_data';

class EmpresaReportLogoDecoder {
  static Uint8List? decodeLogomarcaBytes(String? logomarcaUrl) {
    if (logomarcaUrl == null || logomarcaUrl.trim().isEmpty) {
      return null;
    }
    final String trimmed = logomarcaUrl.trim();
    if (!trimmed.startsWith('data:')) {
      return null;
    }
    final int commaIndex = trimmed.indexOf(',');
    if (commaIndex < 0) {
      return null;
    }
    try {
      return base64Decode(trimmed.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}
