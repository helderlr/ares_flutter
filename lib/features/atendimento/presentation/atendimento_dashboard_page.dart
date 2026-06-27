import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/screen_capture_service.dart';
import '../../../core/widgets/share_format_sheet.dart';
import '../../login/services/auth_service.dart';
import '../models/atendimento_dashboard_model.dart';
import '../services/atendimento_analytics_service.dart';
import '../services/atendimento_share_service.dart';

class AtendimentoDashboardPage extends StatefulWidget {
  const AtendimentoDashboardPage({super.key});

  @override
  State<AtendimentoDashboardPage> createState() =>
      _AtendimentoDashboardPageState();
}

class _AtendimentoDashboardPageState extends State<AtendimentoDashboardPage> {
  final AtendimentoAnalyticsService _service = AtendimentoAnalyticsService();
  final AtendimentoShareService _shareService = AtendimentoShareService();
  final GlobalKey _shareKey = GlobalKey();
  AtendimentoDashboardData? _data;
  bool _isLoading = true;
  bool _isSharing = false;
  String? _errorMessage;
  DateTime _referenceMonth = DateTime.now();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadDashboard();
  }

  Future<void> _loadPermissions() async {
    final permissions = await AuthService.getUserPermissions();
    if (!mounted) {
      return;
    }
    final DateTime now = DateTime.now();
    setState(() {
      _isAdmin = permissions.isAdmin;
      if (!permissions.isAdmin) {
        _referenceMonth = DateTime(now.year, now.month, 1);
      }
    });
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

  DateTime get _currentMonthEnd {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _referenceMonth,
      firstDate: DateTime(2020, 1, 1),
      lastDate: _currentMonthEnd,
      helpText: 'Selecione o mês',
      initialDatePickerMode: DatePickerMode.day,
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
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          if (!_isLoading && _data != null)
            IconButton(
              onPressed: _isSharing ? null : _shareDashboard,
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              tooltip: 'Compartilhar',
            ),
        ],
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
                    child: RepaintBoundary(
                      key: _shareKey,
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMonthHeader(),
                            const SizedBox(height: 12),
                            _buildKpiGrid(),
                            const SizedBox(height: 12),
                            _buildChartCard(),
                            const SizedBox(height: 12),
                            _buildRankingsGrid(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Future<void> _shareDashboard() async {
    if (_data == null) {
      return;
    }
    final ShareFormat? format = await ShareFormatSheet.show(context);
    if (format == null || !mounted) {
      return;
    }
    setState(() => _isSharing = true);
    try {
      if (format == ShareFormat.image) {
        final Uint8List? bytes = await ScreenCaptureService.capturePng(_shareKey);
        if (bytes == null) {
          throw Exception('Não foi possível capturar a imagem.');
        }
        await ScreenCaptureService.sharePngBytes(
          bytes: bytes,
          fileName: 'dashboard_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Dashboard Ares',
        );
      } else {
        final Uint8List pdf = await _shareService.buildDashboardPdf(
          data: _data!,
          periodLabel: _formatMonthLabel(_referenceMonth),
        );
        await ScreenCaptureService.sharePdfFile(
          bytes: pdf,
          fileName: 'dashboard_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Dashboard Ares',
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
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
            const SizedBox(height: 12),
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Visão do mês',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        InkWell(
          onTap: _pickMonth,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMonthLabel(_referenceMonth),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Icon(
                  _isAdmin ? Icons.calendar_today : Icons.lock_outline,
                  size: 16,
                ),
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
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.55,
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
          title: 'Médicos',
          value: '${data.medicos}',
          subtitle: 'com cirurgias',
          background: const Color(0xFFE8EAF6),
          icon: Icons.person,
        ),
        _buildKpiCard(
          title: 'Tipos cirurgia',
          value: '${data.tiposCirurgia}',
          subtitle: 'no período',
          background: const Color(0xFFE0F2F1),
          icon: Icons.healing,
        ),
        _buildKpiCard(
          title: 'Taxa aprov.',
          value: '${data.taxaAproveitamentoPercent.toStringAsFixed(0)}%',
          subtitle: 'realizadas / total',
          background: const Color(0xFFFCE4EC),
          icon: Icons.trending_up,
          onInfoTap: _showTaxaAproveitamentoInfo,
        ),
      ],
    );
  }

  void _showTaxaAproveitamentoInfo() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Taxa aproveitamento'),
          content: const Text(
            'Taxa de Aproveitamento =\n'
            '(Cirurgias realizadas ÷ (Realizadas + Canceladas)) × 100\n\n'
            'Realizadas: agendas não canceladas no período.\n'
            'Canceladas: agenda_cancelada = S no período.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    String? subtitle,
    Color? subtitleColor,
    required Color background,
    required IconData icon,
    VoidCallback? onInfoTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color cardBg = isDark ? scheme.surface : background;
    final Color titleColor = isDark ? scheme.onSurface : Colors.black87;
    final Color valueColor = isDark ? scheme.onSurface : Colors.black87;
    final Color subColor = subtitleColor ??
        (isDark ? scheme.onSurfaceVariant : Colors.black54);
    final Color iconColor = isDark ? titleColor : Colors.black54;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: background.withOpacity(0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: titleColor,
                  ),
                ),
              ),
              if (onInfoTap != null)
                InkWell(
                  onTap: onInfoTap,
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: titleColor,
                  ),
                ),
              Icon(icon, color: iconColor, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: subColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cirurgias por mês',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildBadge('Últimos 6 meses', AppColors.lightBlue),
                  Text(
                    'Meta: $meta/mês',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        metaAtingida ? Icons.check_circle : Icons.info_outline,
                        size: 14,
                        color: metaAtingida ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        metaAtingida ? 'Meta atingida' : 'Abaixo da meta',
                        style: TextStyle(
                          fontSize: 11,
                          color: metaAtingida ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
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
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FittedBox(
                                    child: Text(
                                      '${item.total}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                        widthFactor: 0.6,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.lightBlue,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    child: Text(
                                      _formatChartLabel(item.mes),
                                      style: const TextStyle(fontSize: 10),
                                    ),
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

  Widget _buildRankingsGrid() {
    final AtendimentoDashboardData data = _data!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRankingCard(
          title: 'Top médicos',
          badge: 'Mês',
          badgeColor: AppColors.lightBlue,
          icon: Icons.person,
          iconColor: AppColors.lightBlue,
          items: data.topMedicos,
        ),
        const SizedBox(height: 12),
        _buildRankingCard(
          title: 'Top hospitais',
          badge: 'Mês',
          badgeColor: Colors.green,
          icon: Icons.local_hospital,
          iconColor: Colors.green,
          items: data.topHospitais,
        ),
        const SizedBox(height: 12),
        _buildRankingCard(
          title: 'Top tipos cirurgia',
          badge: 'Mês',
          badgeColor: Colors.teal,
          icon: Icons.healing,
          iconColor: Colors.teal,
          items: data.topTiposCirurgia,
        ),
        const SizedBox(height: 12),
        _buildRankingCard(
          title: 'Top convênios',
          badge: 'Mês',
          badgeColor: Colors.orange,
          icon: Icons.account_balance_wallet,
          iconColor: Colors.orange,
          items: data.topConvenios,
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              _buildBadge(badge, badgeColor),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Sem dados no período',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            ...items.map(
              (AtendimentoRankingItem item) => Column(
                children: [
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 16),
                    ),
                    title: Text(
                      item.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Text(
                      '${item.total}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (item != items.last)
                    Divider(color: scheme.outlineVariant, height: 1),
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
