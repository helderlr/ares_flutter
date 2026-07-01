import 'package:flutter/material.dart';
import '../../features/terms/presentation/terms_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.lightBlue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'AresIA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versão 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Termos e Condições'),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Sobre'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'AresIA',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.medical_services, size: 48),
                children: [
                  const Text(
                    'Aplicativo para gerenciamento de agendamentos cirúrgicos.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}






