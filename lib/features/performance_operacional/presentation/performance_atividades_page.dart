import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_activity_model.dart';
import '../services/performance_operacional_service.dart';
import '../widgets/performance_timeline_widgets.dart';

class PerformanceAtividadesPage extends StatefulWidget {
  final int? codusu;

  const PerformanceAtividadesPage({super.key, this.codusu});

  @override
  State<PerformanceAtividadesPage> createState() =>
      _PerformanceAtividadesPageState();
}

class _PerformanceAtividadesPageState extends State<PerformanceAtividadesPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  PerformanceAtividadesData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final PerformanceAtividadesData data = await _service.fetchAtividades(
        codusu: widget.codusu,
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
        title: const Text('Atividades Recentes'),
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
                  if (_data != null)
                    PerformanceActivityTimeline(activities: _data!.activities),
                ],
              ),
            ),
    );
  }
}
