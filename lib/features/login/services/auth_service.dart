import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/jwt_helper.dart';
import '../models/empresa_model.dart';
import '../models/user_model.dart';

class LoginResult {
  final bool success;
  final UserModel? usuario;
  final List<EmpresaModel> empresas;
  final String? token;
  final String? message;

  const LoginResult({
    required this.success,
    this.usuario,
    this.empresas = const [],
    this.token,
    this.message,
  });
}

class AuthService {
  static const int sessionVersion = 2;
  static const String _sessionVersionKey = 'session_version';
  static const String _sessionUsuarioKey = 'session_usuario';
  static const String _sessionEmpresaKey = 'session_empresa';
  static const String _jwtTokenKey = 'jwt_token';
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  static const String _authorizedEmpresaIdsKey = 'authorized_empresa_ids';

  static VoidCallback? onSessionExpired;

  static Future<void> migrateSessionIfNeeded() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int storedVersion = prefs.getInt(_sessionVersionKey) ?? 0;
    if (storedVersion >= sessionVersion) {
      return;
    }
    await logout();
    await prefs.setInt(_sessionVersionKey, sessionVersion);
  }

  static String? extractTokenFromResponse(Map<String, dynamic> decoded) {
    final dynamic rawToken = decoded['token'] ??
        decoded['accessToken'] ??
        decoded['access_token'] ??
        decoded['jwt'];
    if (rawToken == null) {
      return null;
    }
    final String token = rawToken.toString().trim();
    return token.isEmpty ? null : token;
  }

  static String? extractTokenFromHeaders(http.Response response) {
    for (final MapEntry<String, String> entry in response.headers.entries) {
      if (entry.key.toLowerCase() != 'set-cookie') {
        continue;
      }
      final RegExp cookiePattern =
          RegExp(r'aresia_token=([^;,\s]+)', caseSensitive: false);
      final Match? match = cookiePattern.firstMatch(entry.value);
      if (match != null) {
        final String token = Uri.decodeComponent(match.group(1)!);
        return token.isEmpty ? null : token;
      }
    }
    return null;
  }

  static String? resolveTokenFromLoginResponse({
    required Map<String, dynamic> decoded,
    required http.Response response,
  }) {
    return extractTokenFromResponse(decoded) ??
        extractTokenFromHeaders(response);
  }

  static String mapHttpErrorMessage(int statusCode, String responseBody) {
    if (statusCode == 502) {
      return 'Servidor indisponível (502). O site aresia.com.br não está respondendo. '
          'Aguarde alguns minutos ou verifique se o servidor está no ar.';
    }
    if (statusCode == 503) {
      return 'Serviço temporariamente indisponível (503). Tente novamente em instantes.';
    }
    if (statusCode == 401) {
      return 'E-mail ou senha incorretos.';
    }
    if (statusCode >= 500) {
      return 'Erro no servidor ($statusCode). Tente novamente mais tarde.';
    }
    if (responseBody.contains('502')) {
      return 'Servidor indisponível. Verifique se aresia.com.br está no ar.';
    }
    return 'Erro na API ($statusCode). Verifique sua conexão e tente novamente.';
  }

  static Map<String, dynamic>? tryDecodeJson(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return null;
    }
    try {
      final dynamic decoded = json.decode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  static Future<LoginResult> login({
    required String email,
    required String senha,
  }) async {
    try {
      final http.Response response = await http
          .post(
            Uri.parse(ApiConfig.loginUrl),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'senha': senha,
            }),
          )
          .timeout(const Duration(seconds: 30));
      final Map<String, dynamic>? decoded = tryDecodeJson(response.body);
      if (response.statusCode != 200 || decoded == null) {
        final String apiError = decoded?['error']?.toString() ?? '';
        final String message = apiError.isNotEmpty
            ? apiError
            : mapHttpErrorMessage(response.statusCode, response.body);
        return LoginResult(success: false, message: message);
      }
      if (decoded['ok'] != true) {
        return LoginResult(
          success: false,
          message: decoded['error']?.toString() ?? 'Login inválido',
        );
      }
      final Map<String, dynamic>? usuarioJson =
          decoded['usuario'] as Map<String, dynamic>?;
      if (usuarioJson == null) {
        return const LoginResult(
          success: false,
          message: 'Resposta inválida: usuário não encontrado',
        );
      }
      final String? token = resolveTokenFromLoginResponse(
        decoded: decoded,
        response: response,
      );
      final UserModel usuario = UserModel.fromJson({
        ...usuarioJson,
        if (token != null) 'token': token,
      });
      final List<EmpresaModel> empresas = (decoded['empresas'] as List<dynamic>?)
              ?.map((dynamic item) =>
                  EmpresaModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      return LoginResult(
        success: true,
        usuario: usuario,
        empresas: empresas,
        token: token,
      );
    } catch (error) {
      final String errorText = error.toString();
      if (errorText.contains('TimeoutException') ||
          errorText.contains('timed out')) {
        return const LoginResult(
          success: false,
          message:
              'Tempo esgotado ao conectar com o servidor. Verifique sua internet '
              'ou se aresia.com.br está no ar.',
        );
      }
      if (errorText.contains('SocketException') ||
          errorText.contains('Failed host lookup')) {
        return const LoginResult(
          success: false,
          message:
              'Sem conexão com o servidor. Verifique sua internet e tente novamente.',
        );
      }
      return LoginResult(
        success: false,
        message: 'Erro de conexão. Verifique se aresia.com.br está acessível.',
      );
    }
  }

  static String? validateEmpresaAccess({
    required String empresaId,
    required List<EmpresaModel> empresasFromLogin,
    required String? token,
  }) {
    final bool isInLoginList =
        empresasFromLogin.any((EmpresaModel empresa) => empresa.id == empresaId);
    if (!isInLoginList) {
      return 'Empresa não vinculada a este usuário (usuario_empresa).';
    }
    if (token != null &&
        token.isNotEmpty &&
        ApiConfig.jwtRequired &&
        !JwtHelper.isEmpresaAuthorized(token, empresaId)) {
      return 'Empresa não autorizada no token JWT.';
    }
    return null;
  }

  static Future<void> saveSession({
    required UserModel usuario,
    required EmpresaModel empresa,
    required List<EmpresaModel> empresasFromLogin,
    String? token,
    bool rememberMe = false,
    String? savedEmail,
    String? savedPassword,
  }) async {
    final String? accessError = validateEmpresaAccess(
      empresaId: empresa.id,
      empresasFromLogin: empresasFromLogin,
      token: token,
    );
    if (accessError != null) {
      throw Exception(accessError);
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? sessionToken = token ?? usuario.token;
    final String? refEmpresaId = UserModel.extractEmpresaIdFromRef(usuario.id);
    final int? refCodusu = UserModel.extractCodusuFromRef(usuario.id);
    final int? sessionCodusu = empresa.codusu ??
        usuario.codusu ??
        (refEmpresaId == empresa.id ? refCodusu : null);
    final int? sessionCodven = empresa.codven ?? _parseCodven(usuario.codven);
    final UserModel usuarioToSave = usuario.copyWith(
      codusu: sessionCodusu,
      codven: sessionCodven?.toString(),
    );
    final EmpresaModel empresaToSave = EmpresaModel(
      id: empresa.id,
      nome: empresa.nome,
      cnpj: empresa.cnpj,
      logomarcaUrl: empresa.logomarcaUrl,
      codusu: sessionCodusu,
      codven: sessionCodven,
    );
    await prefs.setString(_sessionUsuarioKey, jsonEncode(usuarioToSave.toJson()));
    await prefs.setString(_sessionEmpresaKey, jsonEncode(empresaToSave.toJson()));
    await prefs.setString('user_name', usuario.nome);
    await prefs.setString('user_email', usuario.email);
    await prefs.setInt(_sessionVersionKey, sessionVersion);
    if (sessionToken != null && sessionToken.isNotEmpty) {
      await prefs.setString(_jwtTokenKey, sessionToken);
      final List<String> authorizedIds =
          JwtHelper.extractEmpresaIds(sessionToken);
      if (authorizedIds.isNotEmpty) {
        await prefs.setStringList(_authorizedEmpresaIdsKey, authorizedIds);
      }
    } else {
      final List<String> idsFromLogin =
          empresasFromLogin.map((EmpresaModel item) => item.id).toList();
      await prefs.setStringList(_authorizedEmpresaIdsKey, idsFromLogin);
    }
    if (rememberMe && savedEmail != null && savedPassword != null) {
      await prefs.setString(_savedEmailKey, savedEmail);
      await prefs.setString(_savedPasswordKey, savedPassword);
      await prefs.setBool(_rememberMeKey, true);
    } else {
      await prefs.remove(_savedEmailKey);
      await prefs.remove(_savedPasswordKey);
      await prefs.setBool(_rememberMeKey, false);
    }
  }

  static Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? usuarioJson = prefs.getString(_sessionUsuarioKey);
    final String? empresaJson = prefs.getString(_sessionEmpresaKey);
    final bool hasSession = usuarioJson != null &&
        usuarioJson.isNotEmpty &&
        empresaJson != null &&
        empresaJson.isNotEmpty;
    if (!hasSession) {
      return false;
    }
    if (!ApiConfig.jwtRequired) {
      return true;
    }
    final String? token = prefs.getString(_jwtTokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jwtTokenKey);
  }

  static Future<String> requireToken() async {
    final String? token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception(
        'Token JWT não encontrado. Faça login novamente.',
      );
    }
    return token;
  }

  static Future<Map<String, String>> buildAuthHeaders() async {
    final Map<String, String> headers = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final String? token = await getToken();
    if (token != null && token.isNotEmpty) {
      return {
        ...headers,
        'Authorization': 'Bearer $token',
      };
    }
    return headers;
  }

  static Future<void> handleSessionExpired() async {
    await logout();
    onSessionExpired?.call();
  }

  static Future<bool> validateTokenWithServer({bool silent = false}) async {
    if (!ApiConfig.jwtRequired) {
      return true;
    }
    final String? token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    try {
      final http.Response response = await http
          .get(
            Uri.parse(ApiConfig.meUrl),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return true;
      }
      if (response.statusCode == 401) {
        if (silent) {
          await logout();
        } else {
          await handleSessionExpired();
        }
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<int?> getCurrentCodusu() async {
    final EmpresaModel? empresa = await getCurrentEmpresa();
    if (empresa?.codusu != null && empresa!.codusu! > 0) {
      return empresa.codusu;
    }
    final UserModel? user = await getCurrentUser();
    if (user == null) {
      return null;
    }
    if (user.codusu != null && user.codusu! > 0) {
      return user.codusu;
    }
    final String? empresaId = await getEmpresaId();
    final String? refEmpresaId = UserModel.extractEmpresaIdFromRef(user.id);
    final int? refCodusu = UserModel.extractCodusuFromRef(user.id);
    if (empresaId != null &&
        refEmpresaId == empresaId &&
        refCodusu != null &&
        refCodusu > 0) {
      return refCodusu;
    }
    final String? token = await getToken();
    if (token != null && token.isNotEmpty && empresaId != null) {
      final Map<String, dynamic>? payload = JwtHelper.decodePayload(token);
      final String? sub = payload?['sub']?.toString();
      if (sub != null && sub.isNotEmpty) {
        final String? jwtEmpresaId = UserModel.extractEmpresaIdFromRef(sub);
        final int? jwtCodusu = UserModel.extractCodusuFromRef(sub);
        if (jwtEmpresaId == empresaId && jwtCodusu != null && jwtCodusu > 0) {
          return jwtCodusu;
        }
      }
    }
    return null;
  }

  static int? _parseCodven(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  static Future<int?> getCurrentCodven() async {
    final EmpresaModel? empresa = await getCurrentEmpresa();
    if (empresa?.codven != null && empresa!.codven! > 0) {
      return empresa.codven;
    }
    final UserModel? user = await getCurrentUser();
    return _parseCodven(user?.codven);
  }

  static Future<String?> getUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<String?> getUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  static Future<UserModel?> getCurrentUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? usuarioJson = prefs.getString(_sessionUsuarioKey);
    if (usuarioJson == null || usuarioJson.isEmpty) {
      return null;
    }
    return UserModel.fromJson(
      jsonDecode(usuarioJson) as Map<String, dynamic>,
    );
  }

  static Future<EmpresaModel?> getCurrentEmpresa() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? empresaJson = prefs.getString(_sessionEmpresaKey);
    if (empresaJson == null || empresaJson.isEmpty) {
      return null;
    }
    return EmpresaModel.fromJson(
      jsonDecode(empresaJson) as Map<String, dynamic>,
    );
  }

  static Future<String?> getEmpresaId() async {
    final EmpresaModel? empresa = await getCurrentEmpresa();
    return empresa?.id;
  }

  static Future<String> requireEmpresaId() async {
    final String? empresaId = await getEmpresaId();
    if (empresaId == null || empresaId.isEmpty) {
      throw Exception(
        'Empresa não selecionada. Faça login novamente.',
      );
    }
    final bool isAuthorized = await isCurrentEmpresaAuthorized();
    if (!isAuthorized) {
      await handleSessionExpired();
      throw Exception('Empresa não autorizada. Faça login novamente.');
    }
    return empresaId;
  }

  static Future<bool> isCurrentEmpresaAuthorized() async {
    final String? empresaId = await getEmpresaId();
    if (empresaId == null || empresaId.isEmpty) {
      return false;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> authorizedIds =
        prefs.getStringList(_authorizedEmpresaIdsKey) ?? <String>[];
    if (authorizedIds.isEmpty) {
      return true;
    }
    return authorizedIds.contains(empresaId);
  }

  static Future<void> repairSessionCodusuIfNeeded() async {
    final UserModel? user = await getCurrentUser();
    final EmpresaModel? empresa = await getCurrentEmpresa();
    if (user == null || empresa == null) {
      return;
    }
    final bool hasCodusu = (user.codusu != null && user.codusu! > 0) ||
        (empresa.codusu != null && empresa.codusu! > 0);
    if (hasCodusu) {
      return;
    }
    final String? refEmpresaId = UserModel.extractEmpresaIdFromRef(user.id);
    final int? refCodusu = UserModel.extractCodusuFromRef(user.id);
    if (refEmpresaId != empresa.id || refCodusu == null || refCodusu <= 0) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionUsuarioKey,
      jsonEncode(user.copyWith(codusu: refCodusu).toJson()),
    );
    await prefs.setString(
      _sessionEmpresaKey,
      jsonEncode(EmpresaModel(
        id: empresa.id,
        nome: empresa.nome,
        cnpj: empresa.cnpj,
        logomarcaUrl: empresa.logomarcaUrl,
        codusu: refCodusu,
        codven: empresa.codven,
      ).toJson()),
    );
  }

  static Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUsuarioKey);
    await prefs.remove(_sessionEmpresaKey);
    await prefs.remove(_jwtTokenKey);
    await prefs.remove(_authorizedEmpresaIdsKey);
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  static Future<Map<String, String?>> getSavedCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (!rememberMe) {
      return {'email': null, 'password': null};
    }
    return {
      'email': prefs.getString(_savedEmailKey),
      'password': prefs.getString(_savedPasswordKey),
    };
  }
}
