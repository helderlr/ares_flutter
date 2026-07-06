import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../login/services/auth_service.dart';
import '../models/performance_home_model.dart';
import '../services/performance_operacional_service.dart';
import '../utils/performance_formatters.dart';
import '../widgets/performance_goal_card.dart';
import '../widgets/performance_quick_actions.dart';
import '../widgets/performance_score_card.dart';
import 'performance_atividades_page.dart';
import 'performance_comparativo_page.dart';
import 'performance_desempenho_page.dart';
import 'performance_evolution_page.dart';
import 'performance_frequencia_page.dart';
import 'performance_gestor_page.dart';
import 'performance_horas_page.dart';
import 'performance_medalhas_page.dart';
import 'performance_metas_page.dart';
import 'performance_ranking_page.dart';

class PerformanceOperacionalHubPage extends StatefulWidget {
  const PerformanceOperacionalHubPage({super.key});

  @override
  State<PerformanceOperacionalHubPage> createState() =>
      _PerformanceOperacionalHubPageState();
}

class _PerformanceOperacionalHubPageState
    extends State<PerformanceOperacionalHubPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  int _selectedIndex = 0;
  int _reloadToken = 0;
  bool _isAdmin = false;
  PerformanceHomeData? _homeData;
  bool _isLoading = true;
  DateTime _referenceMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final permissions = await AuthService.getUserPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _isAdmin = permissions.isAdmin;
      if (!permissions.isAdmin) {
        _referenceMonth = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          1,
        );
      }
    });
    await _loadHome();
  }

  Future<void> _loadHome() async {
    setState(() => _isLoading = true);
    try {
      final PerformanceHomeData data = await _service.fetchHome(
        referenceMonth: _referenceMonth,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _homeData = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMonth() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas administradores podem consultar meses anteriores.'),
        ),
      );
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _referenceMonth,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year, now.month + 1, 0),
      helpText: 'Selecione o mês',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _referenceMonth = DateTime(picked.year, picked.month, 1);
      _reloadToken++;
    });
    await _loadHome();
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void _reloadTabs() {
    setState(() => _reloadToken++);
    _loadHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Performance Operacional'),
            if (_isAdmin)
              Text(
                PerformanceFormatters.formatMonthLabel(_referenceMonth),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        actions: <Widget>[
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Selecionar mês',
              onPressed: _pickMonth,
            ),
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.dashboard_outlined),
              tooltip: 'Dashboard Gestor',
              onPressed: () => _navigateTo(
                PerformanceGestorPage(referenceMonth: _referenceMonth),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadTabs,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          _buildHomeTab(),
          PerformanceRankingPage(
            key: ValueKey<String>('ranking-$_reloadToken'),
            referenceMonth: _referenceMonth,
          ),
          PerformanceDesempenhoPage(
            key: ValueKey<String>('desempenho-$_reloadToken'),
            referenceMonth: _referenceMonth,
          ),
          PerformanceEvolutionPage(
            key: ValueKey<String>('evolution-$_reloadToken'),
            referenceMonth: _referenceMonth,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Ranking'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Desempenho'),
          NavigationDestination(icon: Icon(Icons.show_chart_outlined), selectedIcon: Icon(Icons.show_chart), label: 'Evolução'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final PerformanceHomeData data = _homeData ??
        PerformanceHomeData(
          userName: 'Usuário',
          score: 0,
          scorePercent: 0,
          starCount: 0,
          levelLabel: '',
          goalTarget: 500,
          goalCurrent: 0,
          goalPercent: 0,
          hoursTodayMinutes: 0,
          activitiesToday: 0,
          rankingPosition: 0,
        );
    return RefreshIndicator(
      onRefresh: _loadHome,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Olá, ${data.userName}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (data.rankingPosition > 0) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              '${data.rankingPosition}º no ranking do mês',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          PerformanceScoreCard(
            score: data.score,
            scorePercent: data.scorePercent,
            starCount: data.starCount,
            levelLabel: data.levelLabel,
          ),
          const SizedBox(height: 12),
          PerformanceGoalProgressCard(
            current: data.goalCurrent,
            target: data.goalTarget,
            percent: data.goalPercent,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              PerformanceStatMiniCard(
                label: 'Horas hoje',
                value: PerformanceFormatters.formatHoursMinutes(data.hoursTodayMinutes),
                icon: Icons.schedule,
              ),
              const SizedBox(width: 12),
              PerformanceStatMiniCard(
                label: 'Atividades hoje',
                value: PerformanceFormatters.formatNumber(data.activitiesToday),
                icon: Icons.bolt,
                iconColor: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          PerformanceQuickActionGrid(
            actions: <PerformanceQuickAction>[
              PerformanceQuickAction(
                label: 'Ranking',
                icon: Icons.emoji_events,
                color: const Color(0xFFFFB300),
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              PerformanceQuickAction(
                label: 'Desempenho',
                icon: Icons.insights,
                color: AppColors.lightBlue,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              PerformanceQuickAction(
                label: 'Evolução',
                icon: Icons.show_chart,
                color: const Color(0xFF8E24AA),
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              PerformanceQuickAction(
                label: 'Medalhas',
                icon: Icons.military_tech,
                color: const Color(0xFF43A047),
                onTap: () => _navigateTo(
                  PerformanceMedalhasPage(referenceMonth: _referenceMonth),
                ),
              ),
              PerformanceQuickAction(
                label: 'Horas',
                icon: Icons.access_time,
                color: const Color(0xFF1E88E5),
                onTap: () => _navigateTo(const PerformanceHorasPage()),
              ),
              PerformanceQuickAction(
                label: 'Frequência',
                icon: Icons.calendar_month,
                color: const Color(0xFFE53935),
                onTap: () => _navigateTo(
                  PerformanceFrequenciaPage(referenceMonth: _referenceMonth),
                ),
              ),
              PerformanceQuickAction(
                label: 'Atividades',
                icon: Icons.history,
                color: const Color(0xFF6D4C41),
                onTap: () => _navigateTo(const PerformanceAtividadesPage()),
              ),
              PerformanceQuickAction(
                label: 'Metas',
                icon: Icons.flag,
                color: const Color(0xFF00ACC1),
                onTap: () => _navigateTo(
                  PerformanceMetasPage(referenceMonth: _referenceMonth),
                ),
              ),
              PerformanceQuickAction(
                label: 'Comparativo',
                icon: Icons.compare_arrows,
                color: const Color(0xFF3949AB),
                onTap: () => _navigateTo(
                  PerformanceComparativoPage(referenceMonth: _referenceMonth),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
