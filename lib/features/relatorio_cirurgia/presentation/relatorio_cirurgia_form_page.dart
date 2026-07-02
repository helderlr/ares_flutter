import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/entity_lookup_picker.dart';
import '../../../core/widgets/form_section_field.dart';
import '../models/relatorio_cirurgia_model.dart';
import '../services/relatorio_cirurgia_service.dart';

class RelatorioCirurgiaFormPage extends StatefulWidget {
  final RelatorioCirurgia? relatorio;

  const RelatorioCirurgiaFormPage({super.key, this.relatorio});

  @override
  State<RelatorioCirurgiaFormPage> createState() =>
      _RelatorioCirurgiaFormPageState();
}

class _RelatorioCirurgiaFormPageState extends State<RelatorioCirurgiaFormPage> {
  final RelatorioCirurgiaService _service = RelatorioCirurgiaService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _tabIndex = 0;
  bool _isSaving = false;
  int? _codpac;
  int? _codmed;
  int? _codcli;
  int? _codconv;
  int? _circod;
  String? _pacNome;
  String? _medNome;
  String? _cliNome;
  String? _convNome;
  String? _tipoCirNome;
  final TextEditingController _numrelController = TextEditingController();
  final TextEditingController _nagecirController = TextEditingController();
  final TextEditingController _numreqController = TextEditingController();
  final TextEditingController _datmovController = TextEditingController();
  final TextEditingController _codpacController = TextEditingController();
  final TextEditingController _codmedController = TextEditingController();
  final TextEditingController _codconvController = TextEditingController();
  final TextEditingController _codcliController = TextEditingController();
  final TextEditingController _codinsController = TextEditingController();
  final TextEditingController _inshosController = TextEditingController();
  final TextEditingController _hrfinController = TextEditingController();
  final TextEditingController _codcirController = TextEditingController();
  final TextEditingController _nomcirController = TextEditingController();
  final TextEditingController _codlevController = TextEditingController();
  final TextEditingController _sistemaController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _cirhosController = TextEditingController();
  final TextEditingController _codtroController = TextEditingController();
  final TextEditingController _circodController = TextEditingController();
  final TextEditingController _datcirController = TextEditingController();
  final TextEditingController _hriniController = TextEditingController();
  final TextEditingController _nprontuarioController = TextEditingController();
  final TextEditingController _grauController = TextEditingController();
  final TextEditingController _historicoController = TextEditingController();
  final TextEditingController _obsEstoqueController = TextEditingController();
  final TextEditingController _obsGerenciaController = TextEditingController();
  final TextEditingController _obsRtController = TextEditingController();
  final TextEditingController _problemaController = TextEditingController();
  final TextEditingController _problemaRetornoController = TextEditingController();
  final TextEditingController _problemaImpController = TextEditingController();
  final TextEditingController _medidaEstoqueController = TextEditingController();
  final TextEditingController _sistemaAplicadoController = TextEditingController();
  final TextEditingController _enderecoInicioController = TextEditingController();
  final TextEditingController _enderecoFimController = TextEditingController();
  String? _lado;
  String? _priRev;
  String? _sexo;
  String? _status;
  String? _urgencia;
  String? _relProb;
  String? _satisfacaoMatHospital;
  String? _satisfacaoInstHospital;
  String? _satisfacaoMatCirurg;
  String? _satisfacaoInstCirurg;

