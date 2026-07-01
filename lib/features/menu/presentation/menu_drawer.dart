import 'package:flutter/material.dart';
import '../../../core/widgets/user_avatar.dart';
import '../model/menu_option.dart';

class MenuDrawer extends StatelessWidget {
  final List<MenuOption> atendimento;
  final List<MenuOption> faturamento;
  final List<MenuOption> estoque;
  final List<MenuOption> miscelanea;
  final List<MenuOption> footerOptions;
  final String userName;
  final String userPhone;
  final int avatarRefreshKey;
  final void Function(MenuOption) onOptionTap;

  const MenuDrawer({
    required this.atendimento,
    required this.faturamento,
    required this.estoque,
    required this.miscelanea,
    required this.footerOptions,
    required this.userName,
    required this.userPhone,
    this.avatarRefreshKey = 0,
    required this.onOptionTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color onSurface = scheme.onSurface;
    final Color onSurfaceVariant = scheme.onSurfaceVariant;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    UserAvatar(
                      key: ValueKey<int>(avatarRefreshKey),
                      radius: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ARESIA',
                            style: TextStyle(
                              color: onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Usuário',
                            style: TextStyle(
                              color: onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            userName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildExpansionSection(
            context: context,
            icon: Icons.medical_information_outlined,
            title: 'Atendimento',
            options: atendimento,
          ),
          _buildExpansionSection(
            context: context,
            icon: Icons.payments_outlined,
            title: 'Faturamento',
            options: faturamento,
          ),
          _buildExpansionSection(
            context: context,
            icon: Icons.inventory_2_outlined,
            title: 'Estoque',
            options: estoque,
          ),
          _buildExpansionSection(
            context: context,
            icon: Icons.apps_outlined,
            title: 'Miscelânea',
            options: miscelanea,
          ),
          const Divider(height: 1),
          for (final MenuOption option in footerOptions)
            ListTile(
              dense: true,
              leading: Icon(option.icon, color: onSurface, size: 22),
              title: Text(
                option.title,
                style: TextStyle(
                  color: onSurface,
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<MenuOption> options,
  }) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return ExpansionTile(
      leading: Icon(icon, color: onSurface, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: options
          .map(
            (MenuOption option) => ListTile(
              dense: true,
              leading: Icon(option.icon, color: onSurface, size: 20),
              title: Text(
                option.title,
                style: TextStyle(
                  color: onSurface,
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
