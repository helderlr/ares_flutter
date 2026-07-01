import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/google_maps_config.dart';
import '../../features/configuracao/services/projeto_parametro_service.dart';
import '../../features/login/services/auth_service.dart';

class GoogleMapsApiKeyService {
  GoogleMapsApiKeyService._();

  static final GoogleMapsApiKeyService instance = GoogleMapsApiKeyService._();

  static const MethodChannel _channel =
      MethodChannel(GoogleMapsConfig.methodChannelName);

  final ProjetoParametroService _parametroService = ProjetoParametroService();

  Future<void> initialize() async {
    final String apiKey = await getEffectiveApiKey();
    await applyApiKey(apiKey);
  }

  Future<void> syncFromServer() async {
    try {
      final bool isLoggedIn = await _isUserLoggedIn();
      if (!isLoggedIn) {
        return;
      }
      final String? remoteValue = await _parametroService.fetchValor(
        ProjetoParametroService.googleMapsApiKeyChave,
      );
      if (remoteValue == null ||
          !GoogleMapsConfig.isValidApiKey(remoteValue)) {
        return;
      }
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        GoogleMapsConfig.sharedPreferencesKey,
        remoteValue,
      );
      await applyApiKey(remoteValue);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('GoogleMapsApiKeyService.syncFromServer: $error');
      }
    }
  }

  Future<String> getEffectiveApiKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? localValue =
        prefs.getString(GoogleMapsConfig.sharedPreferencesKey);
    if (localValue != null &&
        GoogleMapsConfig.isValidApiKey(localValue)) {
      return localValue.trim();
    }
    return GoogleMapsConfig.defaultApiKey;
  }

  Future<SaveGoogleMapsApiKeyResult> saveApiKeyAsAdmin(String apiKey) async {
    final String trimmed = apiKey.trim();
    if (!GoogleMapsConfig.isValidApiKey(trimmed)) {
      return SaveGoogleMapsApiKeyResult.invalid;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(GoogleMapsConfig.sharedPreferencesKey, trimmed);
    await applyApiKey(trimmed);
    bool savedOnServer = false;
    try {
      savedOnServer = await _parametroService.saveValor(
        chave: ProjetoParametroService.googleMapsApiKeyChave,
        valor: trimmed,
      );
    } catch (_) {
      savedOnServer = false;
    }
    return SaveGoogleMapsApiKeyResult(
      savedLocally: true,
      savedOnServer: savedOnServer,
    );
  }

  Future<void> applyApiKey(String apiKey) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<void>(
        'setApiKey',
        <String, String>{'apiKey': apiKey},
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('GoogleMapsApiKeyService.applyApiKey: $error');
      }
    }
  }

  Future<bool> _isUserLoggedIn() async {
    try {
      return await AuthService.isLoggedIn();
    } catch (_) {
      return false;
    }
  }
}

class SaveGoogleMapsApiKeyResult {
  final bool savedLocally;
  final bool savedOnServer;
  final bool isInvalidKey;

  const SaveGoogleMapsApiKeyResult({
    this.savedLocally = false,
    this.savedOnServer = false,
    this.isInvalidKey = false,
  });

  static const SaveGoogleMapsApiKeyResult invalid =
      SaveGoogleMapsApiKeyResult(isInvalidKey: true);
}
