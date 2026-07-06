import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_ranking_model.dart';
import '../services/performance_operacional_service.dart';
import '../widgets/performance_ranking_widgets.dart';
import 'performance_desempenho_page.dart';
import 'performance_ranking_full_page.dart';

class PerformanceRankingPage extends StatefulWidget {
  final DateTime referenceMonth;

  const PerformanceRankingPage({
    super.key,
    required this.referenceMonth,
  });

  @override
  State<PerformanceRankingPage> createState() => _PerformanceRankingPageState();
}

class _PerformanceRankingPageState extends State<PerformanceRankingPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  final TextEditingController _searchController = TextEditingController();
  PerformanceRankingData? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRanking({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final PerformanceRankingData data = await _service.fetchRanking(
        referenceMonth: widget.referenceMonth,
        search: search,
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

  void _openUserDetail(PerformanceRankingEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PerformanceDesempenhoPage(
          referenceMonth: widget.referenceMonth,
          codusu: entry.codusu,
          userName: entry.nome,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage!),
        ),
      );
    }
    final PerformanceRankingData data = _data ??
        const PerformanceRankingData(entries: <PerformanceRankingEntry>[], totalUsers: 0);
    final List<PerformanceRankingEntry> topThree = data.entries.take(3).toList();
    final List<PerformanceRankingEntry> rest = data.entries.length > 3
        ? data.entries.sublist(3)
        : <PerformanceRankingEntry>[];
    return RefreshIndicator(
      onRefresh: () => _loadRanking(search: _searchController.text),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pesquisar usuário...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            ),
            onSubmitted: (String value) => _loadRanking(search: value),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Icon(Icons.emoji_events, color: Color(0xFFFFB300)),
              const SizedBox(width: 8),
              Text(
                'Ranking Geral',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${data.totalUsers} usuários',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (topThree.isNotEmpty)
            PerformanceRankingPodium(topThree: topThree),
          const SizedBox(height: 8),
          ...rest.map(
            (PerformanceRankingEntry entry) => PerformanceRankingListTile(
              entry: entry,
              onTap: () => _openUserDetail(entry),
            ),
          ),
          if (data.entries.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PerformanceRankingFullPage(
                          referenceMonth: widget.referenceMonth,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                  ),
                  child: const Text('Ver ranking completo'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
