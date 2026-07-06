import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/performance_activity_model.dart';
import '../services/performance_operacional_service.dart';
import '../utils/performance_formatters.dart';
import '../widgets/performance_timeline_widgets.dart';

class PerformanceHorasPage extends StatefulWidget {
  final int? codusu;
  final DateTime? referenceDay;

  const PerformanceHorasPage({
    super.key,
    this.codusu,
    this.referenceDay,
  });

  @override
  State<PerformanceHorasPage> createState() => _PerformanceHorasPageState();
}

class _PerformanceHorasPageState extends State<PerformanceHorasPage> {
  final PerformanceOperacionalService _service = PerformanceOperacionalService();
  PerformanceHorasData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final PerformanceHorasData data = await _service.fetchHoras(
        codusu: widget.codusu,
        referenceDay: widget.referenceDay ?? DateTime.now(),
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
        title: const Text('Horas Trabalhadas'),
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
                    PerformanceHorasTimeline(
                      events: _data!.events,
                      totalMinutes: _data!.totalMinutes,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: <Widget>[
                                  const Icon(Icons.work_outline, color: Colors.green),
                                  const SizedBox(height: 4),
                                  Text(
                                    PerformanceFormatters.formatHoursMinutes(
                                      _data!.productiveMinutes,
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Text('Tempo produtivo', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: <Widget>[
                                  Icon(Icons.pause_circle_outline, color: Colors.red.shade300),
                                  const SizedBox(height: 4),
                                  Text(
                                    PerformanceFormatters.formatHoursMinutes(
                                      _data!.idleMinutes,
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Text('Tempo parado', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
