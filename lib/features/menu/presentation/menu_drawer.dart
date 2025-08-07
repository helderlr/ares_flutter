import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../model/menu_option.dart';

class MenuDrawer extends StatefulWidget {
  final List<MenuOption> cadastros;
  final List<MenuOption> movimentos;
  final List<MenuOption> outros;
  final String userName;
  final String userPhone;
  final void Function(MenuOption) onOptionTap;

  const MenuDrawer({
    required this.cadastros,
    required this.movimentos,
    required this.outros,
    required this.userName,
    required this.userPhone,
    required this.onOptionTap,
    super.key,
  });

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  File? avatarFile;
  String? avatarPath;
  File? userAvatarFile;
  String? userAvatarPath;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAvatar = prefs.getString('avatar_path');
    final savedUserAvatar = prefs.getString('user_avatar_path');

    // Verificar se os arquivos existem
    File? avatarFileToSet;
    String? avatarPathToSet;
    if (savedAvatar != null && savedAvatar.isNotEmpty) {
      final file = File(savedAvatar);
      if (await file.exists()) {
        avatarPathToSet = savedAvatar;
        avatarFileToSet = file;
      }
    }

    File? userAvatarFileToSet;
    String? userAvatarPathToSet;
    if (savedUserAvatar != null && savedUserAvatar.isNotEmpty) {
      final file = File(savedUserAvatar);
      if (await file.exists()) {
        userAvatarPathToSet = savedUserAvatar;
        userAvatarFileToSet = file;
      }
    }

    setState(() {
      avatarPath = avatarPathToSet;
      avatarFile = avatarFileToSet;
      userAvatarPath = userAvatarPathToSet;
      userAvatarFile = userAvatarFileToSet;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: AppColors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.primaryColor,
            ),
            accountName: const Text('Ares'),
            accountEmail: Text(widget.userName),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.white,
              backgroundImage:
                  (userAvatarFile != null) ? FileImage(userAvatarFile!) : null,
              child: (userAvatarFile == null)
                  ? const Icon(Icons.account_circle,
                      size: 48, color: AppColors.lightBlue)
                  : null,
            ),
          ),
          ExpansionTile(
            leading: const Icon(Icons.folder, color: Colors.black),
            title:
                const Text('Cadastros', style: TextStyle(color: Colors.black)),
            children: widget.cadastros
                .map((option) => ListTile(
                      leading: Icon(option.icon, color: Colors.black),
                      title: Text(option.title,
                          style: const TextStyle(color: Colors.black)),
                      onTap: () => widget.onOptionTap(option),
                    ))
                .toList(),
          ),
          ExpansionTile(
            leading: const Icon(Icons.event, color: Colors.black),
            title:
                const Text('Movimento', style: TextStyle(color: Colors.black)),
            children: widget.movimentos
                .map((option) => ListTile(
                      leading: Icon(option.icon, color: Colors.black),
                      title: Text(option.title,
                          style: const TextStyle(color: Colors.black)),
                      onTap: () => widget.onOptionTap(option),
                    ))
                .toList(),
          ),
          ...widget.outros.map((option) => ListTile(
                leading: Icon(option.icon, color: Colors.black),
                title: Text(option.title,
                    style: const TextStyle(color: Colors.black)),
                onTap: () => widget.onOptionTap(option),
              )),
        ],
      ),
    );
  }
}
