import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/atendimento_dashboard_model.dart';
import '../services/atendimento_analytics_service.dart';

class AtendimentoDashboardPage extends StatefulWidget {
  const AtendimentoDashboardPage({super.key});

  @override
  State<AtendimentoDashboardPage> createState() =>
      _AtendimentoDashboardPageState();
}

class _AtendimentoDashboardPageState extends State<AtendimentoDashboardPage> {
  final AtendimentoAnalyticsService _service = AtendimentoAnalyticsService();
  AtendimentoDashboardData? _data;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _referenceMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final AtendimentoDashboardData data = await _service.fetchDashboard(
        referenceMonth: _referenceMonth,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _referenceMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Selecione o mês',
    );
    if (picked == null) {
      return;
    }
    setState(() => _referenceMonth = DateTime(picked.year, picked.month, 1));
    await _loadDashboard();
  }

  String _formatMonthLabel(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatChartLabel(String mes) {
    if (mes.length < 7) {
      return mes;
    }
    final int month = int.tryParse(mes.substring(5, 7)) ?? 0;
    if (month < 1 || month > 12) {
      return mes;
    }
    const List<String> months = <String>[
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        title: const Text('Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMonthHeader(),
                        const SizedBox(height: 16),
                        _buildKpiGrid(),
                        const SizedBox(height: 20),
                        _buildChartCard(),
                        const SizedBox(height: 20),
                        _buildRankingCard(
                          title: 'Top médicos',
                          badge: 'Mês',
                          badgeColor: AppColors.lightBlue,
                          icon: Icons.person,
                          iconColor: AppColors.lightBlue,
                          items: _data?.topMedicos ?? const [],
                        ),
                        const SizedBox(height: 16),
                        _buildRankingCard(
                          title: 'Top hospitais',
                          badge: 'Mês',
                          badgeColor: Colors.green,
                          icon: Icons.local_hospital,
                          iconColor: Colors.green,
                          items: _data?.topHospitais ?? const [],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage ?? 'Erro ao carregar',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadDashboard,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      children: [
        const Text(
          'Visão do mês',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: _pickMonth,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMonthLabel(_referenceMonth),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid() {
    final AtendimentoDashboardData data = _data!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _buildKpiCard(
          title: 'Cirurgias',
          value: '${data.cirurgias}',
          subtitle: data.cirurgiasVariacaoPercent == null
              ? null
              : '${data.cirurgiasVariacaoPercent! >= 0 ? '+' : ''}${data.cirurgiasVariacaoPercent}% vs mês anterior',
          subtitleColor: Colors.green,
          background: const Color(0xFFE3F2FD),
          icon: Icons.medical_services,
        ),
        _buildKpiCard(
          title: 'Hospitais',
          value: '${data.hospitais}',
          subtitle: 'ativos no período',
          background: const Color(0xFFE8F5E9),
          icon: Icons.local_hospital,
        ),
        _buildKpiCard(
          title: 'Convênios',
          value: '${data.convenios}',
          subtitle: 'com produção',
          background: const Color(0xFFFFF8E1),
          icon: Icons.account_balance_wallet,
        ),
        _buildKpiCard(
          title: 'Taxa retorno',
          value: '${data.taxaRetornoPercent.toStringAsFixed(0)}%',
          subtitle: 'retornaram',
          background: const Color(0xFFFCE4EC),
          icon: Icons.sync,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    String? subtitle,
    Color? subtitleColor,
    required Color background,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(icon, color: Colors.black54),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor ?? Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final List<AtendimentoChartMonth> chart =
        _data?.chartMeses ?? const <AtendimentoChartMonth>[];
    final int maxValue = chart.fold<int>(
      0,
      (int previous, AtendimentoChartMonth item) =>
          item.total > previous ? item.total : previous,
    );
    final int currentTotal = _data?.cirurgias ?? 0;
    const int meta = 300;
    final bool metaAtingida = currentTotal >= meta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gráfico principal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cirurgias por mês',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _buildBadge('Últimos 6 meses', AppColors.lightBlue),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Meta: $meta cirurgias/mês',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const Spacer(),
                  Icon(
                    metaAtingida ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: metaAtingida ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    metaAtingida ? 'Meta atingida' : 'Abaixo da meta',
                    style: TextStyle(
                      fontSize: 12,
                      color: metaAtingida ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: chart.isEmpty
                    ? const Center(child: Text('Sem dados no período'))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: chart.map((AtendimentoChartMonth item) {
                          final double factor =
                              maxValue > 0 ? item.total / maxValue : 0;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.total}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: FractionallySizedBox(
                                        heightFactor: factor < 0.08 && item.total > 0
                                            ? 0.08
                                            : factor,
                                        widthFactor: 0.55,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.lightBlue,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatChartLabel(item.mes),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    required List<AtendimentoRankingItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildBadge(badge, badgeColor),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Sem dados no período'),
            )
          else
            ...items.map(
              (AtendimentoRankingItem item) => Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    title: Text(item.nome),
                    trailing: Text(
                      '${item.total}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (item != items.last)
                    Divider(color: Colors.grey.shade200, height: 1),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
