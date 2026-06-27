import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/especialidade_model.dart';
import '../services/especialidade_service.dart';
import '../services/medico_service.dart';
import '../models/medico_model.dart';

class MedicoFormPage extends StatefulWidget {
  final Medico? medico;

  const MedicoFormPage({
    super.key,
    this.medico,
  });

  @override
  State<MedicoFormPage> createState() => _MedicoFormPageState();
}

class _MedicoFormPageState extends State<MedicoFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _crmController = TextEditingController();
  final MedicoService _medicoService = MedicoService();
  final EspecialidadeService _especialidadeService = EspecialidadeService();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isLoadingEspecialidades = true;
  String? _especialidadesError;
  List<Especialidade> _especialidades = <Especialidade>[];
  int? _selectedCodesp;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.medico != null;
    if (_isEditing) {
      _nomeController.text = widget.medico!.nommed.toUpperCase();
      _crmController.text = widget.medico!.crm ?? '';
      _selectedCodesp = widget.medico!.codesp;
    }
    _loadEspecialidades();
  }

  Future<void> _loadEspecialidades() async {
    setState(() {
      _isLoadingEspecialidades = true;
      _especialidadesError = null;
    });
    try {
      final List<Especialidade> items =
          await _especialidadeService.fetchEspecialidades();
      if (!mounted) {
        return;
      }
      setState(() {
        _especialidades = items;
        _isLoadingEspecialidades = false;
        if (_selectedCodesp != null &&
            !items.any((Especialidade item) => item.codesp == _selectedCodesp)) {
          final String? nomeAtual = widget.medico?.especialidade;
          if (nomeAtual != null && nomeAtual.isNotEmpty) {
            _especialidades = <Especialidade>[
              Especialidade(codesp: _selectedCodesp!, nome: nomeAtual),
              ...items,
            ];
          } else {
            _selectedCodesp = null;
          }
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingEspecialidades = false;
        _especialidadesError = error.toString().replaceAll('Exception: ', '');
      });
    }
  }

  List<Especialidade> get _especialidadesParaSelecao {
    return _especialidades;
  }

  String get _especialidadeSelecionadaLabel {
    if (_selectedCodesp == null) {
      return 'Selecione a especialidade';
    }
    for (final Especialidade item in _especialidadesParaSelecao) {
      if (item.codesp == _selectedCodesp) {
        return item.nome;
      }
    }
    return widget.medico?.especialidade ?? 'Código $_selectedCodesp';
  }

  Future<void> _showEspecialidadePicker() async {
    if (_isLoadingEspecialidades) {
      return;
    }
    if (_especialidadesParaSelecao.isEmpty) {
      if (_especialidadesError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nenhuma especialidade cadastrada para esta empresa.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    final int? selected = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Selecione a especialidade',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    ListTile(
                      title: const Text('Nenhuma'),
                      trailing: _selectedCodesp == null
                          ? const Icon(Icons.check, color: AppColors.lightBlue)
                          : null,
                      onTap: () => Navigator.of(context).pop(null),
                    ),
                    ..._especialidadesParaSelecao.map(
                      (Especialidade item) => ListTile(
                        title: Text(item.nome),
                        trailing: _selectedCodesp == item.codesp
                            ? const Icon(
                                Icons.check,
                                color: AppColors.lightBlue,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(item.codesp),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == _selectedCodesp) {
      return;
    }
    setState(() {
      _selectedCodesp = selected;
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _crmController.dispose();
    super.dispose();
  }

  Future<void> _saveMedico() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final String nome = _nomeController.text.trim();
      final String crm = _crmController.text.trim();
      if (nome.isEmpty) {
        throw Exception('Nome é obrigatório');
      }
      if (nome.length < 3) {
        throw Exception('Nome deve ter pelo menos 3 caracteres');
      }
      if (widget.medico != null) {
        await _medicoService.updateMedico(
          codmed: widget.medico!.codmed,
          nome: nome,
          crm: crm.isNotEmpty ? crm : null,
          codesp: _selectedCodesp,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Médico atualizado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        final Map<String, dynamic> result = await _medicoService.createMedico(
          nome: nome,
          crm: crm.isNotEmpty ? crm : null,
          codesp: _selectedCodesp,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString() ?? 'Médico criado com sucesso!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = 'Erro ao salvar médico';
        final String errorText = error.toString();
        if (errorText.contains('Token') || errorText.contains('Sessão')) {
          errorMessage = 'Sessão expirada. Faça login novamente.';
        } else if (errorText.contains('Dados inválidos')) {
          errorMessage = 'Dados inválidos. Verifique as informações.';
        } else if (errorText.contains('não encontrado')) {
          errorMessage = 'Médico não encontrado.';
        } else if (errorText.contains('conexão')) {
          errorMessage = 'Erro de conexão. Verifique sua internet.';
        } else if (errorText.contains('servidor')) {
          errorMessage = 'Erro do servidor. Tente novamente mais tarde.';
        } else {
          errorMessage = errorText.replaceAll('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Médico' : 'Novo Médico'),
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
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildInputField('Nome', _nomeController, true, Icons.person),
                  _buildInputField(
                    'CRM (opcional)',
                    _crmController,
                    false,
                    Icons.badge,
                  ),
                  _buildEspecialidadeField(),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: 60,
              color: AppColors.lightBlue,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : () => Navigator.pop(context),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                              'Cancelar',
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
                  Container(
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : _saveMedico,
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
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                    'Salvando...',
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
                                const Text(
                                  'Salvar',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEspecialidadeField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Especialidade (opcional)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingEspecialidades)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            )
          else
            InkWell(
              onTap: _showEspecialidadePicker,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _especialidadeSelecionadaLabel,
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedCodesp == null
                              ? Colors.grey.shade500
                              : Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  ],
                ),
              ),
            ),
          if (_especialidadesError != null) ...[
            const SizedBox(height: 8),
            Text(
              _especialidadesError!,
              style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
            ),
            TextButton(
              onPressed: _loadEspecialidades,
              child: const Text('Tentar novamente'),
            ),
          ] else if (!_isLoadingEspecialidades &&
              _especialidades.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Nenhuma especialidade cadastrada.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, height: 1),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    bool isRequired,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            textCapitalization: label.contains('Nome')
                ? TextCapitalization.characters
                : TextCapitalization.none,
            onChanged: label.contains('Nome')
                ? (String value) {
                    final int cursorPosition = controller.selection.start;
                    final String upperValue = value.toUpperCase();
                    if (value != upperValue) {
                      controller.value = TextEditingValue(
                        text: upperValue,
                        selection: TextSelection.collapsed(
                          offset: cursorPosition,
                        ),
                      );
                    }
                  }
                : null,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: _getHintText(label),
            ),
            validator: isRequired
                ? (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obrigatório';
                    }
                    if (label.contains('Nome') && value.trim().length < 3) {
                      return 'Nome deve ter pelo menos 3 caracteres';
                    }
                    return null;
                  }
                : null,
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, height: 1),
        ],
      ),
    );
  }

  String _getHintText(String label) {
    if (label.contains('Nome')) {
      return 'Digite o nome completo do médico';
    }
    if (label.contains('CRM')) {
      return 'Número do CRM';
    }
    return '';
  }
}
