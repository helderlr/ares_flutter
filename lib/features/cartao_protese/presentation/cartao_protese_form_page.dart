import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/form_action_bar.dart';
import '../../../core/widgets/entity_lookup_picker.dart';
import '../../../core/widgets/form_section_field.dart';
import '../../login/services/auth_service.dart';
import '../models/cartao_protese_model.dart';
import '../services/cartao_protese_service.dart';
import '../utils/cartao_protese_field_labels.dart';

class CartaoProteseFormPage extends StatefulWidget {
  final CartaoProtese? cartao;

  const CartaoProteseFormPage({super.key, this.cartao});

  @override
  State<CartaoProteseFormPage> createState() => _CartaoProteseFormPageState();
}

class _CartaoProteseFormPageState extends State<CartaoProteseFormPage> {
  final CartaoProteseService _service = CartaoProteseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoadingPedido = false;
  int? _codpac;
  int? _codmed;
  int? _codcli;
  int? _codcir;
  String? _pacNome;
  String? _medNome;
  String? _cliNome;
  String? _tipoCirNome;
  String? _nacImp;
  String? _priRev;
  String? _lado;
  String? _tipoProtese;
  final TextEditingController _nummovController = TextEditingController();
  final TextEditingController _numpedvController = TextEditingController();
  final TextEditingController _datcirController = TextEditingController();
  final TextEditingController _datmovController = TextEditingController();
  final TextEditingController _horlanController = TextEditingController();
  final TextEditingController _nnomfabController = TextEditingController();
  final TextEditingController _componentesController = TextEditingController();
  final TextEditingController _digitadoPorController = TextEditingController();
  Timer? _pedidoDebounce;

