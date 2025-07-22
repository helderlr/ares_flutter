import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

class ConfiguracaoPage extends StatefulWidget {
  const ConfiguracaoPage({super.key});

  @override
  State<ConfiguracaoPage> createState() => _ConfiguracaoPageState();
}

class _ConfiguracaoPageState extends State<ConfiguracaoPage> {
  final TextEditingController ipController = TextEditingController();
  String? ipError;
  File? avatarFile;
  String? avatarPath;
  File? userAvatarFile;
  String? userAvatarPath;

  final RegExp ipRegex = RegExp(
    r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('remote_ip') ?? '';
    final savedAvatar = prefs.getString('avatar_path');
    final savedUserAvatar = prefs.getString('user_avatar_path');
    setState(() {
      ipController.text = savedIp;
      avatarPath = savedAvatar;
      if (avatarPath != null &&
          avatarPath!.isNotEmpty &&
          File(avatarPath!).existsSync()) {
        avatarFile = File(avatarPath!);
      } else {
        avatarFile = null;
        avatarPath = null;
        prefs.remove('avatar_path');
      }
      userAvatarPath = savedUserAvatar;
      if (userAvatarPath != null &&
          userAvatarPath!.isNotEmpty &&
          File(userAvatarPath!).existsSync()) {
        userAvatarFile = File(userAvatarPath!);
      } else {
        userAvatarFile = null;
        userAvatarPath = null;
        prefs.remove('user_avatar_path');
      }
    });
  }

  void validateIp(String value) {
    setState(() {
      if (value.isEmpty) {
        ipError = 'Informe o IP remoto';
      } else if (!ipRegex.hasMatch(value)) {
        ipError = 'IP inválido';
      } else {
        ipError = null;
      }
    });
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        avatarFile = File(picked.path);
        avatarPath = picked.path;
      });
    }
  }

  Future<void> pickUserAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        userAvatarFile = File(picked.path);
        userAvatarPath = picked.path;
      });
    }
  }

  Future<void> saveConfig() async {
    if (ipError != null || ipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um IP válido para salvar.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remote_ip', ipController.text);
    if (avatarPath != null) {
      await prefs.setString('avatar_path', avatarPath!);
    }
    if (userAvatarPath != null) {
      await prefs.setString('user_avatar_path', userAvatarPath!);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações salvas com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(
            color: AppColors.lightBlue,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.lightBlue),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  color: AppColors.lightBlue.withOpacity(0.2),
                  child: (avatarFile != null && avatarFile!.existsSync())
                      ? Image.file(
                          avatarFile!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person,
                                size: 56, color: AppColors.lightBlue);
                          },
                        )
                      : const Icon(Icons.person,
                          size: 56, color: AppColors.lightBlue),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: pickAvatar,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'IP Remoto',
            style: TextStyle(
              color: AppColors.lightBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ipController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ex: 192.168.0.1',
              errorText: ipError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightBlue),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.lightBlue, width: 2),
              ),
            ),
            style: const TextStyle(
                color: AppColors.lightBlue, fontWeight: FontWeight.bold),
            onChanged: validateIp,
          ),
          const SizedBox(height: 8),
          const Text(
            'Digite um IP válido na faixa 0.0.0.0 a 255.255.255.255',
            style: TextStyle(color: AppColors.lightBlue, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.lightBlue.withOpacity(0.2),
                  backgroundImage:
                      (userAvatarFile != null && userAvatarFile!.existsSync())
                          ? FileImage(userAvatarFile!)
                          : null,
                  child: (userAvatarFile == null ||
                          !(userAvatarFile!.existsSync()))
                      ? const Icon(Icons.account_circle,
                          size: 56, color: AppColors.lightBlue)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: pickUserAvatar,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Foto do usuário',
              style: TextStyle(
                  color: AppColors.lightBlue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Salvar configurações'),
                  content:
                      const Text('Deseja realmente salvar as configurações?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await saveConfig();
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
