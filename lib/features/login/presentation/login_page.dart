import 'dart:async';

import 'package:flutter/material.dart';
import '../../privacy/presentation/privacy_policy_page.dart';
import '../../terms/presentation/terms_page.dart';
import '../models/empresa_model.dart';
import '../services/auth_service.dart';
import '../services/acesso_log_service.dart';
import '../widgets/login_logo.dart';

class LoginPage extends StatefulWidget {
  final void Function(String nomeUsuario) onLogin;
  final bool isDarkTheme;
  final VoidCallback onToggleTheme;

  const LoginPage({
    super.key,
    required this.onLogin,
    this.isDarkTheme = false,
    required this.onToggleTheme,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool rememberMe = true;
  bool obscurePassword = true;
  bool credentialsValidated = false;
  bool acceptedTerms = false;
  bool securityVerification = true;
  String? statusMessage;
  LoginResult? pendingLogin;
  String? selectedEmpresaId;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final Map<String, String?> credentials =
        await AuthService.getSavedCredentials();
    if (credentials['email'] != null) {
      emailController.text = credentials['email']!;
    }
    if (credentials['password'] != null) {
      passController.text = credentials['password']!;
    }
  }

  void _resetAfterCredentialChange() {
    setState(() {
      credentialsValidated = false;
      pendingLogin = null;
      selectedEmpresaId = null;
      statusMessage = null;
    });
  }

  EmpresaModel? get _selectedEmpresa {
    if (selectedEmpresaId == null || pendingLogin == null) {
      return null;
    }
    for (final EmpresaModel empresa in pendingLogin!.empresas) {
      if (empresa.id == selectedEmpresaId) {
        return empresa;
      }
    }
    return null;
  }

  bool get _canValidateCredentials {
    return emailController.text.trim().length > 4 &&
        passController.text.trim().length >= 6 &&
        !isLoading;
  }

  bool get _canEnter {
    return credentialsValidated &&
        selectedEmpresaId != null &&
        selectedEmpresaId!.isNotEmpty &&
        acceptedTerms &&
        securityVerification &&
        !isLoading;
  }

  Future<void> _validateCredentials() async {
    if (!_canValidateCredentials) {
      setState(() {
        statusMessage =
            'Informe e-mail e senha com ao menos 6 caracteres.';
      });
      return;
    }
    setState(() {
      isLoading = true;
      statusMessage = 'Validando usuário e empresas no servidor…';
    });
    FocusScope.of(context).unfocus();
    final LoginResult result = await AuthService.login(
      email: emailController.text.trim(),
      senha: passController.text,
    );
    if (!result.success || result.usuario == null) {
      setState(() {
        credentialsValidated = false;
        pendingLogin = null;
        selectedEmpresaId = null;
        isLoading = false;
        statusMessage = result.message ?? 'Login inválido';
      });
      return;
    }
    if (result.empresas.isEmpty) {
      setState(() {
        credentialsValidated = true;
        pendingLogin = result;
        selectedEmpresaId = null;
        isLoading = false;
        statusMessage =
            'Senha aceita, mas nenhuma empresa vinculada. '
            'Peça ao administrador para liberar o acesso.';
      });
      return;
    }
    setState(() {
      credentialsValidated = true;
      pendingLogin = result;
      selectedEmpresaId = result.empresas.first.id;
      isLoading = false;
      statusMessage = null;
    });
  }

  Future<void> _enterWithEmpresa() async {
    if (!_canEnter || pendingLogin == null || _selectedEmpresa == null) {
      return;
    }
    setState(() {
      isLoading = true;
      statusMessage = null;
    });
    try {
      await AuthService.saveSession(
        usuario: pendingLogin!.usuario!,
        empresa: _selectedEmpresa!,
        empresasFromLogin: pendingLogin!.empresas,
        token: pendingLogin!.token,
        rememberMe: rememberMe,
        savedEmail: emailController.text.trim(),
        savedPassword: passController.text,
      );
      await AuthService.repairSessionCodusuIfNeeded();
      await AcessoLogService.registerLoginAccess();
      if (mounted) {
        widget.onLogin(pendingLogin!.usuario!.nome);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          statusMessage = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (!credentialsValidated) {
      await _validateCredentials();
      return;
    }
    await _enterWithEmpresa();
  }

  void _openTermsPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TermsPage()),
    );
  }

