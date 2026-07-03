import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/cartao_protese_model.dart';
import '../services/cartao_protese_service.dart';
import '../utils/cartao_protese_field_labels.dart';
import 'cartao_protese_form_page.dart';
import 'cartao_protese_virtual_page.dart';

class ConsultaCartaoProtesePage extends StatefulWidget {
  final CartaoProtese cartao;

  const ConsultaCartaoProtesePage({super.key, required this.cartao});

  @override
  State<ConsultaCartaoProtesePage> createState() =>
      _ConsultaCartaoProtesePageState();
}

class _ConsultaCartaoProtesePageState extends State<ConsultaCartaoProtesePage> {
  final CartaoProteseService _service = CartaoProteseService();
  late CartaoProtese _current;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _current = widget.cartao;
    _refreshDetail();
  }

  Future<void> _refreshDetail() async {
    setState(() => _isLoading = true);
    try {
      final CartaoProtese? fresh =
          await _service.getById(widget.cartao.nummov);
      if (!mounted) {
        return;
      }
      if (fresh != null) {
        setState(() => _current = fresh);
      }
    } catch (_) {
      // Mantém dados da lista.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openEdit() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            CartaoProteseFormPage(cartao: _current),
      ),
    );
    if (saved == true) {
      await _refreshDetail();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _openVirtualCard() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            CartaoProteseVirtualPage(cartao: _current),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cartão Nº ${_current.nummov}'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            onPressed: _openVirtualCard,
            icon: const Icon(Icons.credit_card),
            tooltip: 'Cartão',
          ),
          IconButton(
            onPressed: _isLoading ? null : _openEdit,
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  _current.pacienteName,
                  style: AppTheme.listItemTitleStyleOf(context).copyWith(
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLine('No Cartão', '${_current.nummov}'),
                _buildLine('No Pedido', '${_current.numpedv ?? '—'}'),
                _buildLine('Data Cirurgia', _current.dataCirurgiaDisplay),
                _buildLine('Hospital', _current.hospitalName),
                _buildLine('Médico', _current.medicoName),
                _buildLine('Tipo Cirurgia', _current.tipoCirurgiaName),
                _buildLine('Lado', CartaoProteseFieldLabels.ladoToDisplay(_current.lado)),
                _buildLine(
                  'Nacional/Imp',
                  CartaoProteseFieldLabels.nacImpToDisplay(_current.nacImp),
                ),
                _buildLine(
                  'Primaria/Rev',
                  CartaoProteseFieldLabels.priRevToDisplay(_current.priRev),
                ),
                _buildLine(
                  'Tipo Prótese',
                  CartaoProteseFieldLabels.tipoProteseToDisplay(_current.tipo),
                ),
                _buildLine('Fabricante', _current.nnomfab ?? '—'),
                _buildLine('Data Emissão', _current.dataEmissaoDisplay),
                _buildLine('Hora Emissão', _current.horaEmissaoDisplay),
                const SizedBox(height: 12),
                const Text(
                  'Componentes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _current.componentesDisplay,
                  style: AppTheme.listItemSubtitleStyleOf(context),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _openVirtualCard,
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Ver Cartão Virtual'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E3B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTheme.listItemSubtitleStyleOf(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.listItemSubtitleStyleOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
