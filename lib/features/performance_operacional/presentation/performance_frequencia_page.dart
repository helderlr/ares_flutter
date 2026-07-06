import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_frequency_model.dart';
import '../services/performance_operacional_service.dart';
import '../widgets/performance_timeline_widgets.dart';

class PerformanceFrequenciaPage extends StatefulWidget {
  final DateTime referenceMonth;
  final int? codusu;

  const PerformanceFrequenciaPage({
    super.key,
    required this.referenceMonth,
    this.codusu,
  });

  @override
  State<PerformanceFrequenciaPage> createState() =>
      _PerformanceFrequenciaPageState();
}

class _PerformanceFrequenciaPageState extends State<PerformanceFrequenciaPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  PerformanceFrequenciaData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final PerformanceFrequenciaData data = await _service.fetchFrequencia(
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
        title: const Text('Frequência'),
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
                  if (_data != null) PerformanceFrequencyCalendar(data: _data!),
                ],
              ),
            ),
    );
  }
}
