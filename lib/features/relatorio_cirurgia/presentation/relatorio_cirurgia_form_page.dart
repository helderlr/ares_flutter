import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/permissions/user_permissions.dart';
import '../../../core/widgets/entity_lookup_picker.dart';
import '../../../core/widgets/form_section_field.dart';
import '../../../core/widgets/protected_ui.dart';
import '../../agendamento/models/agendamento_model.dart';
import '../../agendamento/services/agendamento_service.dart';
import '../../login/services/auth_service.dart';
import '../models/relatorio_cirurgia_model.dart';
import '../services/relatorio_cirurgia_service.dart';
import '../utils/relatorio_field_labels.dart';

class RelatorioCirurgiaFormPage extends StatefulWidget {
  final RelatorioCirurgia? relatorio;

  const RelatorioCirurgiaFormPage({super.key, this.relatorio});

  @override
  State<RelatorioCirurgiaFormPage> createState() =>
      _RelatorioCirurgiaFormPageState();
}

class _RelatorioCirurgiaFormPageState extends State<RelatorioCirurgiaFormPage> {
  final RelatorioCirurgiaService _service = RelatorioCirurgiaService();
  final AgendamentoService _agendaService = AgendamentoService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _tabIndex = 0;
  bool _isSaving = false;
  bool _isLoadingAgenda = false;
  bool _canEdit = true;
  String? _blockMessage;
  int? _codpac;
  int? _codmed;
  int? _codcli;
  int? _codconv;
  int? _circod;
  int? _codins;
  int? _codcir;
  String? _pacNome;
  String? _medNome;
  String? _cliNome;
  String? _convNome;
  String? _tipoCirNome;
  String? _digitadoPorNome;
  final TextEditingController _nagecirController = TextEditingController();
  final TextEditingController _numreqController = TextEditingController();
  final TextEditingController _datmovController = TextEditingController();
  final TextEditingController _nomeInstrController = TextEditingController();
  final TextEditingController _inshosController = TextEditingController();
  final TextEditingController _hrfinController = TextEditingController();
  final TextEditingController _nomcirController = TextEditingController();
  final TextEditingController _codlevController = TextEditingController();
  final TextEditingController _sistemaController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _cirhosController = TextEditingController();
  final TextEditingController _codtroController = TextEditingController();
  final TextEditingController _datcirController = TextEditingController();
  final TextEditingController _hriniController = TextEditingController();
  final TextEditingController _nprontuarioController = TextEditingController();
  final TextEditingController _grauController = TextEditingController();
  final TextEditingController _historicoController = TextEditingController();
  final TextEditingController _obsEstoqueController = TextEditingController();
  final TextEditingController _obsGerenciaController = TextEditingController();
  final TextEditingController _obsRtController = TextEditingController();
  final TextEditingController _problemaController = TextEditingController();
  final TextEditingController _problemaRetornoController =
      TextEditingController();
  final TextEditingController _problemaImpController = TextEditingController();
  final TextEditingController _medidaEstoqueController =
      TextEditingController();
  final TextEditingController _sistemaAplicadoController =
      TextEditingController();
  final TextEditingController _enderecoInicioController =
      TextEditingController();
  final TextEditingController _enderecoFimController = TextEditingController();
  final TextEditingController _digitadoPorController = TextEditingController();
  String? _lado;
  String? _sexo;
  String? _statusDisplay;
  String? _urgenciaDisplay;
  String? _priRevDisplay;
  String? _relProb;
  String? _satisfacaoMatHospital;
  String? _satisfacaoInstHospital;
  String? _satisfacaoMatCirurg;
  String? _satisfacaoInstCirurg;
  Timer? _nagecirDebounce;

