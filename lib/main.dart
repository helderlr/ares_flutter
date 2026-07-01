import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/login/services/acesso_log_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_context.dart';
import 'core/config/api_config.dart';
import 'core/services/google_maps_api_key_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_page.dart';
import 'features/login/presentation/login_page.dart';
import 'features/login/services/auth_service.dart';
import 'features/splash/presentation/splash_page.dart';
import 'features/terms/services/terms_check_service.dart';

const Duration _startupTimeout = Duration(seconds: 5);
const Duration _maxSplashDuration = Duration(seconds: 6);
const Duration _backgroundLogoutDelay = Duration(minutes: 5);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleMapsApiKeyService.instance.initialize();
  HttpOverrides.global = MyHttpOverrides();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    }
  };
  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isLoggedIn = false;
  String nomeUsuario = '';
  bool isDarkTheme = false;
  bool showSplash = true;
  bool appReady = false;
  bool splashAnimationDone = false;
  Timer? _splashSafetyTimer;
  Timer? _backgroundLogoutTimer;
  bool _requiresLoginOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.onSessionExpired = _onSessionExpired;
    _splashSafetyTimer = Timer(_maxSplashDuration, _forceLeaveSplash);
    _initializeApp();
  }

  void _forceLeaveSplash() {
    if (!mounted || !showSplash) {
      return;
    }
    debugPrint('Ares: splash encerrada por tempo máximo.');
    splashAnimationDone = true;
    appReady = true;
    setState(() {
      showSplash = false;
    });
  }

  Future<void> _initializeApp() async {
    unawaited(_loadTheme().catchError((Object _) {}));
    try {
      await _checkLoginStatus().timeout(_startupTimeout);
    } on TimeoutException {
      debugPrint('Ares: timeout na inicialização — exibindo login.');
      _finishStartup(isUserLoggedIn: false, userName: '');
    } catch (error) {
      debugPrint('Ares: erro na inicialização: $error');
      _finishStartup(isUserLoggedIn: false, userName: '');
    }
    appReady = true;
    _tryLeaveSplash();
  }

  void _tryLeaveSplash() {
    if (!mounted || !appReady || !splashAnimationDone || !showSplash) {
      return;
    }
    _splashSafetyTimer?.cancel();
    setState(() {
      showSplash = false;
    });
  }

  void _onSplashComplete() {
    splashAnimationDone = true;
    _tryLeaveSplash();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (showSplash) {
      return;
    }
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      _backgroundLogoutTimer?.cancel();
      _backgroundLogoutTimer = null;
    }
    if (state == AppLifecycleState.resumed && _requiresLoginOnResume) {
      _requiresLoginOnResume = false;
      if (!mounted) {
        return;
      }
      AppContext.navigatorKey.currentState
          ?.popUntil((Route<dynamic> route) => route.isFirst);
      setState(() {
        isLoggedIn = false;
        nomeUsuario = '';
      });
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!isLoggedIn || _requiresLoginOnResume || AppContext.isProtectedUi) {
        return;
      }
      _backgroundLogoutTimer?.cancel();
      _backgroundLogoutTimer = Timer(_backgroundLogoutDelay, () {
        if (!mounted ||
            !isLoggedIn ||
            _requiresLoginOnResume ||
            AppContext.isProtectedUi) {
          return;
        }
        unawaited(_invalidateSessionForBackground());
      });
    }
  }

  Future<void> _invalidateSessionForBackground() async {
    if (!isLoggedIn || _requiresLoginOnResume) {
      return;
    }
    _requiresLoginOnResume = true;
    await AcessoLogService.registerLogoutAccess();
    await AuthService.logout();
  }

  Future<void> _clearSessionAndShowLogin({bool registerLogout = true}) async {
    if (registerLogout && isLoggedIn) {
      await AcessoLogService.registerLogoutAccess();
    }
    await AuthService.logout();
    if (!mounted) {
      return;
    }
    AppContext.navigatorKey.currentState
        ?.popUntil((Route<dynamic> route) => route.isFirst);
    setState(() {
      isLoggedIn = false;
      nomeUsuario = '';
    });
  }

  void _finishStartup({
    required bool isUserLoggedIn,
    required String userName,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      isLoggedIn = isUserLoggedIn;
      nomeUsuario = userName;
    });
  }

  void _onSessionExpired() {
    if (!mounted) {
      return;
    }
    setState(() {
      isLoggedIn = false;
      nomeUsuario = '';
    });
    final BuildContext? context = AppContext.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão expirada. Faça login novamente.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _checkLoginStatus() async {
    await AuthService.migrateSessionIfNeeded();
    final bool isUserLoggedIn = await AuthService.isLoggedIn();
    final String? userName = await AuthService.getUserName();
    _finishStartup(
      isUserLoggedIn: isUserLoggedIn,
      userName: userName ?? '',
    );
    if (isUserLoggedIn) {
      unawaited(_runPostLoginStartup());
    }
  }

  Future<void> _runPostLoginStartup() async {
    await AuthService.repairSessionCodusuIfNeeded();
    await AuthService.refreshUserProfileFromServer();
    unawaited(GoogleMapsApiKeyService.instance.syncFromServer());
    unawaited(AcessoLogService.registerAppAccess());
    _validateSessionInBackground();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTermsIfLoggedIn();
    });
  }

  void _checkTermsIfLoggedIn() {
    final BuildContext? context = AppContext.currentContext;
    if (context == null || !mounted) {
      return;
    }
    TermsCheckService.checkAndShowTerms(
      context,
      onTermsRejected: _handleTermsRejected,
    );
  }

  Future<void> _validateSessionInBackground() async {
    if (!ApiConfig.jwtRequired) {
      return;
    }
    final bool isTokenValid =
        await AuthService.validateTokenWithServer(silent: true);
    if (!isTokenValid && mounted) {
      setState(() {
        isLoggedIn = false;
        nomeUsuario = '';
      });
    }
  }

  Future<void> _loadTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool savedTheme = prefs.getBool('is_dark_theme') ?? false;
    if (!mounted) {
      return;
    }
    setState(() {
      isDarkTheme = savedTheme;
    });
  }

  void onLoginSuccess(String nome) {
    setState(() {
      isLoggedIn = true;
      nomeUsuario = nome;
    });
    unawaited(GoogleMapsApiKeyService.instance.syncFromServer());
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && AppContext.currentContext != null) {
        TermsCheckService.checkAndShowTerms(
          AppContext.currentContext!,
          onTermsRejected: _handleTermsRejected,
        );
      }
    });
  }

  Future<void> _handleTermsRejected() async {
    await AuthService.logout();
    if (!mounted) {
      return;
    }
    setState(() {
      isLoggedIn = false;
      nomeUsuario = '';
    });
  }

  Future<void> _handleExitApp() async {
    await _clearSessionAndShowLogin();
    SystemNavigator.pop();
  }

  Future<void> _handleLogout() async {
    await _clearSessionAndShowLogin();
  }

  void toggleTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkTheme = !isDarkTheme;
    });
    await prefs.setBool('is_dark_theme', isDarkTheme);
  }

  @override
  void dispose() {
    _backgroundLogoutTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _splashSafetyTimer?.cancel();
    if (AuthService.onSessionExpired == _onSessionExpired) {
      AuthService.onSessionExpired = null;
    }
    super.dispose();
  }

  Widget _buildMainScreen() {
    if (isLoggedIn) {
      return HomePage(
        userName: nomeUsuario,
        isDarkTheme: isDarkTheme,
        toggleTheme: toggleTheme,
        onLogout: _handleLogout,
        onExitApp: _handleExitApp,
      );
    }
    return LoginPage(
      onLogin: onLoginSuccess,
      isDarkTheme: isDarkTheme,
      onToggleTheme: toggleTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppContext.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'ARESIA',
      builder: (BuildContext context, Widget? child) {
        return child ?? const SizedBox.shrink();
      },
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('pt', 'BR'),
      home: showSplash
          ? SplashPage(onComplete: _onSplashComplete)
          : _buildMainScreen(),
    );
  }
}
