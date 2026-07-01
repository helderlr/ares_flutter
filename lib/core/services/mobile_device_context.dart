import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileDeviceSnapshot {
  final String deviceId;
  final String? dispositivo;
  final String? fabricante;
  final String? sistemaOperacional;
  final String? versaoSo;
  final String? navegador;
  final String appVersao;
  final String userAgent;

  const MobileDeviceSnapshot({
    required this.deviceId,
    this.dispositivo,
    this.fabricante,
    this.sistemaOperacional,
    this.versaoSo,
    this.navegador,
    required this.appVersao,
    required this.userAgent,
  });

  Map<String, dynamic> toApiJson() {
    return <String, dynamic>{
      'deviceId': deviceId,
      if (dispositivo != null) 'dispositivo': dispositivo,
      if (fabricante != null) 'fabricante': fabricante,
      if (sistemaOperacional != null) 'sistemaOperacional': sistemaOperacional,
      if (versaoSo != null) 'versaoSo': versaoSo,
      if (navegador != null) 'navegador': navegador,
      'appVersao': appVersao,
      'userAgent': userAgent,
      'origem': 'MOBILE',
    };
  }
}

class MobileDeviceContext {
  static const String _deviceIdKey = 'ares_mobile_device_id';
  static MobileDeviceSnapshot? _cachedSnapshot;

  static Future<MobileDeviceSnapshot> collect() async {
    if (_cachedSnapshot != null) {
      return _cachedSnapshot!;
    }
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String appVersao = packageInfo.version;
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String? dispositivo;
    String? fabricante;
    String? sistemaOperacional;
    String? versaoSo;
    if (kIsWeb) {
      final WebBrowserInfo webInfo = await deviceInfoPlugin.webBrowserInfo;
      dispositivo = webInfo.browserName.name;
      sistemaOperacional = 'Web';
      versaoSo = webInfo.platform;
    } else if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      fabricante = androidInfo.manufacturer;
      dispositivo = androidInfo.model;
      sistemaOperacional = 'Android';
      versaoSo = androidInfo.version.release;
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      fabricante = 'Apple';
      dispositivo = iosInfo.utsname.machine;
      sistemaOperacional = 'iOS';
      versaoSo = iosInfo.systemVersion;
    } else if (Platform.isWindows) {
      final WindowsDeviceInfo windowsInfo = await deviceInfoPlugin.windowsInfo;
      fabricante = 'Microsoft';
      dispositivo = windowsInfo.computerName;
      sistemaOperacional = 'Windows';
      versaoSo = windowsInfo.displayVersion;
    } else if (Platform.isLinux) {
      final LinuxDeviceInfo linuxInfo = await deviceInfoPlugin.linuxInfo;
      dispositivo = linuxInfo.name;
      sistemaOperacional = 'Linux';
      versaoSo = linuxInfo.version;
    } else if (Platform.isMacOS) {
      final MacOsDeviceInfo macInfo = await deviceInfoPlugin.macOsInfo;
      fabricante = 'Apple';
      dispositivo = macInfo.model;
      sistemaOperacional = 'macOS';
      versaoSo = macInfo.osRelease;
    }
    final String deviceId = await _resolveDeviceId();
    final String userAgent = _buildUserAgent(
      appVersao: appVersao,
      sistemaOperacional: sistemaOperacional,
      versaoSo: versaoSo,
      dispositivo: dispositivo,
    );
    _cachedSnapshot = MobileDeviceSnapshot(
      deviceId: deviceId,
      dispositivo: dispositivo,
      fabricante: fabricante,
      sistemaOperacional: sistemaOperacional,
      versaoSo: versaoSo,
      navegador: null,
      appVersao: appVersao,
      userAgent: userAgent,
    );
    return _cachedSnapshot!;
  }

  static Future<String> _resolveDeviceId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_deviceIdKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    final String generated = _generateDeviceId();
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  static String _generateDeviceId() {
    final Random random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256))
        .map((int value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static String _buildUserAgent({
    required String appVersao,
    String? sistemaOperacional,
    String? versaoSo,
    String? dispositivo,
  }) {
    final StringBuffer buffer = StringBuffer('AresIA Mobile/$appVersao');
    if (sistemaOperacional != null && sistemaOperacional.isNotEmpty) {
      buffer.write(' ($sistemaOperacional');
      if (versaoSo != null && versaoSo.isNotEmpty) {
        buffer.write(' $versaoSo');
      }
      if (dispositivo != null && dispositivo.isNotEmpty) {
        buffer.write('; $dispositivo');
      }
      buffer.write(')');
    }
    final String value = buffer.toString();
    return value.length <= 500 ? value : value.substring(0, 500);
  }
}
