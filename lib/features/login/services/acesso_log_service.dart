import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/mobile_device_context.dart';
import 'auth_service.dart';

class AcessoLogService {
  static Future<void> registerLoginAccess() async {
    await _registerAccess(tipmov: 'LOGIN');
  }

  static Future<void> registerLogoutAccess() async {
    await _registerAccess(tipmov: 'LOGOUT');
  }

  static Future<void> registerAppAccess() async {
    await _registerAccess(tipmov: 'ACESSO');
  }

  static Future<void> _registerAccess({required String tipmov}) async {
    try {
      await AuthService.repairSessionCodusuIfNeeded();
      final String empresaId = await AuthService.requireEmpresaId();
      final int? codusu = await AuthService.getCurrentCodusu();
      if (codusu == null || codusu <= 0) {
        debugPrint(
          'AcessoLogService: codusu ausente — $tipmov não registrado.',
        );
        return;
      }
      await AuthService.requireToken();
      final MobileDeviceSnapshot device =
          await MobileDeviceContext.collect();
      final Map<String, dynamic> payload = <String, dynamic>{
        'empresaId': empresaId,
        'codusu': codusu,
        'tipmov': tipmov,
        'sucesso': 'S',
        ...device.toApiJson(),
      };
      await _postMobileAcesso(payload);
      debugPrint('AcessoLogService: $tipmov registrado (codusu=$codusu).');
    } catch (error, stackTrace) {
      debugPrint('AcessoLogService: falha em $tipmov — $error');
      if (kDebugMode) {
        debugPrint('$stackTrace');
      }
    }
  }

  static Future<void> _postMobileAcesso(Map<String, dynamic> payload) async {
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/auth/mobile-acesso');
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.postUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(payload));
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      if (httpResponse.statusCode == 401 || httpResponse.statusCode == 403) {
        throw HttpException(
          'mobile-acesso ${httpResponse.statusCode}: $responseBody',
        );
      }
      if (httpResponse.statusCode != 200) {
        throw HttpException(
          'mobile-acesso ${httpResponse.statusCode}: $responseBody',
        );
      }
      final dynamic decoded = json.decode(responseBody);
      if (decoded is Map<String, dynamic> && decoded['ok'] == false) {
        throw HttpException(
          decoded['error']?.toString() ?? 'Erro ao registrar acesso mobile',
        );
      }
    } finally {
      httpClient.close();
    }
  }
}