  bool get _isEditing => widget.relatorio != null;
  bool get _isReadOnly => !_canEdit;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadFrom(widget.relatorio!);
    } else {
      final DateTime today = DateTime.now();
      _datmovController.text = _formatDateBr(today);
      _sexo = 'M';
      _relProb = 'N';
    }
    _nagecirController.addListener(_onNagecirChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateAccess();
      _loadDigitadorForNew();
    });
  }

  Future<void> _loadDigitadorForNew() async {
    if (_isEditing) {
      return;
    }
    final int? codusu = await AuthService.getCurrentCodusu();
    final dynamic user = await AuthService.getCurrentUser();
    if (!mounted) {
      return;
    }
    final String? nome = user?.nome?.toString();
    if (codusu != null || (nome != null && nome.isNotEmpty)) {
      setState(() {
        _digitadoPorNome = nome;
        _digitadoPorController.text = nome != null && nome.isNotEmpty
            ? '$nome (cód. $codusu)'
            : 'cód. $codusu';
      });
    }
  }

  @override
  void dispose() {
    _nagecirDebounce?.cancel();
    _nagecirController.removeListener(_onNagecirChanged);
    _nagecirController.dispose();
    _numreqController.dispose();
    _datmovController.dispose();
    _nomeInstrController.dispose();
    _inshosController.dispose();
    _hrfinController.dispose();
    _nomcirController.dispose();
    _codlevController.dispose();
    _sistemaController.dispose();
    _idadeController.dispose();
    _cirhosController.dispose();
    _codtroController.dispose();
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
    _digitadoPorController.dispose();
    super.dispose();
  }

  Future<void> _validateAccess() async {
    if (!_isEditing) {
      return;
    }
    final UserPermissions permissions = await AuthService.getUserPermissions();
    final RelatorioAccess access =
        widget.relatorio!.evaluateAccess(permissions);
    if (!mounted) {
      return;
    }
    setState(() {
      _canEdit = access.canEdit;
      _blockMessage = access.blockReason;
    });
    if (!access.canEdit) {
      setState(() {
        _canEdit = false;
        _blockMessage = access.blockReason;
      });
    }
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

  void _onNagecirChanged() {
    if (_isReadOnly) {
      return;
    }
    _nagecirDebounce?.cancel();
    _nagecirDebounce = Timer(const Duration(milliseconds: 800), () {
      final int? nagecir = _parseIntField(_nagecirController);
      if (nagecir != null && nagecir > 0) {
        _loadFromAgenda();
      }
    });
  }

  Future<void> _loadFromAgenda() async {
    if (_isReadOnly) {
      return;
    }
    final int? nagecir = _parseIntField(_nagecirController);
    if (nagecir == null) {
      return;
    }
    setState(() => _isLoadingAgenda = true);
    try {
      final AgendaCirurgia? agenda =
          await _agendaService.fetchAgendaById(nagecir);
      if (!mounted) {
        return;
      }
      if (agenda == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agenda nao encontrada.')),
        );
        return;
      }
      setState(() {
        _codpac = agenda.codpac;
        _pacNome = agenda.nompac;
        _codmed = agenda.codmed;
        _medNome = agenda.nommed;
        _codcli = agenda.codcli;
        _cliNome = agenda.nomcli;
        _codconv = agenda.codconv;
        _convNome = agenda.nomconv;
        _circod = agenda.codcir;
        _tipoCirNome = agenda.tipoCirurgiaDisplay;
        _lado = agenda.lado;
        _priRevDisplay = RelatorioFieldLabels.priRevToDisplay(agenda.primrev);
        _urgenciaDisplay =
            RelatorioFieldLabels.snToDisplay(agenda.cirurgiaUrgencia);
        _codins = agenda.codinstru1;
        _nomeInstrController.text = agenda.nominstru1 ?? '';
        if (agenda.datcir != null) {
          _datcirController.text = _formatDateBr(agenda.datcir!);
        }
        if ((agenda.horcir ?? '').trim().isNotEmpty) {
          _hriniController.text = agenda.horcir!.trim();
        }
        if (agenda.numreq != null) {
          _numreqController.text = agenda.numreq.toString();
        }
        if ((agenda.procir ?? '').trim().isNotEmpty &&
            _nomcirController.text.trim().isEmpty) {
          _nomcirController.text = agenda.procir!.trim();
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
        setState(() => _isLoadingAgenda = false);
      }
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    if (_isReadOnly) {
      return;
    }
    final DateTime initial =
        _parseDateBr(controller.text) ?? DateTime.now();
    final DateTime? picked = await showProtectedDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      setState(() => controller.text = _formatDateBr(picked));
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    if (_isReadOnly) {
      return;
    }
    TimeOfDay initial = const TimeOfDay(hour: 8, minute: 0);
    final String current = controller.text.trim();
    final RegExp pattern = RegExp(r'^(\d{1,2}):(\d{2})');
    final Match? match = pattern.firstMatch(current);
    if (match != null) {
      initial = TimeOfDay(
        hour: int.parse(match.group(1)!),
        minute: int.parse(match.group(2)!),
      );
    }
    final TimeOfDay? picked = await showProtectedTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        controller.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _loadFrom(RelatorioCirurgia item) {
    _codpac = item.codpac;
    _codmed = item.codmed;
    _codcli = item.codcli;
    _codconv = item.codconv;
    _circod = item.circod;
    _codins = item.codins;
    _codcir = item.codcir;
    _pacNome = item.pacNome;
    _medNome = item.medNome;
    _cliNome = item.cliNome;
    _convNome = item.convNome;
    _tipoCirNome = item.tipoCirNome;
    _digitadoPorNome = item.digitadorLabel;
    _nagecirController.text = item.nagecir?.toString() ?? '';
    _numreqController.text = item.numreq?.toString() ?? '';
    _datmovController.text =
        item.datmov != null ? _formatDateBr(item.datmov!) : '';
    _nomeInstrController.text = '';
    _inshosController.text = item.inshos ?? '';
    _hrfinController.text = item.hrfin ?? '';
    _nomcirController.text = item.nomcir ?? '';
    _codlevController.text = item.codlev?.toString() ?? '';
    _sistemaController.text = item.sistema ?? '';
    _idadeController.text = item.idade?.toString() ?? '';
    _cirhosController.text = item.cirhos ?? '';
    _codtroController.text = item.codtro?.toString() ?? '';
    _datcirController.text =
        item.datcir != null ? _formatDateBr(item.datcir!) : '';
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
    _digitadoPorController.text = item.digitadorLabel;
    _lado = item.lado;
    _priRevDisplay = RelatorioFieldLabels.priRevToDisplay(item.priRev);
    _sexo = item.sexo ?? 'M';
    _statusDisplay = RelatorioFieldLabels.snToDisplay(item.status);
    _urgenciaDisplay = RelatorioFieldLabels.snToDisplay(item.urgencia);
    _relProb = item.relProb ?? 'N';
    _satisfacaoMatHospital = item.satisfacaoMatHospital;
    _satisfacaoInstHospital = item.satisfacaoInstHospital;
    _satisfacaoMatCirurg = item.satisfacaoMatCirurg;
    _satisfacaoInstCirurg = item.satisfacaoInstCirurg;
  }

  RelatorioCirurgia _buildDraft() {
    return RelatorioCirurgia(
      nummov: widget.relatorio?.nummov ?? 0,
      numrel: widget.relatorio?.numrel,
      nagecir: _parseIntField(_nagecirController),
      numreq: _parseIntField(_numreqController),
      datmov: _parseDateBr(_datmovController.text),
      codpac: _codpac,
      codmed: _codmed,
      codconv: _codconv,
      codcli: _codcli,
      codins: _codins,
      inshos: _inshosController.text.trim().isEmpty
          ? null
          : _inshosController.text.trim(),
      hrfin: _hrfinController.text.trim().isEmpty
          ? null
          : _hrfinController.text.trim(),
      codcir: _codcir,
      nomcir: _nomcirController.text.trim().isEmpty
          ? null
          : _nomcirController.text.trim(),
      codlev: _parseIntField(_codlevController),
      sistema: _sistemaController.text.trim().isEmpty
          ? null
          : _sistemaController.text.trim(),
      idade: _parseIntField(_idadeController),
      cirhos: _cirhosController.text.trim().isEmpty
          ? null
          : _cirhosController.text.trim(),
      codtro: _parseIntField(_codtroController),
      circod: _circod,
      datcir: _parseDateBr(_datcirController.text),
      hrini: _hriniController.text.trim().isEmpty
          ? null
          : _hriniController.text.trim(),
      nprontuario: _nprontuarioController.text.trim().isEmpty
          ? null
          : _nprontuarioController.text.trim(),
      grau: _grauController.text.trim().isEmpty
          ? null
          : _grauController.text.trim(),
      historico: _historicoController.text.trim().isEmpty
          ? null
          : _historicoController.text.trim(),
      obsEstoque: _obsEstoqueController.text.trim().isEmpty
          ? null
          : _obsEstoqueController.text.trim(),
      obsGerencia: _obsGerenciaController.text.trim().isEmpty
          ? null
          : _obsGerenciaController.text.trim(),
      obsRt: _obsRtController.text.trim().isEmpty
          ? null
          : _obsRtController.text.trim(),
      problema: _problemaController.text.trim().isEmpty
          ? null
          : _problemaController.text.trim(),
      problemaRetornoMat: _problemaRetornoController.text.trim().isEmpty
          ? null
          : _problemaRetornoController.text.trim(),
      problemaImp: _problemaImpController.text.trim().isEmpty
          ? null
          : _problemaImpController.text.trim(),
      medidaTomadaEstoque: _medidaEstoqueController.text.trim().isEmpty
          ? null
          : _medidaEstoqueController.text.trim(),
      sistemaAplicado: _sistemaAplicadoController.text.trim().isEmpty
          ? null
          : _sistemaAplicadoController.text.trim(),
      enderecoInicio: _enderecoInicioController.text.trim().isEmpty
          ? null
          : _enderecoInicioController.text.trim(),
      enderecoFim: _enderecoFimController.text.trim().isEmpty
          ? null
          : _enderecoFimController.text.trim(),
      lado: _lado,
      priRev: RelatorioFieldLabels.displayToPriRev(_priRevDisplay),
      sexo: _sexo,
      status: RelatorioFieldLabels.displayToSn(_statusDisplay),
      urgencia: RelatorioFieldLabels.displayToSn(_urgenciaDisplay),
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
      usulan: widget.relatorio?.usulan,
      usulanNome: _digitadoPorNome,
    );
  }

  Future<void> _save() async {
    if (_isReadOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_blockMessage ?? 'Não é possível salvar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_codpac == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o paciente.')),
      );
      setState(() => _tabIndex = 0);
      return;
    }
    if (_codmed == null) {
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

  Future<void> _pickPaciente() async {
    final EntityLookupSelection? selection =
        await EntityLookupPicker.pickPaciente(context);
    if (selection == null) {
      return;
    }
    setState(() {
      _codpac = int.tryParse(selection.code);
      _pacNome = selection.name;
    });
  }

  Future<void> _pickMedico() async {
    final EntityLookupSelection? selection =
        await EntityLookupPicker.pickMedico(context);
    if (selection == null) {
      return;
    }
    setState(() {
      _codmed = int.tryParse(selection.code);
      _medNome = selection.name;
    });
  }

  Future<void> _pickHospital() async {
    final EntityLookupSelection? selection =
        await EntityLookupPicker.pickHospital(context);
    if (selection == null) {
      return;
    }
    setState(() {
      _codcli = int.tryParse(selection.code);
      _cliNome = selection.name;
    });
  }

  Future<void> _pickConvenio() async {
    final EntityLookupSelection? selection =
        await EntityLookupPicker.pickConvenio(context);
    if (selection == null) {
      return;
    }
    setState(() {
      _codconv = int.tryParse(selection.code);
      _convNome = selection.name;
    });
  }

  Future<void> _pickTipoCirurgia() async {
    final EntityLookupSelection? selection =
        await EntityLookupPicker.pickTipoCirurgia(context);
    if (selection == null) {
      return;
    }
    setState(() {
      _circod = int.tryParse(selection.code);
      _tipoCirNome = selection.name;
    });
  }

  Widget _buildBlockBanner() {
    if (_blockMessage == null || _canEdit) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: Colors.red.shade50,
      padding: const EdgeInsets.all(12),
      child: Text(
        _blockMessage!,
        style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildCadastroTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        FormSectionField(
          label: 'No Agenda',
          controller: _nagecirController,
          readOnly: _isReadOnly,
          keyboardType: TextInputType.number,
          onSearch: _isReadOnly ? null : _loadFromAgenda,
          actionIcon: Icons.download_outlined,
        ),
        if (_isLoadingAgenda)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        _field('No Ropme', _numreqController),
        _field('Data Emissao', _datmovController),
        FormSectionLookup(
          label: 'Paciente *',
          value: _pacNome,
          onSearch: _isReadOnly ? null : _pickPaciente,
          readOnly: _isReadOnly,
        ),
        FormSectionLookup(
          label: 'Medico *',
          value: _medNome,
          onSearch: _isReadOnly ? null : _pickMedico,
          readOnly: _isReadOnly,
        ),
        FormSectionLookup(
          label: 'Convenio',
          value: _convNome,
          onSearch: _isReadOnly ? null : _pickConvenio,
          readOnly: _isReadOnly,
        ),
        FormSectionLookup(
          label: 'Local Cirurgia',
          value: _cliNome,
          onSearch: _isReadOnly ? null : _pickHospital,
          readOnly: _isReadOnly,
        ),
      ],
    );
  }

  Widget _buildOutrosTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _field('Instrumentador', _nomeInstrController),
        _dateField('Data Cirurgia *', _datcirController),
        _timeField('Inicio', _hriniController),
        _timeField('Fim', _hrfinController),
        _field('Instrumentador Hospital', _inshosController),
        _dropdown('Lado', _lado, <String>['D', 'E', 'A'],
            (String? v) => setState(() => _lado = v)),
        _priRevDropdown(),
        _field('Circulante', _nomcirController),
        _field('Circulante Hospital', _cirhosController),
        _dropdown('Sexo', _sexo, <String>['M', 'F'],
            (String? v) => setState(() => _sexo = v)),
        FormSectionField(
          label: 'Digitado por',
          controller: _digitadoPorController,
          readOnly: true,
        ),
        _field('Idade', _idadeController),
        _field('Grau', _grauController),
        _field('No Prontuario', _nprontuarioController),
        _field('Cod Levou', _codlevController),
        _field('Cod Trouxe', _codtroController),
        _field('Sistema', _sistemaController),
        _simNaoDropdown(
          'Rel Concluido',
          _statusDisplay,
          (String? v) => setState(() => _statusDisplay = v),
        ),
        FormSectionLookup(
          label: 'Tipo Cirurgia',
          value: _tipoCirNome,
          onSearch: _isReadOnly ? null : _pickTipoCirurgia,
          readOnly: _isReadOnly,
        ),
        _field('No Req', _numreqController),
        _simNaoDropdown(
          'Urgencia',
          _urgenciaDisplay,
          (String? v) => setState(() => _urgenciaDisplay = v),
        ),
      ],
    );
  }

  Widget _dateField(String label, TextEditingController controller) {
    return FormSectionField(
      label: label,
      controller: controller,
      readOnly: true,
      onSearch: _isReadOnly ? null : () => _pickDate(controller),
      actionIcon: Icons.calendar_today,
    );
  }

  Widget _timeField(String label, TextEditingController controller) {
    return FormSectionField(
      label: label,
      controller: controller,
      readOnly: true,
      onSearch: _isReadOnly ? null : () => _pickTime(controller),
      actionIcon: Icons.access_time,
    );
  }

  Widget _simNaoDropdown(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return FormSectionDropdown<String?>(
      label: label,
      value: value,
      items: const <DropdownMenuItem<String?>>[
        DropdownMenuItem<String?>(value: null, child: Text('')),
        DropdownMenuItem<String?>(value: 'Sim', child: Text('Sim')),
        DropdownMenuItem<String?>(value: 'Não', child: Text('Não')),
      ],
      onChanged: onChanged,
      readOnly: _isReadOnly,
    );
  }

  Widget _priRevDropdown() {
    return FormSectionDropdown<String?>(
      label: 'Primaria/Revisao',
      value: _priRevDisplay,
      items: const <DropdownMenuItem<String?>>[
        DropdownMenuItem<String?>(value: null, child: Text('')),
        DropdownMenuItem<String?>(
          value: 'Primaria',
          child: Text('Primaria'),
        ),
        DropdownMenuItem<String?>(
          value: 'Revisao',
          child: Text('Revisao'),
        ),
      ],
      onChanged: (String? v) => setState(() => _priRevDisplay = v),
      readOnly: _isReadOnly,
    );
  }

  Widget _buildAvaliacaoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Text('Avaliacao do Hospital',
            style: TextStyle(fontWeight: FontWeight.bold)),
        _satisfacaoDropdown('Nivel Sat C/ Material', _satisfacaoMatHospital,
            (String? v) => setState(() => _satisfacaoMatHospital = v)),
        _satisfacaoDropdown('Nivel Sat C/ Instrum', _satisfacaoInstHospital,
            (String? v) => setState(() => _satisfacaoInstHospital = v)),
        const SizedBox(height: 16),
        const Text('Avaliacao do Cirurgiao',
            style: TextStyle(fontWeight: FontWeight.bold)),
        _satisfacaoDropdown('Nivel Sat C/ Material', _satisfacaoMatCirurg,
            (String? v) => setState(() => _satisfacaoMatCirurg = v)),
        _satisfacaoDropdown('Nivel Sat C/ Instrum', _satisfacaoInstCirurg,
            (String? v) => setState(() => _satisfacaoInstCirurg = v)),
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
        _dropdown('Problema Cirurgia (flag)', _relProb, <String>['S', 'N'],
            (String? v) => setState(() => _relProb = v)),
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
      readOnly: _isReadOnly,
    );
  }

  Widget _multiline(String label, TextEditingController controller) {
    return FormSectionField(
      label: label,
      controller: controller,
      maxLines: 8,
      readOnly: _isReadOnly,
    );
  }

  Widget _multilineSection(String label, TextEditingController controller) {
    return FormSectionField(
      label: label,
      controller: controller,
      maxLines: 8,
      readOnly: _isReadOnly,
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return FormSectionDropdown<String?>(
      label: label,
      value: value,
      items: options
          .map(
            (String option) => DropdownMenuItem<String?>(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      onChanged: onChanged,
      readOnly: _isReadOnly,
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
      readOnly: _isReadOnly,
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else if (!_isReadOnly)
            IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            _buildBlockBanner(),
            Expanded(
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
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (int index) => setState(() => _tabIndex = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
              icon: Icon(Icons.description_outlined), label: 'Cadastro'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Outros'),
          NavigationDestination(
              icon: Icon(Icons.fact_check_outlined), label: 'Avaliacao'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'Observacao'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
      ),
    );
  }
}
