import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../model/menu_option.dart';

class MenuDrawer extends StatelessWidget {
  final List<MenuOption> atendimento;
  final List<MenuOption> faturamento;
  final List<MenuOption> estoque;
  final List<MenuOption> footerOptions;
  final String userName;
  final String userPhone;
  final void Function(MenuOption) onOptionTap;

  const MenuDrawer({
    required this.atendimento,
    required this.faturamento,
    required this.estoque,
    required this.footerOptions,
    required this.userName,
    required this.userPhone,
    required this.onOptionTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'ARESIA',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Usuário',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildExpansionSection(
            icon: Icons.medical_information_outlined,
            title: 'Atendimento',
            options: atendimento,
          ),
          _buildExpansionSection(
            icon: Icons.payments_outlined,
            title: 'Faturamento',
            options: faturamento,
          ),
          _buildExpansionSection(
            icon: Icons.inventory_2_outlined,
            title: 'Estoque',
            options: estoque,
          ),
          const Divider(height: 1),
          for (final MenuOption option in footerOptions)
            ListTile(
              dense: true,
              leading: Icon(option.icon, color: Colors.black87, size: 22),
              title: Text(
                option.title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
              onTap: () => onOptionTap(option),
            ),
        ],
      ),
    );
  }

  Widget _buildExpansionSection({
    required IconData icon,
    required String title,
    required List<MenuOption> options,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: options
          .map(
            (MenuOption option) => ListTile(
              dense: true,
              leading: Icon(option.icon, color: Colors.black87, size: 20),
              title: Text(
                option.title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
              onTap: () => onOptionTap(option),
            ),
          )
          .toList(),
    );
  }
}
