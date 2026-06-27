import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/atendimento_consulta_filters.dart';
import '../models/atendimento_consulta_model.dart';

class AtendimentoConsultaFiltersSheet extends StatefulWidget {
  final AtendimentoConsultaFilters initialFilters;
  final bool isAdmin;

  const AtendimentoConsultaFiltersSheet({
    super.key,
    required this.initialFilters,
    this.isAdmin = false,
  });

  @override
  State<AtendimentoConsultaFiltersSheet> createState() =>
      _AtendimentoConsultaFiltersSheetState();
}

class _AtendimentoConsultaFiltersSheetState
    extends State<AtendimentoConsultaFiltersSheet> {
  late DateTime _dateFrom;
  late DateTime _dateTo;
  late AtendimentoConsultaGroupBy _groupBy;
  final TextEditingController _medicoController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _convenioController = TextEditingController();
  final TextEditingController _tipoCirurgiaController = TextEditingController();
  final TextEditingController _vendedorController = TextEditingController();
  final TextEditingController _instrumentadorController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.initialFilters.dateFrom;
    _dateTo = widget.initialFilters.dateTo;
    _groupBy = widget.initialFilters.groupBy;
    _medicoController.text = widget.initialFilters.medico ?? '';
    _hospitalController.text = widget.initialFilters.hospital ?? '';
    _convenioController.text = widget.initialFilters.convenio ?? '';
    _tipoCirurgiaController.text = widget.initialFilters.tipoCirurgia ?? '';
    _vendedorController.text = widget.initialFilters.vendedor ?? '';
    _instrumentadorController.text =
        widget.initialFilters.instrumentador ?? '';
  }

  @override
  void dispose() {
    _medicoController.dispose();
    _hospitalController.dispose();
    _convenioController.dispose();
    _tipoCirurgiaController.dispose();
    _vendedorController.dispose();
    _instrumentadorController.dispose();
    super.dispose();
  }

  DateTime get _currentMonthStart {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime get _currentMonthEnd {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  AtendimentoConsultaFilters _buildFilters() {
    return AtendimentoConsultaFilters(
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      groupBy: _groupBy,
      medico: _medicoController.text.trim().isEmpty
          ? null
          : _medicoController.text.trim(),
      hospital: _hospitalController.text.trim().isEmpty
          ? null
          : _hospitalController.text.trim(),
      convenio: _convenioController.text.trim().isEmpty
          ? null
          : _convenioController.text.trim(),
      tipoCirurgia: _tipoCirurgiaController.text.trim().isEmpty
          ? null
          : _tipoCirurgiaController.text.trim(),
      vendedor: _vendedorController.text.trim().isEmpty
          ? null
          : _vendedorController.text.trim(),
      instrumentador: _instrumentadorController.text.trim().isEmpty
          ? null
          : _instrumentadorController.text.trim(),
    );
  }

  Future<void> _pickDate({
    required bool isStart,
  }) async {
    if (!widget.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Apenas administradores podem filtrar meses anteriores.',
          ),
        ),
      );
      return;
    }
    final DateTime initial = isStart ? _dateFrom : _dateTo;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: _currentMonthEnd,
      helpText: 'Selecione a data',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _dateFrom = picked;
        if (_dateTo.isBefore(_dateFrom)) {
          _dateTo = _dateFrom;
        }
      } else {
        _dateTo = picked;
        if (_dateFrom.isAfter(_dateTo)) {
          _dateFrom = _dateTo;
        }
      }
    });
  }

  void _applyLast30Days() {
    final DateTime end = DateTime.now();
    final DateTime start = end.subtract(const Duration(days: 29));
    if (!widget.isAdmin && start.isBefore(_currentMonthStart)) {
      setState(() {
        _dateFrom = _currentMonthStart;
        _dateTo = end.isAfter(_currentMonthEnd) ? _currentMonthEnd : end;
      });
      return;
    }
    setState(() {
      _dateFrom = start;
      _dateTo = end;
    });
  }

  void _clearAllMedicoFilter() {
    setState(() => _medicoController.clear());
    Navigator.of(context).pop(
      _buildFilters().copyWith(clearMedico: true),
    );
  }

  void _clearAllHospitalFilter() {
    setState(() => _hospitalController.clear());
    Navigator.of(context).pop(
      _buildFilters().copyWith(clearHospital: true),
    );
  }

  void _clearFilters() {
    final AtendimentoConsultaFilters defaults =
        AtendimentoConsultaFilters.currentMonth(groupBy: _groupBy);
    setState(() {
      _dateFrom = defaults.dateFrom;
      _dateTo = defaults.dateTo;
      _medicoController.clear();
      _hospitalController.clear();
      _convenioController.clear();
      _tipoCirurgiaController.clear();
      _vendedorController.clear();
      _instrumentadorController.clear();
    });
  }

  String _formatDisplayDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: AppColors.lightBlue),
                const SizedBox(width: 8),
                const Text(
                  'Filtros da consulta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip(
                  label: 'Últimos 30 dias',
                  icon: Icons.calendar_today,
                  color: AppColors.lightBlue,
                  onTap: _applyLast30Days,
                ),
                _buildQuickChip(
                  label: 'Todos médicos',
                  icon: Icons.medical_services,
                  color: Colors.green,
                  onTap: _clearAllMedicoFilter,
                ),
                _buildQuickChip(
                  label: 'Todos hospitais',
                  icon: Icons.local_hospital,
                  color: Colors.purple,
                  onTap: _clearAllHospitalFilter,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.isAdmin
                  ? 'Administrador: pode filtrar anos anteriores no período.'
                  : 'Período limitado ao mês atual.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Período',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: _formatDisplayDate(_dateFrom),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    label: _formatDisplayDate(_dateTo),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Agrupar por',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AtendimentoConsultaGroupBy>(
              value: _groupBy,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.layers_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: AtendimentoConsultaGroupBy.values
                  .map(
                    (AtendimentoConsultaGroupBy value) =>
                        DropdownMenuItem<AtendimentoConsultaGroupBy>(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (AtendimentoConsultaGroupBy? value) {
                if (value == null) {
                  return;
                }
                setState(() => _groupBy = value);
              },
            ),
            const SizedBox(height: 16),
            _buildTextFilter('Médico', _medicoController, Icons.person),
            const SizedBox(height: 12),
            _buildTextFilter(
              'Hospital',
              _hospitalController,
              Icons.local_hospital,
            ),
            const SizedBox(height: 12),
            _buildTextFilter(
              'Tipo cirurgia',
              _tipoCirurgiaController,
              Icons.healing,
            ),
            const SizedBox(height: 12),
            _buildTextFilter(
              'Convênio',
              _convenioController,
              Icons.assignment,
            ),
            const SizedBox(height: 12),
            _buildTextFilter(
              'Vendedor',
              _vendedorController,
              Icons.storefront,
            ),
            const SizedBox(height: 12),
            _buildTextFilter(
              'Instrumentador',
              _instrumentadorController,
              Icons.handyman,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        Navigator.of(context).pop(_buildFilters()),
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar filtros'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide(color: color.withOpacity(0.2)),
    );
  }

  Widget _buildDateField({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          suffixIcon: Icon(
            widget.isAdmin ? Icons.calendar_today : Icons.lock_outline,
            size: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildTextFilter(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
