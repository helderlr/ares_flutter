import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../login/models/empresa_model.dart';
import '../../login/services/auth_service.dart';
import '../../menu/presentation/menu_drawer.dart';
import '../../menu/model/menu_option.dart';
import '../../legal/data/legal_content.dart';
import '../../legal/presentation/legal_document_page.dart';
import '../../paciente/presentation/paciente_page.dart';
import '../../medico/presentation/medico_page.dart';
import '../../hospital/presentation/hospital_page.dart';
import '../../convenio/presentation/convenio_page.dart';
import '../../tipo_cirurgia/presentation/tipo_cirurgia_page.dart';
import '../../agendamento/presentation/agendamento_page.dart';
import '../../configuracao/presentation/configuracao_page.dart';
import '../../registro_hora_cirurgia/presentation/registro_hora_cirurgia_page.dart';
import '../../atendimento/presentation/atendimento_dashboard_page.dart';
import '../../atendimento/presentation/atendimento_consultas_page.dart';
import '../../atendimento/presentation/atendimento_relatorios_page.dart';

class _HomeMenuItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _HomeMenuItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class HomePage extends StatefulWidget {
  final String userName;
  final bool isDarkTheme;
  final VoidCallback toggleTheme;
  final Future<void> Function() onLogout;
  final Future<void> Function() onExitApp;