  bool get _isEditing => widget.relatorio != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadFrom(widget.relatorio!);
    } else {
      final DateTime today = DateTime.now();
      _datmovController.text = _formatDateBr(today);
      _priRev = 'P';
      _sexo = 'M';
      _urgencia = 'N';
      _relProb = 'N';
      _status = 'N';
    }
  }

  @override
  void dispose() {
    _numrelController.dispose();
    _nagecirController.dispose();
    _numreqController.dispose();
    _datmovController.dispose();
    _codpacController.dispose();
    _codmedController.dispose();
    _codconvController.dispose();
    _codcliController.dispose();
    _codinsController.dispose();
    _inshosController.dispose();
    _hrfinController.dispose();
    _codcirController.dispose();
    _nomcirController.dispose();
    _codlevController.dispose();
    _sistemaController.dispose();
    _idadeController.dispose();
    _cirhosController.dispose();
    _codtroController.dispose();
    _circodController.dispose();
    _datcirController.dispose();
    _hriniController.dispose();
    _nprontuarioController.dispose();
    _grauController.dispose();
    _historicoController.dispose();
    _obsEstoqueController.dispose();
    _obsGerenciaController.dispose();
    _obsRtController.dispose();
    _problemaController.dispose();
    _problemaRetornoController.dispose();
    _problemaImpController.dispose();
    _medidaEstoqueController.dispose();
    _sistemaAplicadoController.dispose();
    _enderecoInicioController.dispose();
    _enderecoFimController.dispose();
    super.dispose();
  }

  String _formatDateBr(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  DateTime? _parseDateBr(String text) {
    final RegExp pattern = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final Match? match = pattern.firstMatch(text.trim());
    if (match == null) {
      return null;
    }
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }

  int? _parseIntField(TextEditingController controller) {
    final String text = controller.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return int.tryParse(text);
  }

  void _loadFrom(RelatorioCirurgia item) {
    _codpac = item.codpac;
    _codmed = item.codmed;
    _codcli = item.codcli;
    _codconv = item.codconv;
    _circod = item.circod;
    _pacNome = item.pacNome;
    _medNome = item.medNome;
    _cliNome = item.cliNome;
    _convNome = item.convNome;
    _tipoCirNome = item.tipoCirNome;
    _numrelController.text = item.numrel?.toString() ?? '';
    _nagecirController.text = item.nagecir?.toString() ?? '';
    _numreqController.text = item.numreq?.toString() ?? '';
    _datmovController.text = item.datmov != null ? _formatDateBr(item.datmov!) : '';
    _codpacController.text = item.codpac?.toString() ?? '';
    _codmedController.text = item.codmed?.toString() ?? '';
    _codconvController.text = item.codconv?.toString() ?? '';
    _codcliController.text = item.codcli?.toString() ?? '';
    _codinsController.text = item.codins?.toString() ?? '';
    _inshosController.text = item.inshos ?? '';
    _hrfinController.text = item.hrfin ?? '';
    _codcirController.text = item.codcir?.toString() ?? '';
    _nomcirController.text = item.nomcir ?? '';
    _codlevController.text = item.codlev?.toString() ?? '';
    _sistemaController.text = item.sistema ?? '';
    _idadeController.text = item.idade?.toString() ?? '';
    _cirhosController.text = item.cirhos ?? '';
    _codtroController.text = item.codtro?.toString() ?? '';
    _circodController.text = item.circod?.toString() ?? '';
    _datcirController.text = item.datcir != null ? _formatDateBr(item.datcir!) : '';
    _hriniController.text = item.hrini ?? '';
    _nprontuarioController.text = item.nprontuario ?? '';
    _grauController.text = item.grau ?? '';
    _historicoController.text = item.historico ?? '';
    _obsEstoqueController.text = item.obsEstoque ?? '';
    _obsGerenciaController.text = item.obsGerencia ?? '';
    _obsRtController.text = item.obsRt ?? '';
    _problemaController.text = item.problema ?? '';
    _problemaRetornoController.text = item.problemaRetornoMat ?? '';
    _problemaImpController.text = item.problemaImp ?? '';
    _medidaEstoqueController.text = item.medidaTomadaEstoque ?? '';
    _sistemaAplicadoController.text = item.sistemaAplicado ?? '';
    _enderecoInicioController.text = item.enderecoInicio ?? '';
    _enderecoFimController.text = item.enderecoFim ?? '';
    _lado = item.lado;
    _priRev = item.priRev ?? 'P';
    _sexo = item.sexo ?? 'M';
    _status = item.status ?? 'N';
    _urgencia = item.urgencia ?? 'N';
    _relProb = item.relProb ?? 'N';
    _satisfacaoMatHospital = item.satisfacaoMatHospital;
    _satisfacaoInstHospital = item.satisfacaoInstHospital;
    _satisfacaoMatCirurg = item.satisfacaoMatCirurg;
    _satisfacaoInstCirurg = item.satisfacaoInstCirurg;
  }

  RelatorioCirurgia _buildDraft() {
    return RelatorioCirurgia(
      nummov: widget.relatorio?.nummov ?? 0,
      numrel: _parseIntField(_numrelController),
      nagecir: _parseIntField(_nagecirController),
      numreq: _parseIntField(_numreqController),
      datmov: _parseDateBr(_datmovController.text),
      codpac: _codpac ?? _parseIntField(_codpacController),
      codmed: _codmed ?? _parseIntField(_codmedController),
      codconv: _codconv ?? _parseIntField(_codconvController),
      codcli: _codcli ?? _parseIntField(_codcliController),
      codins: _parseIntField(_codinsController),
      inshos: _inshosController.text.trim().isEmpty ? null : _inshosController.text.trim(),
      hrfin: _hrfinController.text.trim().isEmpty ? null : _hrfinController.text.trim(),
      codcir: _parseIntField(_codcirController),
      nomcir: _nomcirController.text.trim().isEmpty ? null : _nomcirController.text.trim(),
      codlev: _parseIntField(_codlevController),
      sistema: _sistemaController.text.trim().isEmpty ? null : _sistemaController.text.trim(),
      idade: _parseIntField(_idadeController),
      cirhos: _cirhosController.text.trim().isEmpty ? null : _cirhosController.text.trim(),
      codtro: _parseIntField(_codtroController),
      circod: _circod ?? _parseIntField(_circodController),
      datcir: _parseDateBr(_datcirController.text),
      hrini: _hriniController.text.trim().isEmpty ? null : _hriniController.text.trim(),
      nprontuario: _nprontuarioController.text.trim().isEmpty ? null : _nprontuarioController.text.trim(),
      grau: _grauController.text.trim().isEmpty ? null : _grauController.text.trim(),
      historico: _historicoController.text.trim().isEmpty ? null : _historicoController.text.trim(),
      obsEstoque: _obsEstoqueController.text.trim().isEmpty ? null : _obsEstoqueController.text.trim(),
      obsGerencia: _obsGerenciaController.text.trim().isEmpty ? null : _obsGerenciaController.text.trim(),
      obsRt: _obsRtController.text.trim().isEmpty ? null : _obsRtController.text.trim(),
      problema: _problemaController.text.trim().isEmpty ? null : _problemaController.text.trim(),
      problemaRetornoMat: _problemaRetornoController.text.trim().isEmpty ? null : _problemaRetornoController.text.trim(),
      problemaImp: _problemaImpController.text.trim().isEmpty ? null : _problemaImpController.text.trim(),
      medidaTomadaEstoque: _medidaEstoqueController.text.trim().isEmpty ? null : _medidaEstoqueController.text.trim(),
      sistemaAplicado: _sistemaAplicadoController.text.trim().isEmpty ? null : _sistemaAplicadoController.text.trim(),
      enderecoInicio: _enderecoInicioController.text.trim().isEmpty ? null : _enderecoInicioController.text.trim(),
      enderecoFim: _enderecoFimController.text.trim().isEmpty ? null : _enderecoFimController.text.trim(),
      lado: _lado,
      priRev: _priRev,
      sexo: _sexo,
      status: _status,
      urgencia: _urgencia,
      relProb: _relProb,
      satisfacaoMatHospital: _satisfacaoMatHospital,
      satisfacaoInstHospital: _satisfacaoInstHospital,
      satisfacaoMatCirurg: _satisfacaoMatCirurg,
      satisfacaoInstCirurg: _satisfacaoInstCirurg,
      pacNome: _pacNome,
      medNome: _medNome,
      cliNome: _cliNome,
      convNome: _convNome,
      tipoCirNome: _tipoCirNome,
    );
  }

  Future<void> _save() async {
    if (_codpac == null && _parseIntField(_codpacController) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o paciente.')),
      );
      setState(() => _tabIndex = 0);
      return;
    }
    if (_codmed == null && _parseIntField(_codmedController) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o médico.')),
      );
      setState(() => _tabIndex = 0);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final RelatorioCirurgia draft = _buildDraft();
      if (_isEditing) {
        await _service.update(widget.relatorio!.nummov, draft);
      } else {
        await _service.create(draft);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _applyLookupSelection({
    required EntityLookupSelection? selection,
    required void Function(int? code, String? name) apply,
    required TextEditingController controller,
  }) async {
    if (selection == null) {
      return;
    }
    setState(() {
      final int? code = int.tryParse(selection.code);
      apply(code, selection.name);
      controller.text = selection.code;
    });
  }

  Future<void> _pickPaciente() async {
    final EntityLookupSelection? selection =
        await EntityLookupPicker.pickPaciente(context);
    await _applyLookupSelection(
      selection: selection,
      controller: _codpacController,
      apply: (int? code, String? name) {
        _codpac = code;
        _pacNome = name;
      },
    );
  }

  Future<void> _pickMedico() async {
    final EntityLookupSelection? selection =
        await EntityLookupPicker.pickMedico(context);
    await _applyLookupSelection(
      selection: selection,
      controller: _codmedController,
      apply: (int? code, String? name) {
        _codmed = code;
        _medNome = name;
      },
    );
  }

  Future<void> _pickHospital() async {
    final EntityLookupSelection? selection =
        await EntityLookupPicker.pickHospital(context);
    await _applyLookupSelection(
      selection: selection,
      controller: _codcliController,
      apply: (int? code, String? name) {
        _codcli = code;
        _cliNome = name;
      },
    );
  }

  Future<void> _pickConvenio() async {
    final EntityLookupSelection? selection =
        await EntityLookupPicker.pickConvenio(context);
    await _applyLookupSelection(
      selection: selection,
      controller: _codconvController,
      apply: (int? code, String? name) {
        _codconv = code;
        _convNome = name;
      },
    );
  }

  Future<void> _pickTipoCirurgia() async {
    final EntityLookupSelection? selection =
        await EntityLookupPicker.pickTipoCirurgia(context);
    await _applyLookupSelection(
      selection: selection,
      controller: _circodController,
      apply: (int? code, String? name) {
        _circod = code;
        _tipoCirNome = name;
      },
    );
  }

  Widget _buildCadastroTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _field('No Relatorio', _numrelController),
        _field('No Agenda', _nagecirController),
        _field('No Ropme', _numreqController),
        _field('Data Emissao', _datmovController),
        _lookupField('Paciente *', _codpacController, _pacNome, _pickPaciente),
        _lookupField('Medico *', _codmedController, _medNome, _pickMedico),
        _lookupField('Convenio', _codconvController, _convNome, _pickConvenio),
        _lookupField('Local Cirurgia', _codcliController, _cliNome, _pickHospital),
      ],
    );
  }

  Widget _buildOutrosTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _field('Cod Instr', _codinsController),
        _field('Instrumentador Hospital', _inshosController),
        _field('Fim', _hrfinController),
        _field('Cod Circulante', _codcirController),
        _field('Nome Circulante', _nomcirController),
        _field('Cod Levou', _codlevController),
        _field('Sistema', _sistemaController),
        _field('No Req', _numreqController),
        _field('Idade', _idadeController),
        _field('Circulante Hospital', _cirhosController),
        _dropdown('Rel Concluido', _status, <String>['S', 'N'], (String? v) => setState(() => _status = v)),
        _dropdown('Urgencia', _urgencia, <String>['S', 'N'], (String? v) => setState(() => _urgencia = v)),
        _field('Data Cirurgia *', _datcirController),
        _dropdown('Lado', _lado, <String>['D', 'E', 'A'], (String? v) => setState(() => _lado = v)),
        _field('Grau', _grauController),
        _field('Cod Trouxe', _codtroController),
        _lookupField('Tipo Cirurgia', _circodController, _tipoCirNome, _pickTipoCirurgia),
        _field('Inicio', _hriniController),
        _dropdown('Primaria/Revisao', _priRev, <String>['P', 'R'], (String? v) => setState(() => _priRev = v)),
        _dropdown('Sexo', _sexo, <String>['M', 'F'], (String? v) => setState(() => _sexo = v)),
        _field('No Prontuario', _nprontuarioController),
      ],
    );
  }

  Widget _buildAvaliacaoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Text('Avaliacao do Hospital', style: TextStyle(fontWeight: FontWeight.bold)),
        _satisfacaoDropdown('Nivel Sat C/ Material', _satisfacaoMatHospital, (String? v) => setState(() => _satisfacaoMatHospital = v)),
        _satisfacaoDropdown('Nivel Sat C/ Instrum', _satisfacaoInstHospital, (String? v) => setState(() => _satisfacaoInstHospital = v)),
        const SizedBox(height: 16),
        const Text('Avaliacao do Cirurgiao', style: TextStyle(fontWeight: FontWeight.bold)),
        _satisfacaoDropdown('Nivel Sat C/ Material', _satisfacaoMatCirurg, (String? v) => setState(() => _satisfacaoMatCirurg = v)),
        _satisfacaoDropdown('Nivel Sat C/ Instrum', _satisfacaoInstCirurg, (String? v) => setState(() => _satisfacaoInstCirurg = v)),
      ],
    );
  }

  Widget _buildObservacaoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _multilineSection('Observacao', _historicoController),
        _multilineSection('Material da Cirurgia', _sistemaAplicadoController),
        _multilineSection('Obs Estoque', _obsEstoqueController),
        _multilineSection('Obs Gerencia', _obsGerenciaController),
        _multilineSection('Obs RT', _obsRtController),
      ],
    );
  }

  Widget _buildMaisTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _multiline('Problema Cirurgia', _problemaController),
        _dropdown('Problema Cirurgia (flag)', _relProb, <String>['S', 'N'], (String? v) => setState(() => _relProb = v)),
        _multiline('Problema retorno material', _problemaRetornoController),
        _multiline('Problema imp', _problemaImpController),
        _field('Medida tomada estoque', _medidaEstoqueController),
        _field('Endereco inicio', _enderecoInicioController),
        _field('Endereco fim', _enderecoFimController),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return FormSectionField(
      label: label,
      controller: controller,
    );
  }

  Widget _multiline(String label, TextEditingController controller) {
    return FormSectionField(
      label: label,
      controller: controller,
      maxLines: 8,
    );
  }

  Widget _multilineSection(String label, TextEditingController controller) {
    return FormSectionField(
      label: label,
      controller: controller,
      maxLines: 8,
    );
  }

  Widget _lookupField(
    String label,
    TextEditingController controller,
    String? nome,
    VoidCallback onSearch,
  ) {
    return FormSectionField(
      label: label,
      controller: controller,
      subtitle: nome,
      onSearch: onSearch,
      keyboardType: TextInputType.number,
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return FormSectionDropdown<String>(
      label: label,
      value: value ?? options.first,
      items: options
          .map(
            (String option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _satisfacaoDropdown(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return FormSectionDropdown<String?>(
      label: label,
      value: value,
      items: kSatisfacaoOptions
          .map(
            (MapEntry<String, String> entry) => DropdownMenuItem<String?>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Relatorio' : 'Novo Relatorio'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        actions: <Widget>[
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: IndexedStack(
          index: _tabIndex,
          children: <Widget>[
            _buildCadastroTab(),
            _buildOutrosTab(),
            _buildAvaliacaoTab(),
            _buildObservacaoTab(),
            _buildMaisTab(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (int index) => setState(() => _tabIndex = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Cadastro'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Outros'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Avaliacao'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Observacao'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
      ),
    );
  }
}