  bool get _isEditing => widget.cartao != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadFrom(widget.cartao!);
    } else {
      final DateTime today = DateTime.now();
      _datmovController.text = _formatDateBr(today);
      _horlanController.text = _formatTimeNow();
      _loadDigitadoPor();
    }
    _numpedvController.addListener(_onPedidoChanged);
  }

  @override
  void dispose() {
    _pedidoDebounce?.cancel();
    _nummovController.dispose();
    _numpedvController.dispose();
    _datcirController.dispose();
    _datmovController.dispose();
    _horlanController.dispose();
    _nnomfabController.dispose();
    _componentesController.dispose();
    _digitadoPorController.dispose();
    super.dispose();
  }

  Future<void> _loadDigitadoPor() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted || user == null) {
      return;
    }
    setState(() {
      _digitadoPorController.text = user.nome;
    });
  }

  void _loadFrom(CartaoProtese item) {
    _nummovController.text = item.nummov.toString();
    _numpedvController.text = item.numpedv?.toString() ?? '';
    _datcirController.text = item.datcir != null
        ? _formatDateBr(item.datcir!)
        : '';
    _datmovController.text = item.datmov != null
        ? _formatDateBr(item.datmov!)
        : '';
    _horlanController.text = item.horlan ?? '';
    _nnomfabController.text = item.nnomfab ?? '';
    _componentesController.text = item.sistemaAplicado ?? '';
    _codpac = item.codpac;
    _codmed = item.codmed;
    _codcli = item.codcli;
    _codcir = item.codcir;
    _pacNome = item.nnompac;
    _medNome = item.nnommed;
    _cliNome = item.nnomcli;
    _tipoCirNome = item.nomcirTipo ?? item.tipoCirurgiaName;
    _nacImp = item.nacImp;
    _priRev = item.priRev;
    _lado = item.lado;
    _tipoProtese = item.tipo;
    _digitadoPorController.text = item.codusu?.toString() ?? '';
  }

  void _onPedidoChanged() {
    _pedidoDebounce?.cancel();
    _pedidoDebounce = Timer(const Duration(milliseconds: 800), () {
      final int? numpedv = int.tryParse(_numpedvController.text.trim());
      if (numpedv != null && numpedv > 0) {
        _loadFromPedido(numpedv);
      }
    });
  }

  Future<void> _warnPedidoDuplicado(int numpedv) async {
    final CartaoProtese? existente = await _service.findExistingByPedido(
      numpedv,
      excludeNummov: _isEditing ? widget.cartao!.nummov : null,
    );
    if (!mounted || existente == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pedido $numpedv já vinculado ao cartão Nº ${existente.nummov}.',
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _loadFromPedido(int numpedv) async {
    setState(() => _isLoadingPedido = true);
    try {
      await _warnPedidoDuplicado(numpedv);
      final CartaoProtese? dados = await _service.fetchDadosPorPedido(numpedv);
      if (!mounted) {
        return;
      }
      if (dados == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido não encontrado.')),
        );
        return;
      }
      setState(() {
        _codpac = dados.codpac;
        _pacNome = dados.nnompac;
        _codmed = dados.codmed;
        _medNome = dados.nnommed;
        _codcli = dados.codcli;
        _cliNome = dados.nnomcli;
        _codcir = dados.codcir;
        _tipoCirNome = dados.nomcirTipo ?? dados.tipoCirurgiaName;
        _nacImp = dados.nacImp ?? 'N';
        _priRev = dados.priRev ?? 'P';
        _lado = dados.lado;
        _tipoProtese = dados.tipo;
        if (dados.datcir != null) {
          _datcirController.text = _formatDateBr(dados.datcir!);
        }
        if (dados.sistemaAplicado != null) {
          _componentesController.text = dados.sistemaAplicado!;
        }
        if (dados.nnomfab != null) {
          _nnomfabController.text = dados.nnomfab!;
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPedido = false);
      }
    }
  }

  Future<void> _pickPaciente() async {
    final EntityLookupSelection? sel =
        await EntityLookupPicker.pickPaciente(context);
    if (sel == null) {
      return;
    }
    setState(() {
      _codpac = int.tryParse(sel.code);
      _pacNome = sel.name;
    });
  }

  Future<void> _pickMedico() async {
    final EntityLookupSelection? sel =
        await EntityLookupPicker.pickMedico(context);
    if (sel == null) {
      return;
    }
    setState(() {
      _codmed = int.tryParse(sel.code);
      _medNome = sel.name;
    });
  }

  Future<void> _pickHospital() async {
    final EntityLookupSelection? sel =
        await EntityLookupPicker.pickHospital(context);
    if (sel == null) {
      return;
    }
    setState(() {
      _codcli = int.tryParse(sel.code);
      _cliNome = sel.name;
    });
  }

  Future<void> _pickTipoCirurgia() async {
    final EntityLookupSelection? sel =
        await EntityLookupPicker.pickTipoCirurgia(context);
    if (sel == null) {
      return;
    }
    setState(() {
      _codcir = int.tryParse(sel.code);
      _tipoCirNome = sel.name;
    });
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final DateTime initial =
        _parseDateBr(controller.text) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2010),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked == null) {
      return;
    }
    setState(() => controller.text = _formatDateBr(picked));
  }

  Future<void> _pickTime() async {
    final TimeOfDay initial = _parseTime(_horlanController.text) ??
        TimeOfDay.fromDateTime(DateTime.now());
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _horlanController.text =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}:00';
    });
  }

  Future<void> _save() async {
    if (_codpac == null || _codmed == null || _codcli == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha paciente, médico e hospital.'),
        ),
      );
      return;
    }
    if (_datcirController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a data da cirurgia.')),
      );
      return;
    }
    if (_componentesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe os componentes.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final int? codusu = await AuthService.getCurrentCodusu();
      final CartaoProtese item = CartaoProtese(
        nummov: _isEditing ? widget.cartao!.nummov : 0,
        datcir: _parseDateBr(_datcirController.text),
        codpac: _codpac,
        nacImp: _nacImp ?? 'N',
        lado: _lado,
        priRev: _priRev ?? 'P',
        codmed: _codmed,
        datmov: _parseDateBr(_datmovController.text),
        codcli: _codcli,
        tipo: _tipoProtese,
        sistemaAplicado: _componentesController.text.trim(),
        codusu: codusu,
        horlan: _horlanController.text.trim(),
        numpedv: int.tryParse(_numpedvController.text.trim()),
        codcir: _codcir,
        nnompac: _pacNome,
        nnomcli: _cliNome,
        nnommed: _medNome,
        nnomfab: _nnomfabController.text.trim().isEmpty
            ? null
            : _nnomfabController.text.trim(),
        nomcirTipo: _tipoCirNome,
      );
      if (_isEditing) {
        await _service.update(widget.cartao!.nummov, item);
      } else {
        await _service.create(item);
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cartão salvo com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDateBr(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTimeNow() {
    final DateTime now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDateBr(String text) {
    final List<String> parts = text.trim().split('/');
    if (parts.length != 3) {
      return null;
    }
    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  TimeOfDay? _parseTime(String text) {
    final List<String> parts = text.trim().split(':');
    if (parts.length < 2) {
      return null;
    }
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Cartão Prótese' : 'Novo Cartão Prótese'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: <Widget>[
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (_isEditing)
                  FormSectionField(
                    label: 'No Cartão',
                    controller: _nummovController,
                    readOnly: true,
                  ),
                FormSectionLookup(
                  label: 'Hospital/Clínica *',
                  value: _cliNome,
                  placeholder: 'Toque para buscar hospital',
                  onSearch: _pickHospital,
                ),
                FormSectionField(
                  label: 'Data Cirurgia *',
                  controller: _datcirController,
                  readOnly: true,
                  onSearch: () => _pickDate(_datcirController),
                  actionIcon: Icons.calendar_today,
                ),
                FormSectionLookup(
                  label: 'Médico *',
                  value: _medNome,
                  placeholder: 'Toque para buscar médico',
                  onSearch: _pickMedico,
                ),
                FormSectionLookup(
                  label: 'Tipo Cirurgia',
                  value: _tipoCirNome,
                  placeholder: 'Toque para buscar tipo de cirurgia',
                  onSearch: _pickTipoCirurgia,
                ),
                FormSectionLookup(
                  label: 'Paciente *',
                  value: _pacNome,
                  placeholder: 'Toque para buscar paciente',
                  onSearch: _pickPaciente,
                ),
                _buildDropdown(
                  label: 'Lado',
                  value: _lado,
                  items: CartaoProteseFieldLabels.ladoLabels.entries
                      .map(
                        (MapEntry<String, String> e) =>
                            DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) => setState(() => _lado = v),
                ),
                FormSectionField(
                  label: 'Digitado por',
                  controller: _digitadoPorController,
                  readOnly: true,
                ),
                _buildDropdown(
                  label: 'Nacional/Imp *',
                  value: _nacImp ?? 'N',
                  items: CartaoProteseFieldLabels.nacImpLabels.entries
                      .map(
                        (MapEntry<String, String> e) =>
                            DropdownMenuItem<String>(
                          value: e.key,
                          child: Text('${e.key}=${e.value}'),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) => setState(() => _nacImp = v),
                ),
                _buildDropdown(
                  label: 'Primaria/Rev *',
                  value: _priRev ?? 'P',
                  items: CartaoProteseFieldLabels.priRevLabels.entries
                      .map(
                        (MapEntry<String, String> e) =>
                            DropdownMenuItem<String>(
                          value: e.key,
                          child: Text('${e.key}=${e.value}'),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) => setState(() => _priRev = v),
                ),
                _buildDropdown(
                  label: 'Tipo Protese',
                  value: _tipoProtese,
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('—'),
                    ),
                    ...CartaoProteseFieldLabels.tipoProteseLabels.entries.map(
                      (MapEntry<String, String> e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text('${e.key}=${e.value}'),
                      ),
                    ),
                  ],
                  onChanged: (String? v) => setState(() => _tipoProtese = v),
                ),
                FormSectionField(
                  label: 'No Pedido',
                  controller: _numpedvController,
                  keyboardType: TextInputType.number,
                  onSearch: () {
                    final int? numpedv =
                        int.tryParse(_numpedvController.text.trim());
                    if (numpedv != null) {
                      _loadFromPedido(numpedv);
                    }
                  },
                ),
                FormSectionField(
                  label: 'Data Emissao',
                  controller: _datmovController,
                  readOnly: true,
                  onSearch: () => _pickDate(_datmovController),
                  actionIcon: Icons.calendar_today,
                ),
                FormSectionField(
                  label: 'Hora Emissao',
                  controller: _horlanController,
                  readOnly: true,
                  onSearch: _pickTime,
                  actionIcon: Icons.access_time,
                ),
                FormSectionField(
                  label: 'Nome Fabricante',
                  controller: _nnomfabController,
                ),
                FormSectionField(
                  label: 'Componentes *',
                  controller: _componentesController,
                  maxLines: 6,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (_isLoadingPedido)
            const ColoredBox(
              color: Color(0x44000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: FormActionBar(
        isLoading: _isSaving,
        isEditing: _isEditing,
        onCancel: () => Navigator.of(context).pop(),
        onSave: _save,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return FormSectionDropdown<String?>(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }
}
