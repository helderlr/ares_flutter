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
      final String empresaId = await AuthService.requireEmpresaId();
      final int? codusu = await AuthService.getCurrentCodusu();
      if (codusu == null || codusu <= 0) {
        if (kDebugMode) {
          debugPrint(
            'AcessoLogService: codusu ausente — $tipmov não registrado.',
          );
        }
        return;
      }
      final MobileDeviceSnapshot device =
          await MobileDeviceContext.collect();
      final Map<String, dynamic> basePayload = <String, dynamic>{
        'empresaId': empresaId,
        'codusu': codusu,
        ...device.toApiJson(),
      };
      await _postDispositivoUsuario(basePayload);
      await _postLogAcesso(<String, dynamic>{
        ...basePayload,
        'tipmov': tipmov,
        'sucesso': 'S',
      });
      if (kDebugMode) {
        debugPrint('AcessoLogService: $tipmov registrado (codusu=$codusu).');
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('AcessoLogService: falha em $tipmov — $error');
        debugPrint('$stackTrace');
      }
    }
  }

  static Future<void> _postDispositivoUsuario(
    Map<String, dynamic> payload,
  ) async {
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/dispositivo-usuario');
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
          'dispositivo-usuario ${httpResponse.statusCode}: $responseBody',
        );
      }
      if (httpResponse.statusCode != 200) {
        throw HttpException(
          'dispositivo-usuario ${httpResponse.statusCode}: $responseBody',
        );
      }
    } finally {
      httpClient.close();
    }
  }

  static Future<void> _postLogAcesso(Map<String, dynamic> payload) async {
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/log-acesso');
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
          'log-acesso ${httpResponse.statusCode}: $responseBody',
        );
      }
      if (httpResponse.statusCode != 200) {
        throw HttpException(
          'log-acesso ${httpResponse.statusCode}: $responseBody',
        );
      }
    } finally {
      httpClient.close();
    }
  }
}
