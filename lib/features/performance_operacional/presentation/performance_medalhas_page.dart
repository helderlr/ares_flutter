import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_medal_model.dart';
import '../services/performance_operacional_service.dart';
import '../widgets/performance_timeline_widgets.dart';

class PerformanceMedalhasPage extends StatefulWidget {
  final DateTime referenceMonth;
  final int? codusu;

  const PerformanceMedalhasPage({
    super.key,
    required this.referenceMonth,
    this.codusu,
  });

  @override
  State<PerformanceMedalhasPage> createState() => _PerformanceMedalhasPageState();
}

class _PerformanceMedalhasPageState extends State<PerformanceMedalhasPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  PerformanceMedalhasData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final PerformanceMedalhasData data = await _service.fetchMedalhas(
        codusu: widget.codusu,
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
        title: const Text('Medalhas'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  if (_data != null) ...<Widget>[
                    Text(
                      '${_data!.earnedCount} de ${_data!.totalCount} conquistas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    PerformanceMedalGrid(medals: _data!.medals),
                  ],
                ],
              ),
            ),
    );
  }
}
