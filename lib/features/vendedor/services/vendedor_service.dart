import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';

class VendedorLookup {
  final int codven;
  final String nome;

  const VendedorLookup({
    required this.codven,
    required this.nome,
  });
}

class VendedorService {
  Future<VendedorLookup?> fetchByCodven(int codven) async {
    if (codven <= 0) {
      return null;
    }
    final Map<String, String> queryParams =
        await HttpRequestHelper.withEmpresaId(<String, String>{});
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/vendedor')
        .replace(queryParameters: queryParams);
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      await HttpRequestHelper.throwIfUnauthorized(httpResponse.statusCode);
      if (httpResponse.statusCode != 200) {
        return null;
      }
      final dynamic decoded = HttpRequestHelper.decodeResponse(responseBody);
      final List<dynamic> rows = decoded is List<dynamic>
          ? decoded
          : (decoded is Map<String, dynamic> && decoded['data'] is List<dynamic>
              ? decoded['data'] as List<dynamic>
              : <dynamic>[]);
      for (final dynamic row in rows) {
        if (row is! Map<String, dynamic>) {
          continue;
        }
        final int? codigo = _parseCodven(row['codven']);
        if (codigo == codven) {
          final String nome = row['nomven']?.toString().trim() ??
              row['nomred']?.toString().trim() ??
              '';
          if (nome.isNotEmpty) {
            return VendedorLookup(codven: codven, nome: nome);
          }
        }
      }
      return null;
    } on UnauthorizedException {
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  int? _parseCodven(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
