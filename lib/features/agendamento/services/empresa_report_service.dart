import 'dart:convert';
import 'dart:io';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../login/models/empresa_model.dart';
import '../../login/services/auth_service.dart';
import '../models/empresa_report_model.dart';

class EmpresaReportService {
  Future<EmpresaReportData> fetchReportData() async {
    final EmpresaModel? sessionEmpresa = await AuthService.getCurrentEmpresa();
    if (sessionEmpresa == null) {
      throw Exception('Empresa não selecionada.');
    }
    try {
      final String empresaId = await AuthService.requireEmpresaId();
      final Uri uri =
          Uri.parse('${ApiConfig.apiUrl}/menu/empresa/$empresaId');
      final HttpClient client = HttpRequestHelper.createClient();
      try {
        final HttpClientRequest request = await client.getUrl(uri);
        await HttpRequestHelper.applyJsonHeaders(request);
        final HttpClientResponse response = await request.close();
        final String body = await response.transform(utf8.decoder).join();
        await HttpRequestHelper.throwIfUnauthorized(response.statusCode);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final dynamic decoded = jsonDecode(body);
          final Map<String, dynamic>? data =
              decoded is Map<String, dynamic> ? decoded['data'] as Map<String, dynamic>? : null;
          if (data != null) {
            return EmpresaReportData.fromJson(data);
          }
        }
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      // Fallback para dados da sessão.
    }
    return EmpresaReportData(
      nome: sessionEmpresa.nome,
      razaoSocial: sessionEmpresa.nome,
      nomeFantasia: sessionEmpresa.nome,
      cnpj: sessionEmpresa.cnpj,
      logomarcaUrl: sessionEmpresa.logomarcaUrl,
    );
  }
}