  void _openPrivacyPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage()),
    );
  }

  Widget _buildTermsLabel() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color textColor = credentialsValidated
        ? scheme.onSurface
        : scheme.onSurfaceVariant;
    final Color linkColor = scheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: acceptedTerms,
          activeColor: scheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          onChanged: credentialsValidated
              ? (bool? value) {
                  setState(() {
                    acceptedTerms = value ?? false;
                  });
                }
              : null,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Li e aceito os ',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                GestureDetector(
                  onTap: _openTermsPage,
                  child: Text(
                    'Termos de Uso',
                    style: TextStyle(
                      fontSize: 13,
                      color: linkColor,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  ' e a ',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                GestureDetector(
                  onTap: _openPrivacyPage,
                  child: Text(
                    'Política de Privacidade',
                    style: TextStyle(
                      fontSize: 13,
                      color: linkColor,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final InputDecoration fieldDecoration = InputDecoration(
      labelStyle: TextStyle(color: scheme.primary),
      prefixIconColor: scheme.primary,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: scheme.surface,
      isDense: true,
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkTheme ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: widget.isDarkTheme ? 'Tema claro' : 'Tema escuro',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bem-vindo',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 12),
                LoginLogo(
                  empresa: credentialsValidated ? _selectedEmpresa : null,
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    children: const [
                      TextSpan(text: 'Identifique-se para utilizar '),
                      TextSpan(
                        text: 'DOMINA TECNOLOGIA',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !isLoading,
                  onChanged: (_) => _resetAfterCredentialChange(),
                  decoration: fieldDecoration.copyWith(
                    labelText: 'Usuário *',
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passController,
                  obscureText: obscurePassword,
                  enabled: !isLoading,
                  onChanged: (_) => _resetAfterCredentialChange(),
                  decoration: fieldDecoration.copyWith(
                    labelText: 'Senha *',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: scheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                if (credentialsValidated) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedEmpresaId,
                    isExpanded: true,
                    decoration: fieldDecoration.copyWith(
                      labelText: 'Empresa',
                      prefixIcon: const Icon(Icons.business),
                    ),
                    items: pendingLogin?.empresas
                            .map(
                              (EmpresaModel empresa) =>
                                  DropdownMenuItem<String>(
                                value: empresa.id,
                                child: Text(
                                  empresa.displayLabel,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList() ??
                        <DropdownMenuItem<String>>[],
                    onChanged: (pendingLogin?.empresas.isEmpty ?? true)
                        ? null
                        : (String? value) {
                            setState(() {
                              selectedEmpresaId = value;
                            });
                          },
                  ),
                ],
                if (!credentialsValidated) ...[
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        activeColor: scheme.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (bool? value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                      ),
                      Text(
                        'Lembrar-me',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
                _buildTermsLabel(),
                Row(
                  children: [
                    Checkbox(
                      value: securityVerification,
                      activeColor: scheme.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (bool? value) {
                        setState(() {
                          securityVerification = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Verificação de segurança',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 140,
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: isLoading ||
                              (!credentialsValidated
                                  ? !_canValidateCredentials
                                  : !_canEnter)
                          ? null
                          : _handlePrimaryAction,
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
                          : Text(
                              credentialsValidated ? 'Entrar' : 'Validar',
                            ),
                    ),
                  ),
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    statusMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusMessage!.contains('indisponível') ||
                              statusMessage!.contains('Erro') ||
                              statusMessage!.contains('inválid') ||
                              statusMessage!.contains('incorret')
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
