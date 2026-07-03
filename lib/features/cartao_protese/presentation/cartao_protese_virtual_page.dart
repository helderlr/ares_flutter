import 'package:flutter/material.dart';

import '../../agendamento/models/empresa_report_model.dart';
import '../../agendamento/services/empresa_report_service.dart';
import '../models/cartao_protese_model.dart';
import '../utils/cartao_protese_field_labels.dart';

class CartaoProteseVirtualPage extends StatefulWidget {
  final CartaoProtese cartao;

  const CartaoProteseVirtualPage({super.key, required this.cartao});

  @override
  State<CartaoProteseVirtualPage> createState() =>
      _CartaoProteseVirtualPageState();
}

class _CartaoProteseVirtualPageState extends State<CartaoProteseVirtualPage> {
  static const Color _primaryGreen = Color(0xFF1B5E3B);
  static const Color _lightGreen = Color(0xFFE8F5E9);
  final EmpresaReportService _empresaService = EmpresaReportService();
  bool _showVerso = false;
  EmpresaReportData? _empresa;
  bool _isLoadingEmpresa = true;

  @override
  void initState() {
    super.initState();
    _loadEmpresa();
  }

  Future<void> _loadEmpresa() async {
    try {
      final EmpresaReportData data = await _empresaService.fetchReportData();
      if (!mounted) {
        return;
      }
      setState(() {
        _empresa = data;
        _isLoadingEmpresa = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingEmpresa = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryGreen,
      appBar: AppBar(
        title: const Text('Cartão Virtual'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _showVerso ? _buildVerso() : _buildFrente(),
                ),
              ),
            ),
          ),
          _buildToggle(),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      width: double.infinity,
      color: _primaryGreen,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'FRENTE',
            style: TextStyle(
              fontWeight: !_showVerso ? FontWeight.bold : FontWeight.normal,
              color: !_showVerso ? Colors.white : Colors.white70,
              fontSize: 13,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Switch(
              value: _showVerso,
              activeColor: Colors.white,
              activeTrackColor: Colors.white54,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white38,
              onChanged: (bool value) => setState(() => _showVerso = value),
            ),
          ),
          Text(
            'VERSO',
            style: TextStyle(
              fontWeight: _showVerso ? FontWeight.bold : FontWeight.normal,
              color: _showVerso ? Colors.white : Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrente() {
    final CartaoProtese cartao = widget.cartao;
    final String hospitalShort = _shortHospitalName(cartao.hospitalName);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            color: _primaryGreen,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _buildLogo(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        const Text(
                          'CARTÃO PRÓTESE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Nº ${cartao.nummov}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.calendar_today,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'DATA DA CIRURGIA ${cartao.dataCirurgiaDisplay}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildInfoRow(
            icon: Icons.person,
            label: 'PACIENTE',
            value: cartao.pacienteName.toUpperCase(),
          ),
          _buildInfoRow(
            icon: Icons.local_hospital,
            label: 'HOSPITAL',
            value: hospitalShort.toUpperCase(),
          ),
          _buildInfoRow(
            icon: Icons.medical_services,
            label: 'CIRURGIÃO',
            value: cartao.medicoName.toUpperCase(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'CRM ${cartao.crmMedico ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    'LADO ${CartaoProteseFieldLabels.ladoToDisplay(cartao.lado).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'PRÓTESE UTILIZADA',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cartao.tipoCirurgiaName.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.inventory_2, size: 16, color: _primaryGreen),
                    SizedBox(width: 6),
                    Text(
                      'COMPONENTE(S)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: _primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatComponentes(cartao.sistemaAplicado),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: _primaryGreen,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                const Icon(Icons.location_on, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _footerAddress(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerso() {
    final CartaoProtese cartao = widget.cartao;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: _primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'INFORMAÇÕES DA PRÓTESE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          _buildVersoRow(
            icon: Icons.build,
            label: 'TIPO DE PRÓTESE',
            value: CartaoProteseFieldLabels.tipoProteseToDisplay(cartao.tipo),
          ),
          _buildVersoRow(
            icon: Icons.refresh,
            label: 'PRIMÁRIA / REVISÃO',
            value: CartaoProteseFieldLabels.priRevToDisplay(cartao.priRev),
          ),
          _buildVersoRow(
            icon: Icons.public,
            label: 'PROCEDÊNCIA',
            value: CartaoProteseFieldLabels.nacImpToDisplay(cartao.nacImp),
          ),
          _buildVersoRow(
            icon: Icons.factory,
            label: 'FABRICANTE',
            value: cartao.nnomfab?.trim().isNotEmpty == true
                ? cartao.nnomfab!
                : '(Não informado)',
          ),
          _buildVersoRow(
            icon: Icons.qr_code,
            label: 'REGISTRO ANVISA',
            value: '(Não informado)',
          ),
          _buildVersoRow(
            icon: Icons.calendar_today,
            label: 'DATA DE IMPLANTE',
            value: cartao.dataCirurgiaDisplay,
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.info_outline, size: 16, color: _primaryGreen),
                    SizedBox(width: 6),
                    Text(
                      'ORIENTAÇÕES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: _primaryGreen,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Este cartão contém informações importantes sobre a prótese '
                  'implantada. Apresente-o em atendimentos médicos. Em caso de '
                  'dúvida, entre em contato com o hospital.',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            height: 24,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    if (_empresa?.logomarcaUrl != null &&
        _empresa!.logomarcaUrl!.trim().isNotEmpty) {
      return Image.network(
        _empresa!.logomarcaUrl!,
        height: 36,
        errorBuilder: (_, __, ___) => _buildLogoFallback(),
      );
    }
    return _buildLogoFallback();
  }

  Widget _buildLogoFallback() {
    final String nome = _empresa?.displayNome ?? 'ELLO';
    return Text(
      nome.length > 12 ? nome.substring(0, 12) : nome,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: _primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: _primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortHospitalName(String name) {
    if (name.length <= 30) {
      return name;
    }
    return name.substring(0, 30);
  }

  String _formatComponentes(String? text) {
    if (text == null || text.trim().isEmpty) {
      return '—';
    }
    return text.replaceAll('|', ', ').trim();
  }

  String _footerAddress() {
    if (_isLoadingEmpresa || _empresa == null) {
      return '—';
    }
    final List<String> parts = <String>[];
    final String endereco = _empresa!.endereco.trim();
    final String numero = _empresa!.numero.trim();
    if (endereco.isNotEmpty) {
      parts.add(numero.isNotEmpty ? '$endereco, $numero' : endereco);
    }
    if (_empresa!.bairro.trim().isNotEmpty) {
      parts.add(_empresa!.bairro.trim());
    }
    final String cidadeUf =
        '${_empresa!.cidade.trim()}${_empresa!.uf.trim().isNotEmpty ? ' - ${_empresa!.uf.trim()}' : ''}';
    if (cidadeUf.trim().isNotEmpty) {
      parts.add(cidadeUf.trim());
    }
    if (_empresa!.fone.trim().isNotEmpty) {
      parts.add('FONE: ${_empresa!.fone.trim()}');
    }
    return parts.join(' - ').toUpperCase();
  }
}
