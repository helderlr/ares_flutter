import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../services/auth_service.dart'; // Usar o serviço original sem criptografia
import '../models/user_model.dart';

class LoginPage extends StatefulWidget {
  final void Function(String nomeUsuario) onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isLoading = false;
  File? logoFile;
  String? logoPath;

  @override
  void initState() {
    super.initState();
    _loadLogo();
    _loadFixedCredentials();
  }

  Future<void> _loadLogo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLogo = prefs.getString('avatar_path');

      if (savedLogo != null && savedLogo.isNotEmpty) {
        final file = File(savedLogo);
        if (await file.exists()) {
          setState(() {
            logoPath = savedLogo;
            logoFile = file;
          });
        } else {
          // Limpar o caminho inválido
          await prefs.remove('avatar_path');
          setState(() {
            logoPath = null;
            logoFile = null;
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar logo: $e');
      setState(() {
        logoPath = null;
        logoFile = null;
      });
    }
  }

  Future<void> _loadFixedCredentials() async {
    // Credenciais fixas para teste
    setState(() {
      userController.text = 'Administrador';
      passController.text = 'D9ENMxz+';
    });
  }

  Future<void> _login() async {
    if (formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });

      FocusScope.of(context).unfocus();

      print('🔍 INICIANDO LOGIN COM CREDENCIAIS FIXAS:');
      print('Usuário: ${userController.text.trim()}');
      print('Senha: ${passController.text.trim()}');

      final result = await AuthService.login(
        login: userController.text.trim(),
        senha: passController.text.trim(),
        nomusu: userController.text.trim(), // Usar login como nomusu
      );

      print('📋 RESULTADO DO LOGIN:');
      print('Success: ${result['success']}');
      print('Message: ${result['message']}');
      if (result.containsKey('data')) {
        print('Data: ${result['data']}');
      }

      if (result['success']) {
        final user = result['user'] as UserModel;
        print('✅ Usuário logado: ${user.nome}');

        // Salvar dados do usuário
        await AuthService.saveUserData(
          user: user,
          rememberMe: true, // Lembrar credenciais
          savedPassword: passController.text.trim(),
        );

        print('✅ Login realizado com sucesso');

        widget.onLogin(user.nome);
      } else {
        print('❌ Login falhou: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login inválido: ${result['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    color: AppColors.lightBlue.withOpacity(0.2),
                    child: (logoFile != null)
                        ? FutureBuilder<bool>(
                            future: logoFile!.exists(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data == true) {
                                return Image.file(
                                  logoFile!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person,
                                        size: 80, color: AppColors.lightBlue);
                                  },
                                );
                              } else {
                                return const Icon(Icons.person,
                                    size: 80, color: AppColors.lightBlue);
                              }
                            },
                          )
                        : const Icon(Icons.person,
                            size: 80, color: AppColors.lightBlue),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Seja bem-vindo',
                  style: TextStyle(
                    color: AppColors.lightBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '🔓 Credenciais Fixas para Teste',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: userController,
                  enabled: false, // Desabilitar edição
                  decoration: InputDecoration(
                    labelText: 'Nome de usuário (Fixo)',
                    labelStyle: const TextStyle(color: AppColors.lightBlue),
                    prefixIcon:
                        const Icon(Icons.person, color: AppColors.lightBlue),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Campo obrigatório'
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passController,
                  enabled: false, // Desabilitar edição
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Senha (Fixa)',
                    labelStyle: const TextStyle(color: AppColors.lightBlue),
                    prefixIcon:
                        const Icon(Icons.lock, color: AppColors.lightBlue),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Campo obrigatório'
                      : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBlue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Entrar'),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Credenciais fixas: Administrador / D9ENMxz+',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
