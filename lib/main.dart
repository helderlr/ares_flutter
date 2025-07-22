import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'core/theme/app_theme.dart';
import 'features/menu/presentation/menu_drawer.dart';
import 'features/menu/model/menu_option.dart';
import 'features/paciente/presentation/paciente_page.dart';
import 'features/configuracao/presentation/configuracao_page.dart';
import 'features/login/presentation/login_page.dart';
import 'features/login/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  HttpOverrides.global = MyHttpOverrides();
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

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;
  String nomeUsuario = '';
  bool isDarkTheme = false;
  bool isLoading = true;
  File? avatarFile;
  String? avatarPath;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadTheme();
  }

  Future<void> _checkLoginStatus() async {
    final isUserLoggedIn = await AuthService.isLoggedIn();
    final userName = await AuthService.getUserName();

    setState(() {
      isLoggedIn = isUserLoggedIn;
      nomeUsuario = userName ?? '';
      isLoading = false;
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getBool('is_dark_theme') ?? false;
    setState(() {
      isDarkTheme = savedTheme;
    });
  }

  void onLoginSuccess(String nome) {
    setState(() {
      isLoggedIn = true;
      nomeUsuario = nome;
    });
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkTheme = !isDarkTheme;
    });
    await prefs.setBool('is_dark_theme', isDarkTheme);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    setState(() {
      isLoggedIn = false;
      nomeUsuario = '';
    });
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do aplicativo'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      if (kReleaseMode) {
        SystemNavigator.pop();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ares Flutter',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final List<MenuOption> cadastros = [
      const MenuOption(title: 'Paciente', icon: Icons.person),
      const MenuOption(title: 'Médico', icon: Icons.medical_services),
      const MenuOption(title: 'Tipo Cirurgia', icon: Icons.healing),
      const MenuOption(title: 'Hospital', icon: Icons.local_hospital),
      const MenuOption(title: 'Convênio', icon: Icons.assignment),
    ];

    final List<MenuOption> movimentos = [
      const MenuOption(title: 'Agendamento', icon: Icons.event_available),
      const MenuOption(title: 'Remarcar', icon: Icons.update),
      const MenuOption(title: 'Cancelar', icon: Icons.cancel),
    ];

    final List<MenuOption> outros = [
      const MenuOption(title: 'Configuração', icon: Icons.settings),
      const MenuOption(title: 'Termos e Condições', icon: Icons.description),
      const MenuOption(
          title: 'Política de Privacidade', icon: Icons.privacy_tip),
      const MenuOption(title: 'Sair', icon: Icons.exit_to_app),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ares Flutter',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: isLoggedIn
          ? Builder(
              builder: (context) {
                void handleMenuOptionTap(MenuOption option) async {
                  Navigator.of(context).pop();
                  Future.delayed(const Duration(milliseconds: 250), () async {
                    if (option.title == 'Paciente') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PacientePage()),
                      );
                    } else if (option.title == 'Configuração') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ConfiguracaoPage()),
                      );
                    } else if (option.title == 'Sair') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sair do aplicativo'),
                          content: const Text(
                              'Deseja realmente sair do aplicativo?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(ctx).pop(true);
                                await _logout();
                              },
                              child: const Text('Sair'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _logout();
                      }
                    }
                  });
                }

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Home'),
                    actions: [
                      IconButton(
                        icon: Icon(
                            isDarkTheme ? Icons.light_mode : Icons.dark_mode),
                        onPressed: toggleTheme,
                      ),
                    ],
                  ),
                  drawer: MenuDrawer(
                    userName: nomeUsuario,
                    userPhone: '',
                    cadastros: cadastros,
                    movimentos: movimentos,
                    outros: outros,
                    onOptionTap: handleMenuOptionTap,
                  ),
                  body: const Center(child: Text('Conteúdo principal aqui')),
                );
              },
            )
          : LoginPage(onLogin: onLoginSuccess),
    );
  }
}

class Patient {
  final int id;
  final String name;
  final String birthDate;
  final String planCardNumber;

  const Patient({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.planCardNumber,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['codigo'] as int,
      name: json['nome'] as String,
      birthDate: json['dataNascimento'] as String,
      planCardNumber: json['carteira'] as String,
    );
  }
}

class PatientService {
  static const String baseUrl = 'http://45.162.242.43:3051';

  Future<List<Patient>> fetchAllPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/api/Paciente/list_paciente'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Patient.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load patients: ${response.statusCode} - ${response.body}');
    }
  }
}