  const HomePage({
    super.key,
    required this.userName,
    required this.isDarkTheme,
    required this.toggleTheme,
    required this.onLogout,
    required this.onExitApp,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _empresaTitle = '';

  @override
  void initState() {
    super.initState();
    _loadEmpresaTitle();
  }

  Future<void> _loadEmpresaTitle() async {
    final EmpresaModel? empresa = await AuthService.getCurrentEmpresa();
    if (!mounted) {
      return;
    }
    setState(() {
      _empresaTitle = empresa?.nome.trim() ?? '';
    });
  }

  void _showModuleInDevelopment(String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$moduleName — módulo em desenvolvimento'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<_HomeMenuItem> _buildAtendimentoItems() {
    return <_HomeMenuItem>[
      _HomeMenuItem(
        title: 'Dashboard',
        subtitle: 'KPIs e gráficos',
        icon: Icons.dashboard,
        color: Colors.green,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AtendimentoDashboardPage()),
        ),
      ),
      _HomeMenuItem(
        title: 'Consultas',
        subtitle: 'Rankings e resumos',
        icon: Icons.table_chart,
        color: Colors.orange,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AtendimentoConsultasPage()),
        ),
      ),
      _HomeMenuItem(
        title: 'Relatórios',
        subtitle: 'PDF / Excel / impressão',
        icon: Icons.description,
        color: Colors.pink,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AtendimentoRelatoriosPage()),
        ),
      ),
      _HomeMenuItem(
        title: 'Pacientes',
        icon: Icons.person,
        color: Colors.blue,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PacientePage()),
        ),
      ),
      _HomeMenuItem(
        title: 'Médicos',
        icon: Icons.medical_services,
        color: Colors.green,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MedicoPage()),
        ),
      ),
      _HomeMenuItem(
        title: 'Agenda',
        icon: Icons.event_available,
        color: Colors.orange,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AgendamentoPage()),
        ),
      ),
      _HomeMenuItem(
        title: 'Hospitais',
        icon: Icons.local_hospital,
        color: Colors.red,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HospitalPage()),
        ),
      ),
      _HomeMenuItem(
        title: 'Convênio',
        icon: Icons.assignment,
        color: Colors.purple,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConvenioPage()),
        ),
      ),
      _HomeMenuItem(
        title: 'Tipo Cirurgia',
        icon: Icons.healing,
        color: Colors.teal,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TipoCirurgiaPage()),
        ),
      ),
      _HomeMenuItem(
        title: 'Registro Hora',
        icon: Icons.access_time,
        color: Colors.indigo,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const RegistroHoraCirurgiaPage(),
          ),
        ),
      ),
    ];
  }

  List<_HomeMenuItem> _buildFaturamentoItems() {
    return <_HomeMenuItem>[
      _HomeMenuItem(
        title: 'Cliente',
        icon: Icons.people_outline,
        color: const Color(0xFF1565C0),
        onTap: () => _showModuleInDevelopment('Cliente'),
      ),
      _HomeMenuItem(
        title: 'Pedido',
        icon: Icons.shopping_cart_outlined,
        color: const Color(0xFF2E7D32),
        onTap: () => _showModuleInDevelopment('Pedido'),
      ),
      _HomeMenuItem(
        title: 'Orçamento',
        icon: Icons.request_quote_outlined,
        color: const Color(0xFFEF6C00),
        onTap: () => _showModuleInDevelopment('Orçamento'),
      ),
      _HomeMenuItem(
        title: 'Docto Saída',
        icon: Icons.output_outlined,
        color: const Color(0xFF6A1B9A),
        onTap: () => _showModuleInDevelopment('Docto Saída'),
      ),
      _HomeMenuItem(
        title: 'NFS-e',
        icon: Icons.cloud_upload_outlined,
        color: const Color(0xFFC62828),
        onTap: () => _showModuleInDevelopment('NFS-e'),
      ),
      _HomeMenuItem(
        title: 'Ordem Serviço',
        icon: Icons.build_circle_outlined,
        color: const Color(0xFF455A64),
        onTap: () => _showModuleInDevelopment('Ordem Serviço'),
      ),
      _HomeMenuItem(
        title: 'Prontuário',
        icon: Icons.folder_shared_outlined,
        color: const Color(0xFF5D4037),
        onTap: () => _showModuleInDevelopment('Prontuário'),
      ),
      _HomeMenuItem(
        title: 'GNRE',
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF00695C),
        onTap: () => _showModuleInDevelopment('GNRE'),
      ),
    ];
  }

  List<_HomeMenuItem> _buildEstoqueItems() {
    return <_HomeMenuItem>[
      _HomeMenuItem(
        title: 'Docto Entrada',
        icon: Icons.input_outlined,
        color: const Color(0xFF1565C0),
        onTap: () => _showModuleInDevelopment('Docto Entrada'),
      ),
      _HomeMenuItem(
        title: 'Requisição',
        icon: Icons.assignment_outlined,
        color: const Color(0xFF2E7D32),
        onTap: () => _showModuleInDevelopment('Requisição'),
      ),
      _HomeMenuItem(
        title: 'Movto Estoque',
        icon: Icons.swap_horiz_outlined,
        color: const Color(0xFFEF6C00),
        onTap: () => _showModuleInDevelopment('Movto Estoque'),
      ),
      _HomeMenuItem(
        title: 'Caixa Cirúrgica',
        icon: Icons.medical_services_outlined,
        color: const Color(0xFF6A1B9A),
        onTap: () => _showModuleInDevelopment('Caixa Cirúrgica'),
      ),
    ];
  }

  List<MenuOption> _buildAtendimentoMenuOptions() {
    return const <MenuOption>[
      MenuOption(title: 'Dashboard', icon: Icons.dashboard),
      MenuOption(title: 'Consultas', icon: Icons.table_chart),
      MenuOption(title: 'Relatórios', icon: Icons.description),
      MenuOption(title: 'Paciente', icon: Icons.person),
      MenuOption(title: 'Médico', icon: Icons.medical_services),
      MenuOption(title: 'Tipo Cirurgia', icon: Icons.healing),
      MenuOption(title: 'Hospital', icon: Icons.local_hospital),
      MenuOption(title: 'Convênio', icon: Icons.assignment),
      MenuOption(title: 'Agenda', icon: Icons.event_available),
      MenuOption(title: 'Registro Hora Cirurgia', icon: Icons.access_time),
    ];
  }

  List<MenuOption> _buildFaturamentoMenuOptions() {
    return const <MenuOption>[
      MenuOption(title: 'Cliente', icon: Icons.people_outline),
      MenuOption(title: 'Pedido', icon: Icons.shopping_cart_outlined),
      MenuOption(title: 'Orçamento', icon: Icons.request_quote_outlined),
      MenuOption(title: 'Docto Saída', icon: Icons.output_outlined),
      MenuOption(title: 'NFS-e', icon: Icons.cloud_upload_outlined),
      MenuOption(title: 'Ordem Serviço', icon: Icons.build_circle_outlined),
      MenuOption(title: 'Prontuário', icon: Icons.folder_shared_outlined),
      MenuOption(title: 'GNRE', icon: Icons.account_balance_outlined),
    ];
  }

  List<MenuOption> _buildEstoqueMenuOptions() {
    return const <MenuOption>[
      MenuOption(title: 'Docto Entrada', icon: Icons.input_outlined),
      MenuOption(title: 'Requisição', icon: Icons.assignment_outlined),
      MenuOption(title: 'Movto Estoque', icon: Icons.swap_horiz_outlined),
      MenuOption(title: 'Caixa Cirúrgica', icon: Icons.medical_services_outlined),
    ];
  }

  void _handleMenuOptionTap(MenuOption option) {
    Navigator.of(context).pop();
    final String title = option.title;
    if (title == 'Dashboard') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AtendimentoDashboardPage()),
      );
      return;
    }
    if (title == 'Consultas') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AtendimentoConsultasPage()),
      );
      return;
    }
    if (title == 'Relatórios') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AtendimentoRelatoriosPage()),
      );
      return;
    }
    if (title == 'Paciente') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PacientePage()),
      );
      return;
    }
    if (title == 'Médico') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MedicoPage()),
      );
      return;
    }
    if (title == 'Hospital') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HospitalPage()),
      );
      return;
    }
    if (title == 'Convênio') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ConvenioPage()),
      );
      return;
    }
    if (title == 'Tipo Cirurgia') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TipoCirurgiaPage()),
      );
      return;
    }
    if (title == 'Agenda') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AgendamentoPage()),
      );
      return;
    }
    if (title == 'Registro Hora Cirurgia') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const RegistroHoraCirurgiaPage(),
        ),
      );
      return;
    }
    if (title == 'Miscelânea') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ConfiguracaoPage()),
      );
      return;
    }
    if (title == 'Termos e Condições') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LegalDocumentPage(
            title: 'Termos e Condições',
            subtitle: 'Aresia — DOMINA TECNOLOGIA',
            updatedAt: LegalContent.termsUpdatedAt,
            sections: LegalContent.termsSections,
          ),
        ),
      );
      return;
    }
    if (title == 'Política de Privacidade') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LegalDocumentPage(
            title: 'Política de Privacidade',
            subtitle: 'Aresia — DOMINA TECNOLOGIA',
            updatedAt: LegalContent.privacyUpdatedAt,
            sections: LegalContent.privacySections,
          ),
        ),
      );
      return;
    }
    if (title == 'Sair') {
      _executeExit();
      return;
    }
    _showModuleInDevelopment(title);
  }

  Future<void> _executeExit() async {
    await widget.onExitApp();
  }

  @override
  Widget build(BuildContext context) {
    final List<MenuOption> footerOptions = <MenuOption>[
      const MenuOption(title: 'Miscelânea', icon: Icons.apps_outlined),
      const MenuOption(title: 'Termos e Condições', icon: Icons.description),
      const MenuOption(
        title: 'Política de Privacidade',
        icon: Icons.privacy_tip,
      ),
      const MenuOption(title: 'Sair', icon: Icons.exit_to_app),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        title: Text(
          _empresaTitle.isNotEmpty ? _empresaTitle : 'ARESIA',
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkTheme ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      drawer: MenuDrawer(
        userName: widget.userName,
        userPhone: '',
        atendimento: _buildAtendimentoMenuOptions(),
        faturamento: _buildFaturamentoMenuOptions(),
        estoque: _buildEstoqueMenuOptions(),
        footerOptions: footerOptions,
        onOptionTap: _handleMenuOptionTap,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppColors.lightBlue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    widget.userName.isNotEmpty
                        ? widget.userName.toUpperCase()
                        : 'USUÁRIO',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.logoGreen,
                        ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Gerencie pacientes, médicos, agendas e muito mais.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            _buildSectionTitle(context, 'Atendimento', Icons.medical_information_outlined),
            const SizedBox(height: 16.0),
            _buildMenuGrid(
              context: context,
              items: _buildAtendimentoItems(),
              crossAxisCount: 3,
              childAspectRatio: 0.78,
            ),
            const SizedBox(height: 28.0),
            _buildSectionTitle(context, 'Faturamento', Icons.payments_outlined),
            const SizedBox(height: 16.0),
            _buildMenuGrid(
              context: context,
              items: _buildFaturamentoItems(),
              crossAxisCount: 3,
              childAspectRatio: 0.88,
            ),
            const SizedBox(height: 28.0),
            _buildSectionTitle(context, 'Estoque', Icons.inventory_2_outlined),
            const SizedBox(height: 16.0),
            _buildMenuGrid(
              context: context,
              items: _buildEstoqueItems(),
              crossAxisCount: 3,
              childAspectRatio: 0.88,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.lightBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                letterSpacing: 0.1,
              ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid({
    required BuildContext context,
    required List<_HomeMenuItem> items,
    required int crossAxisCount,
    double childAspectRatio = 1.2,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final _HomeMenuItem item = items[index];
        return _buildMenuCard(
          context: context,
          title: item.title,
          subtitle: item.subtitle,
          icon: item.icon,
          color: item.color,
          onTap: item.onTap,
        );
      },
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24.0, color: color),
            ),
            const SizedBox(height: 6.0),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    height: 1.2,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Colors.grey[600],
                      height: 1.1,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
