import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_comparativo_model.dart';
import '../models/performance_ranking_model.dart';
import '../services/performance_operacional_service.dart';
import '../utils/performance_formatters.dart';
import '../widgets/performance_score_card.dart';

class PerformanceComparativoPage extends StatefulWidget {
  final DateTime referenceMonth;
  final int? initialCompareCodusu;

  const PerformanceComparativoPage({
    super.key,
    required this.referenceMonth,
    this.initialCompareCodusu,
  });

  @override
  State<PerformanceComparativoPage> createState() =>
      _PerformanceComparativoPageState();
}

class _PerformanceComparativoPageState extends State<PerformanceComparativoPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  PerformanceComparativoData? _data;
  List<PerformanceRankingEntry> _users = <PerformanceRankingEntry>[];
  int? _selectedCodusu;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCodusu = widget.initialCompareCodusu;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final PerformanceRankingData ranking = await _service.fetchRanking(
        referenceMonth: widget.referenceMonth,
        limit: 100,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _users = ranking.entries;
        if (_selectedCodusu == null && ranking.entries.length > 1) {
          _selectedCodusu = ranking.entries[1].codusu;
        }
      });
      await _loadComparativo();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadComparativo() async {
    if (_selectedCodusu == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final PerformanceComparativoData data = await _service.fetchComparativo(
        codusuB: _selectedCodusu!,
        referenceMonth: widget.referenceMonth,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparativo'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  DropdownButtonFormField<int>(
                    value: _selectedCodusu,
                    decoration: InputDecoration(
                      labelText: 'Comparar com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _users
                        .map(
                          (PerformanceRankingEntry entry) =>
                              DropdownMenuItem<int>(
                            value: entry.codusu,
                            child: Text(entry.nome),
                          ),
                        )
                        .toList(),
                    onChanged: (int? value) {
                      setState(() => _selectedCodusu = value);
                      _loadComparativo();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_data != null) ...<Widget>[
                    _ComparativoTable(
                      userA: _data!.userA,
                      userB: _data!.userB,
                    ),
                    const SizedBox(height: 16),
                    _ComparativoBar(
                      label: 'Horas',
                      valueA: _data!.userA.horasMinutes.toDouble(),
                      valueB: _data!.userB.horasMinutes.toDouble(),
                      format: (double v) =>
                          PerformanceFormatters.formatHoursMinutes(v.round()),
                    ),
                    const SizedBox(height: 12),
                    _ComparativoBar(
                      label: 'Operações',
                      valueA: _data!.userA.operacoes.toDouble(),
                      valueB: _data!.userB.operacoes.toDouble(),
                      format: (double v) => v.round().toString(),
                    ),
                    const SizedBox(height: 12),
                    _ComparativoBar(
                      label: 'Pontuação',
                      valueA: _data!.userA.pontuacao.toDouble(),
                      valueB: _data!.userB.pontuacao.toDouble(),
                      format: (double v) => v.round().toString(),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ComparativoTable extends StatelessWidget {
  final PerformanceComparativoUser userA;
  final PerformanceComparativoUser userB;

  const _ComparativoTable({
    required this.userA,
    required this.userB,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    userA.nome,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    userB.nome,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _ComparativoRow(
              label: 'Horas',
              valueA: PerformanceFormatters.formatHoursMinutes(userA.horasMinutes),
              valueB: PerformanceFormatters.formatHoursMinutes(userB.horasMinutes),
            ),
            _ComparativoRow(
              label: 'Operações',
              valueA: '${userA.operacoes}',
              valueB: '${userB.operacoes}',
            ),
            _ComparativoRow(
              label: 'Pontuação',
              valueA: '${userA.pontuacao}',
              valueB: '${userB.pontuacao}',
            ),
            _ComparativoRow(
              label: 'Eficiência',
              valueA: PerformanceFormatters.formatPercent(userA.eficiencia),
              valueB: PerformanceFormatters.formatPercent(userB.eficiencia),
            ),
            _ComparativoRow(
              label: 'Ranking',
              valueA: userA.ranking > 0 ? '${userA.ranking}º' : '—',
              valueB: userB.ranking > 0 ? '${userB.ranking}º' : '—',
            ),
            _ComparativoRow(
              label: 'Estrelas',
              valueA: PerformanceStarDisplay(starCount: userA.starCount, size: 14),
              valueB: PerformanceStarDisplay(starCount: userB.starCount, size: 14),
              isWidget: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparativoRow extends StatelessWidget {
  final String label;
  final dynamic valueA;
  final dynamic valueB;
  final bool isWidget;

  const _ComparativoRow({
    required this.label,
    required this.valueA,
    required this.valueB,
    this.isWidget = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: isWidget
                ? Center(child: valueA as Widget)
                : Text(valueA as String, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 80,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: isWidget
                ? Center(child: valueB as Widget)
                : Text(valueB as String, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _ComparativoBar extends StatelessWidget {
  final String label;
  final double valueA;
  final double valueB;
  final String Function(double) format;

  const _ComparativoBar({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final double max = valueA > valueB ? valueA : valueB;
    final double ratioA = max > 0 ? valueA / max : 0;
    final double ratioB = max > 0 ? valueB / max : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  flex: (ratioA * 100).round().clamp(1, 100),
                  child: Container(
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      format(valueA),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: (ratioB * 100).round().clamp(1, 100),
                  child: Container(
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.darkBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      format(valueB),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
