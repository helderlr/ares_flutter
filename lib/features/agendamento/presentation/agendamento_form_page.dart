import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/agendamento_model.dart';
import '../services/agendamento_service.dart';
import '../../paciente/services/paciente_service.dart';
import '../../medico/services/medico_service_paginado.dart';
import '../../hospital/services/hospital_service_paginado.dart';
import '../../convenio/services/convenio_service_paginado.dart';
import '../../tipo_cirurgia/services/tipo_cirurgia_service_paginado.dart';

class AgendamentoFormPage extends StatefulWidget {
  final AgendaCirurgia? agendamento;

  const AgendamentoFormPage({Key? key, this.agendamento}) : super(key: key);

  @override
  State<AgendamentoFormPage> createState() => _AgendamentoFormPageState();
}

class _AgendamentoFormPageState extends State<AgendamentoFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AgendamentoService _service = AgendamentoService();
  final PacienteService _pacienteService = PacienteService();
  final MedicoServicePaginado _medicoService = MedicoServicePaginado();
  final HospitalServicePaginado _hospitalService = HospitalServicePaginado();
  final ConvenioServicePaginado _convenioService = ConvenioServicePaginado();
  final TipoCirurgiaServicePaginado _cirurgiaService =
      TipoCirurgiaServicePaginado();

  // Controllers para os campos do formulário
  final TextEditingController _pacienteController = TextEditingController();
  final TextEditingController _medicoController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _convenioController = TextEditingController();
  final TextEditingController _cirurgiaController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _ladoController = TextEditingController();
  final TextEditingController _nomeCirurgiaController = TextEditingController();
  final TextEditingController _solicitanteController = TextEditingController();
  final TextEditingController _materialCirurgiaController =
      TextEditingController();

  // IDs necessários para criação/atualização
  int? _codpac;
  int? _codmed;
  int? _codcli;
  int? _codconv;

  bool _isLoading = false;
  bool _isEditing = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Variáveis para busca de entidades
  String? _selectedPacienteName;
  String? _selectedMedicoName;
  String? _selectedHospitalName;
  String? _selectedConvenioName;
  String? _selectedCirurgiaName;

  // Variáveis para campos de seleção
  String? _selectedPrimariaRevisao;
  String? _selectedAgendaCancelada;
  String? _selectedCirurgiaUrgencia;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.agendamento != null;

    if (_isEditing) {
      _loadAgendamentoData();
    } else {
      // Para novos agendamentos, definir alguns valores padrão
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedTime = const TimeOfDay(hour: 8, minute: 0);
      _updateDateTimeControllers();
    }
  }

  void _loadAgendamentoData() {
    final agendamento = widget.agendamento!;

    // Carregar nomes selecionados em vez dos controllers (serão somente leitura)
    _selectedPacienteName = agendamento.nompac ?? '';
    _selectedMedicoName = agendamento.nommed ?? '';
    _selectedHospitalName = agendamento.nomcli ?? '';
    _selectedConvenioName = agendamento.nomconv ?? '';
    _selectedCirurgiaName = agendamento.nomcir ?? '';

    // Limpar controllers pois serão campos de busca
    _pacienteController.clear();
    _medicoController.clear();
    _hospitalController.clear();
    _convenioController.clear();
    _cirurgiaController.clear();

    _ladoController.text = agendamento.lado ?? '';

    // Carregar novos campos
    _nomeCirurgiaController.text = agendamento.nomcir ?? '';
    _solicitanteController.text = agendamento.solicitou ?? '';
    _materialCirurgiaController.text = agendamento.matcir ?? '';
    _selectedPrimariaRevisao = agendamento.primrev;
    _selectedAgendaCancelada = agendamento.agendaCancelada;
    _selectedCirurgiaUrgencia = agendamento.cirurgiaUrgencia;

    _codpac = agendamento.codpac;
    _codmed = agendamento.codmed;
    _codcli = agendamento.codcli;
    _codconv = agendamento.codconv;

    _selectedDate = agendamento.datcir;
    if (agendamento.horcir != null && agendamento.horcir!.isNotEmpty) {
      try {
        final parts = agendamento.horcir!.split(':');
        if (parts.length >= 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        print('Erro ao parsear hora: ${agendamento.horcir}');
      }
    }
    _updateDateTimeControllers();
  }

  void _updateDateTimeControllers() {
    if (_selectedDate != null) {
      _dataController.text =
          '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';
    }
    if (_selectedTime != null) {
      _horaController.text =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _pacienteController.dispose();
    _medicoController.dispose();
    _hospitalController.dispose();
    _convenioController.dispose();
    _cirurgiaController.dispose();
    _dataController.dispose();
    _horaController.dispose();
    _ladoController.dispose();
    _nomeCirurgiaController.dispose();
    _solicitanteController.dispose();
    _materialCirurgiaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Agenda' : 'Nova Agenda'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isEditing)
                        _buildReadOnlyField(
                            'No Agenda', widget.agendamento!.nummov.toString()),
                      _buildPacienteSearchField(),
                      _buildMedicoSearchField(),
                      _buildHospitalSearchField(),
                      _buildConvenioSearchField(),
                      _buildCirurgiaSearchField(),
                      _buildNomeCirurgiaField(),
                      _buildDateField(),
                      _buildTimeField(),
                      _buildPrimariaRevisaoField(),
                      _buildAgendaCanceladaField(),
                      _buildSolicitanteField(),
                      _buildCirurgiaUrgenciaField(),
                      _buildLadoField(),
                      _buildMaterialCirurgiaField(),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 60,
              color: AppColors.lightBlue,
              child: Row(
                children: [
                  // Botão CANCELAR
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : () => Navigator.pop(context),
                      child: Container(
                        color: Colors.transparent,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cancel,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'CANCELAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Linha divisória
                  Container(
                    width: 1,
                    color: Colors.white,
                  ),
                  // Botão SALVAR
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : _saveAgendamento,
                      child: Container(
                        color: Colors.transparent,
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'SALVANDO...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isEditing ? Icons.save : Icons.add,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SALVAR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPacienteSearchField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'Paciente *',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Se está editando, mostrar nome atual + botão para trocar
          if (_isEditing && _selectedPacienteName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedPacienteName!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.blue[700]),
                    onPressed: _showPacienteSearchDialog,
                    tooltip: 'Buscar outro paciente',
                  ),
                ],
              ),
            ),
          ] else ...[
            // Se é novo agendamento, mostrar campo de busca
            InkWell(
              onTap: _showPacienteSearchDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedPacienteName ?? 'Toque para buscar paciente',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedPacienteName != null
                              ? Colors.black87
                              : Colors.grey[600],
                          fontWeight: _selectedPacienteName != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required String label,
    required String? selectedValue,
    required VoidCallback onTap,
    required String placeholder,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Se está editando, mostrar nome atual + botão para trocar
          if (_isEditing && selectedValue != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedValue,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.blue[700]),
                    onPressed: onTap,
                    tooltip: 'Buscar outro ${label.toLowerCase()}',
                  ),
                ],
              ),
            ),
          ] else ...[
            // Se é novo agendamento, mostrar campo de busca
            InkWell(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedValue ?? placeholder,
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedValue != null
                              ? Colors.black87
                              : Colors.grey[600],
                          fontWeight: selectedValue != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicoSearchField() {
    return _buildSearchField(
      label: 'Médico *',
      selectedValue: _selectedMedicoName,
      onTap: _showMedicoSearchDialog,
      placeholder: 'Toque para buscar médico',
    );
  }

  Widget _buildHospitalSearchField() {
    return _buildSearchField(
      label: 'Hospital/Clínica *',
      selectedValue: _selectedHospitalName,
      onTap: _showHospitalSearchDialog,
      placeholder: 'Toque para buscar hospital',
    );
  }

  Widget _buildConvenioSearchField() {
    return _buildSearchField(
      label: 'Convênio *',
      selectedValue: _selectedConvenioName,
      onTap: _showConvenioSearchDialog,
      placeholder: 'Toque para buscar convênio',
    );
  }

  Widget _buildCirurgiaSearchField() {
    return _buildSearchField(
      label: 'Cirurgia *',
      selectedValue: _selectedCirurgiaName,
      onTap: _showCirurgiaSearchDialog,
      placeholder: 'Toque para buscar cirurgia',
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (título em negrito)
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Campo somente leitura
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            width: double.infinity,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Linha divisória
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      bool isRequired, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (título em negrito)
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Campo de entrada
          TextFormField(
            controller: controller,
            textCapitalization: label.contains('Paciente') ||
                    label.contains('Médico') ||
                    label.contains('Hospital') ||
                    label.contains('Convênio') ||
                    label.contains('Cirurgia')
                ? TextCapitalization.words
                : TextCapitalization.none,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: _getHintText(label),
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
            maxLines: label.contains('Observações') ? 3 : 1,
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo é obrigatório';
                    }
                    return null;
                  }
                : null,
          ),
          const SizedBox(height: 12),
          // Linha divisória
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  String _getHintText(String label) {
    switch (label) {
      case 'Paciente *':
        return 'Digite o nome do paciente';
      case 'Médico *':
        return 'Digite o nome do médico';
      case 'Hospital/Clínica *':
        return 'Digite o nome do hospital ou clínica';
      case 'Convênio *':
        return 'Digite o nome do convênio';
      case 'Cirurgia *':
        return 'Digite o nome da cirurgia';
      case 'Autorização':
        return 'Número da autorização';
      case 'Observações':
        return 'Observações sobre o agendamento';
      default:
        return '';
    }
  }

  Widget _buildDateField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (título em negrito)
          const Text(
            'Data da Cirurgia *',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Campo de entrada
          TextFormField(
            controller: _dataController,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'dd/mm/aaaa',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_today, color: Colors.blue[700]),
                onPressed: _selectDate,
                tooltip: 'Selecionar data',
              ),
            ),
            readOnly: true,
            onTap: _selectDate,
            validator: (value) {
              if (_selectedDate == null) {
                return 'Selecione uma data';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          // Linha divisória
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (título em negrito)
          const Text(
            'Horário da Cirurgia *',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Campo de entrada
          TextFormField(
            controller: _horaController,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'hh:mm',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              suffixIcon: IconButton(
                icon: Icon(Icons.access_time, color: Colors.blue[700]),
                onPressed: _selectTime,
                tooltip: 'Selecionar horário',
              ),
            ),
            readOnly: true,
            onTap: _selectTime,
            validator: (value) {
              if (_selectedTime == null) {
                return 'Selecione um horário';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          // Linha divisória
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildLadoField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (título em negrito)
          const Text(
            'Lado da Cirurgia',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Campo de entrada
          DropdownButtonFormField<String>(
            value: _ladoController.text.isEmpty ? null : _ladoController.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Selecione o lado',
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Vazio')),
              DropdownMenuItem(value: 'D', child: Text('Direito')),
              DropdownMenuItem(value: 'E', child: Text('Esquerdo')),
            ],
            onChanged: (value) {
              setState(() {
                _ladoController.text = value ?? '';
              });
            },
          ),
          const SizedBox(height: 12),
          // Linha divisória
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildNomeCirurgiaField() {
    return _buildInputField(
        'Nome Cirurgia', _nomeCirurgiaController, false, Icons.healing);
  }

  Widget _buildPrimariaRevisaoField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Primária/Revisão',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPrimariaRevisao,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Selecione o tipo',
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Vazio')),
              DropdownMenuItem(value: 'P', child: Text('Primária')),
              DropdownMenuItem(value: 'R', child: Text('Revisão')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPrimariaRevisao = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaCanceladaField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agenda Cancelada',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedAgendaCancelada,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Selecione',
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Não informado')),
              DropdownMenuItem(value: 'S', child: Text('Sim')),
              DropdownMenuItem(value: 'N', child: Text('Não')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedAgendaCancelada = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitanteField() {
    return _buildInputField(
        'Nome Solicitante', _solicitanteController, false, Icons.person);
  }

  Widget _buildCirurgiaUrgenciaField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cirurgia Urgência',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCirurgiaUrgencia,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Selecione',
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Não informado')),
              DropdownMenuItem(value: 'S', child: Text('Sim')),
              DropdownMenuItem(value: 'N', child: Text('Não')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCirurgiaUrgencia = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCirurgiaField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Material Cirurgia',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: _materialCirurgiaController,
              maxLines: null,
              minLines: 3,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintText: 'Digite o material necessário para a cirurgia',
                hintStyle: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _updateDateTimeControllers();
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
        _updateDateTimeControllers();
      });
    }
  }

  Future<void> _showPacienteSearchDialog() async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Buscar Paciente'),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Campo de busca
                    TextField(
                      controller: searchController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Digite o nome do paciente',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: const BorderSide(color: Colors.lightBlue),
                        ),
                      ),
                      onChanged: (value) async {
                        // Converter para maiúscula e manter posição do cursor
                        final upperValue = value.toUpperCase();
                        if (value != upperValue) {
                          final cursorPosition =
                              searchController.selection.start;
                          searchController.value = TextEditingValue(
                            text: upperValue,
                            selection: TextSelection.collapsed(
                              offset: cursorPosition,
                            ),
                          );
                          value = upperValue;
                        }

                        if (value.length >= 2) {
                          setDialogState(() {
                            isSearching = true;
                          });

                          try {
                            final results =
                                await _pacienteService.searchPacientes(value);
                            setDialogState(() {
                              searchResults = results;
                              isSearching = false;
                            });
                          } catch (e) {
                            setDialogState(() {
                              searchResults = [];
                              isSearching = false;
                            });
                            print('Erro na busca: $e');
                          }
                        } else {
                          setDialogState(() {
                            searchResults = [];
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Lista de resultados
                    Expanded(
                      child: isSearching
                          ? Center(child: CircularProgressIndicator())
                          : searchResults.isEmpty
                              ? Center(
                                  child: Text(
                                    searchController.text.length >= 2
                                        ? 'Nenhum paciente encontrado'
                                        : 'Digite pelo menos 2 caracteres para buscar',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    final paciente = searchResults[index];
                                    final codpac = paciente['codpac'] ??
                                        paciente['CODPAC'];
                                    final nompac = paciente['nompac'] ??
                                        paciente['NOMPAC'] ??
                                        '';

                                    return ListTile(
                                      leading: CircleAvatar(
                                        child: Icon(Icons.person),
                                        backgroundColor: Colors.blue[100],
                                      ),
                                      title: Text(nompac),
                                      subtitle: Text('Código: $codpac'),
                                      onTap: () {
                                        setState(() {
                                          _codpac = codpac;
                                          _selectedPacienteName = nompac;
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showMedicoSearchDialog() async {
    await _showGenericSearchDialog<Map<String, dynamic>>(
      title: 'Buscar Médico',
      placeholder: 'Digite o nome do médico',
      searchFunction: (query) async {
        final response = await _medicoService.fetchMedicosPaginated(
          page: 1,
          pageSize: 20,
          searchQuery: query,
        );
        return response.medicos
            .map((medico) => {
                  'code': medico.codmed,
                  'name': medico.nommed,
                })
            .toList();
      },
      onSelected: (item) {
        setState(() {
          _codmed = item['code'];
          _selectedMedicoName = item['name'];
        });
      },
    );
  }

  Future<void> _showHospitalSearchDialog() async {
    await _showGenericSearchDialog<Map<String, dynamic>>(
      title: 'Buscar Hospital',
      placeholder: 'Digite o nome do hospital',
      searchFunction: (query) async {
        final response = await _hospitalService.fetchHospitaisPaginated(
          page: 1,
          pageSize: 20,
          searchQuery: query,
        );
        return response.hospitais
            .map((hospital) => {
                  'code': hospital.codcli,
                  'name': hospital.nomcli,
                })
            .toList();
      },
      onSelected: (item) {
        setState(() {
          _codcli = item['code'];
          _selectedHospitalName = item['name'];
        });
      },
    );
  }

  Future<void> _showConvenioSearchDialog() async {
    await _showGenericSearchDialog<Map<String, dynamic>>(
      title: 'Buscar Convênio',
      placeholder: 'Digite o nome do convênio',
      searchFunction: (query) async {
        final response = await _convenioService.fetchConveniosPaginated(
          page: 1,
          pageSize: 20,
          searchQuery: query,
        );
        return response.convenios
            .map((convenio) => {
                  'code': convenio.codcon,
                  'name': convenio.nomcon,
                })
            .toList();
      },
      onSelected: (item) {
        setState(() {
          _codconv = item['code'];
          _selectedConvenioName = item['name'];
        });
      },
    );
  }

  Future<void> _showCirurgiaSearchDialog() async {
    await _showGenericSearchDialog<Map<String, dynamic>>(
      title: 'Buscar Cirurgia',
      placeholder: 'Digite o nome da cirurgia',
      searchFunction: (query) async {
        final response = await _cirurgiaService.fetchTiposCirurgiaPaginated(
          page: 1,
          pageSize: 20,
          searchQuery: query,
        );
        return response.tiposCirurgia
            .map((cirurgia) => {
                  'code': cirurgia.codcir,
                  'name': cirurgia.nomcir,
                })
            .toList();
      },
      onSelected: (item) {
        setState(() {
          // Para cirurgia, vamos usar o nome como código também por enquanto
          _selectedCirurgiaName = item['name'];
        });
      },
    );
  }

  Future<void> _showGenericSearchDialog<T>({
    required String title,
    required String placeholder,
    required Future<List<T>> Function(String) searchFunction,
    required void Function(T) onSelected,
  }) async {
    final TextEditingController searchController = TextEditingController();
    List<T> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Campo de busca
                    TextField(
                      controller: searchController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: placeholder,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: const BorderSide(color: Colors.lightBlue),
                        ),
                      ),
                      onChanged: (value) async {
                        // Converter para maiúscula e manter posição do cursor
                        final upperValue = value.toUpperCase();
                        if (value != upperValue) {
                          final cursorPosition =
                              searchController.selection.start;
                          searchController.value = TextEditingValue(
                            text: upperValue,
                            selection: TextSelection.collapsed(
                              offset: cursorPosition,
                            ),
                          );
                          value = upperValue;
                        }

                        if (value.length >= 2) {
                          setDialogState(() {
                            isSearching = true;
                          });

                          try {
                            final results = await searchFunction(value);
                            setDialogState(() {
                              searchResults = results;
                              isSearching = false;
                            });
                          } catch (e) {
                            setDialogState(() {
                              searchResults = [];
                              isSearching = false;
                            });
                            print('Erro na busca: $e');
                          }
                        } else {
                          setDialogState(() {
                            searchResults = [];
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Lista de resultados
                    Expanded(
                      child: isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : searchResults.isEmpty
                              ? Center(
                                  child: Text(
                                    searchController.text.length >= 2
                                        ? 'Nenhum resultado encontrado'
                                        : 'Digite pelo menos 2 caracteres para buscar',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    final item = searchResults[index]
                                        as Map<String, dynamic>;
                                    final code = item['code'];
                                    final name = item['name'] ?? '';

                                    return ListTile(
                                      leading: CircleAvatar(
                                        child: Icon(_getIconForType(title)),
                                        backgroundColor: Colors.blue[100],
                                      ),
                                      title: Text(name),
                                      subtitle: Text('Código: $code'),
                                      onTap: () {
                                        onSelected(item as T);
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getIconForType(String title) {
    switch (title) {
      case 'Buscar Médico':
        return Icons.local_hospital;
      case 'Buscar Hospital':
        return Icons.business;
      case 'Buscar Convênio':
        return Icons.credit_card;
      case 'Buscar Cirurgia':
        return Icons.healing;
      default:
        return Icons.search;
    }
  }

  Future<void> _saveAgendamento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar se todas as entidades obrigatórias foram selecionadas
    if (_codpac == null || _selectedPacienteName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um paciente')),
      );
      return;
    }

    if (_codmed == null || _selectedMedicoName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um médico')),
      );
      return;
    }

    if (_codcli == null || _selectedHospitalName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um hospital')),
      );
      return;
    }

    if (_codconv == null || _selectedConvenioName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um convênio')),
      );
      return;
    }

    if (_selectedCirurgiaName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma cirurgia')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final horcir = _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
          : '08:00:00';

      if (_isEditing) {
        await _service.updateAgendamento(
          nummov: widget.agendamento!.nummov,
          nomcir: _nomeCirurgiaController.text.trim(),
          datcir: _selectedDate!,
          horcir: horcir,
          lado: _ladoController.text.trim(),
          primrev: _selectedPrimariaRevisao,
          agendaCancelada: _selectedAgendaCancelada,
          solicitou: _solicitanteController.text.trim(),
          cirurgiaUrgencia: _selectedCirurgiaUrgencia,
          matcir: _materialCirurgiaController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Agendamento atualizado com sucesso!')),
          );
        }
      } else {
        // Para novos agendamentos, usar as entidades selecionadas
        await _service.createAgendamento(
          codpac: _codpac!, // Obrigatório e já validado
          nompac: _selectedPacienteName!,
          codcli: _codcli!, // Obrigatório e já validado
          nomcli: _selectedHospitalName!,
          codmed: _codmed!, // Obrigatório e já validado
          nommed: _selectedMedicoName!,
          codconv: _codconv!, // Obrigatório e já validado
          nomconv: _selectedConvenioName!,
          nomcir: _nomeCirurgiaController.text.trim(),
          datcir: _selectedDate!,
          horcir: horcir,
          lado: _ladoController.text.trim(),
          primrev: _selectedPrimariaRevisao,
          agendaCancelada: _selectedAgendaCancelada,
          solicitou: _solicitanteController.text.trim(),
          cirurgiaUrgencia: _selectedCirurgiaUrgencia,
          matcir: _materialCirurgiaController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento criado com sucesso!')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar agendamento: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
