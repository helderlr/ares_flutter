import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_ranking_model.dart';
import '../services/performance_operacional_service.dart';
import '../widgets/performance_ranking_widgets.dart';
import 'performance_desempenho_page.dart';

class PerformanceRankingFullPage extends StatefulWidget {
  final DateTime referenceMonth;

  const PerformanceRankingFullPage({
    super.key,
    required this.referenceMonth,
  });

  @override
  State<PerformanceRankingFullPage> createState() =>
      _PerformanceRankingFullPageState();
}

class _PerformanceRankingFullPageState extends State<PerformanceRankingFullPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  final TextEditingController _searchController = TextEditingController();
  PerformanceRankingData? _data;
  bool _isLoading = true;

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
    setState(() => _isLoading = true);
    try {
      final PerformanceRankingData data = await _service.fetchRanking(
        referenceMonth: widget.referenceMonth,
        search: search,
        limit: 100,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking Completo'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar usuário...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (String value) => _loadRanking(search: value),
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadRanking(search: _searchController.text),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: <Widget>[
                    if (_data != null) ...<Widget>[
                      Text(
                        'Top ${_data!.entries.length} de ${_data!.totalUsers} usuários',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      if (_data!.entries.length >= 3)
                        PerformanceRankingPodium(
                          topThree: _data!.entries.take(3).toList(),
                        ),
                      const SizedBox(height: 8),
                      ..._data!.entries.map(
                        (PerformanceRankingEntry entry) =>
                            PerformanceRankingListTile(
                          entry: entry,
                          onTap: () => _openUserDetail(entry),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
