import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../services/auth_service.dart';
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
  bool rememberMe = false;
  bool isLoading = false;
  File? logoFile;
  String? logoPath;

  @override
  void initState() {
    super.initState();
    _loadLogo();
    _loadSavedCredentials();
  }

  Future<void> _loadLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLogo = prefs.getString('avatar_path');
    if (savedLogo != null &&
        savedLogo.isNotEmpty &&
        File(savedLogo).existsSync()) {
      setState(() {
        logoPath = savedLogo;
        logoFile = File(savedLogo);
      });
    }
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await AuthService.getSavedCredentials();
    if (credentials['login'] != null && credentials['password'] != null) {
      setState(() {
        userController.text = credentials['login']!;
        passController.text = credentials['password']!;
        rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    if (formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });

      FocusScope.of(context).unfocus();

      print('🔍 INICIANDO LOGIN:');
      print('Usuário: ${userController.text.trim()}');
      print('Senha: ${passController.text.trim()}');
      print('Remember Me: $rememberMe');

      final result = await AuthService.login(
        login: userController.text.trim(),
        senha: passController.text.trim(),
        nomusu: userController.text.trim(),
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

        await AuthService.saveUserData(
          user: user,
          rememberMe: rememberMe,
          savedPassword: rememberMe ? passController.text.trim() : null,
        );

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
                    width: 96,
                    height: 96,
                    color: AppColors.lightBlue.withOpacity(0.2),
                    child: (logoFile != null && logoFile!.existsSync())
                        ? Image.file(logoFile!, fit: BoxFit.cover)
                        : const Icon(Icons.person,
                            size: 56, color: AppColors.lightBlue),
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
                const SizedBox(height: 32),
                TextFormField(
                  controller: userController,
                  decoration: const InputDecoration(
                    labelText: 'Nome de usuário',
                    labelStyle: TextStyle(color: AppColors.lightBlue),
                    prefixIcon: Icon(Icons.person, color: AppColors.lightBlue),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Campo obrigatório'
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    labelStyle: TextStyle(color: AppColors.lightBlue),
                    prefixIcon: Icon(Icons.lock, color: AppColors.lightBlue),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Campo obrigatório'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      activeColor: AppColors.lightBlue,
                      onChanged: (value) {
                        setState(() {
                          rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Me lembre',
                      style: TextStyle(color: AppColors.lightBlue),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // ação de recuperar senha
                      },
                      child: const Text(
                        'Recuperar senha?',
                        style: TextStyle(
                          color: AppColors.lightBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
