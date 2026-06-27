import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../services/paciente_service.dart';
import '../services/paciente_service_paginado.dart';

class PacienteFormPage extends StatefulWidget {
  final Patient? paciente; // null = novo, não-null = edição

  const PacienteFormPage({
    super.key,
    this.paciente,
  });

  @override
  State<PacienteFormPage> createState() => _PacienteFormPageState();
}

class _PacienteFormPageState extends State<PacienteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _carteiraController = TextEditingController();

  final _pacienteService = PacienteService();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.paciente != null;

    if (_isEditing) {
      // Converter nome para caixa alta ao carregar
      _nomeController.text = widget.paciente!.nompac.toUpperCase();
      // Formatar data para dd/mm/yyyy se existir
      if (widget.paciente!.datnas != null &&
          widget.paciente!.datnas!.isNotEmpty) {
        try {
          final date = DateTime.parse(widget.paciente!.datnas!);
          _dataNascimentoController.text =
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        } catch (e) {
          _dataNascimentoController.text = widget.paciente!.datnas!;
        }
      }
      _carteiraController.text = widget.paciente!.carteira ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dataNascimentoController.dispose();
    _carteiraController.dispose();
    super.dispose();
  }

  Future<void> _savePaciente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nome = _nomeController.text.trim();
      final dataNascimento = _dataNascimentoController.text.trim();

      print('💾 Salvando paciente:');
      print('   Nome: $nome');
      print('   Data: $dataNascimento');
      print('   Carteira: ${_carteiraController.text.trim()}');

      // Validações adicionais antes de enviar
      if (nome.isEmpty) {
        throw Exception('Nome é obrigatório');
      }

      if (nome.length < 3) {
        throw Exception('Nome deve ter pelo menos 3 caracteres');
      }

      // Validar formato da data se fornecida
      if (dataNascimento.isNotEmpty) {
        final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
        if (!regex.hasMatch(dataNascimento)) {
          throw Exception('Formato de data inválido. Use dd/mm/aaaa');
        }

        try {
          final parts = dataNascimento.split('/');
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);

          if (day < 1 ||
              day > 31 ||
              month < 1 ||
              month > 12 ||
              year < 1900 ||
              year > DateTime.now().year) {
            throw Exception(
                'Data fora do intervalo válido (1900-${DateTime.now().year})');
          }

          final date = DateTime(year, month, day);
          if (date.year != year || date.month != month || date.day != day) {
            throw Exception('Data inválida');
          }

          if (date.isAfter(DateTime.now())) {
            throw Exception('Data não pode ser futura');
          }
        } catch (e) {
          if (e.toString().contains('Data')) {
            rethrow;
          }
          throw Exception('Data inválida');
        }
      }

      if (widget.paciente != null) {
        // Atualizando paciente existente
        await _pacienteService.updatePaciente(
          codpac: widget.paciente!.codpac,
          nome: nome,
          dataNascimento: dataNascimento.isNotEmpty ? dataNascimento : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paciente atualizado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Criando novo paciente
        final result = await _pacienteService.createPaciente(
          nome: nome,
          dataNascimento: dataNascimento.isNotEmpty ? dataNascimento : '',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Paciente criado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print('❌ Erro ao salvar paciente: $e');

      if (mounted) {
        String errorMessage = 'Erro ao salvar paciente';

        if (e.toString().contains('Token')) {
          errorMessage = 'Sessão expirada. Faça login novamente.';
        } else if (e.toString().contains('Dados inválidos')) {
          errorMessage = 'Dados inválidos. Verifique as informações.';
        } else if (e.toString().contains('não encontrado')) {
          errorMessage = 'Paciente não encontrado.';
        } else if (e.toString().contains('conexão')) {
          errorMessage = 'Erro de conexão. Verifique sua internet.';
        } else if (e.toString().contains('servidor')) {
          errorMessage = 'Erro do servidor. Tente novamente mais tarde.';
        } else if (e.toString().contains('Data')) {
          errorMessage =
              'Erro na data de nascimento: ${e.toString().replaceAll('Exception: ', '')}';
        } else if (e.toString().contains('Nome')) {
          errorMessage =
              'Erro no nome: ${e.toString().replaceAll('Exception: ', '')}';
        } else {
          errorMessage = 'Erro: ${e.toString().replaceAll('Exception: ', '')}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
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
        title: Text(_isEditing ? 'Editar Paciente' : 'Novo Paciente'),
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
            // Lista de campos (sem título)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildInputField('Nome', _nomeController, true, Icons.person),
                  _buildInputField('Data de Nascimento',
                      _dataNascimentoController, false, Icons.calendar_today),
                  _buildInputField('Carteira (opcional)', _carteiraController,
                      false, Icons.credit_card),
                ],
              ),
            ),
            // Rodapé igual à tela de consulta
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
                  ),
                  // Linha divisória
                  Container(
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  // Botão SALVAR
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : _savePaciente,
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
                                  Text(
                                    'Salvar',
                                    style: const TextStyle(
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
            // Configurar caixa alta apenas para o campo nome
            textCapitalization: label.contains('Nome')
                ? TextCapitalization.characters
                : TextCapitalization.none,
            // Converter para caixa alta em tempo real para o campo nome
            onChanged: label.contains('Nome')
                ? (value) {
                    // Manter cursor na posição correta
                    final cursorPosition = controller.selection.start;
                    final upperValue = value.toUpperCase();
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
              // Remover o ícone TT do campo nome
              prefixIcon: null,
            ),
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obrigatório';
                    }
                    if (label.contains('Nome') && value.trim().length < 3) {
                      return 'Nome deve ter pelo menos 3 caracteres';
                    }
                    if (label.contains('Data') && value.trim().isNotEmpty) {
                      // Valida formato dd/mm/aaaa
                      final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                      if (!regex.hasMatch(value)) {
                        return 'Formato inválido. Use dd/mm/aaaa';
                      }
                      // Valida se a data é válida
                      try {
                        final parts = value.split('/');
                        final day = int.parse(parts[0]);
                        final month = int.parse(parts[1]);
                        final year = int.parse(parts[2]);

                        // Verificar se os valores estão em ranges válidos
                        if (day < 1 ||
                            day > 31 ||
                            month < 1 ||
                            month > 12 ||
                            year < 1900 ||
                            year > DateTime.now().year) {
                          return 'Data fora do intervalo válido (1900-${DateTime.now().year})';
                        }

                        final date = DateTime(year, month, day);
                        if (date.year != year ||
                            date.month != month ||
                            date.day != day) {
                          return 'Data inválida';
                        }

                        // Verificar se não é uma data futura
                        if (date.isAfter(DateTime.now())) {
                          return 'Data não pode ser futura';
                        }
                      } catch (e) {
                        return 'Data inválida';
                      }
                    }
                    return null;
                  }
                : null,
            onTap: label.contains('Data')
                ? () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(
                          const Duration(days: 6570)), // 18 anos atrás
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.text =
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                    }
                  }
                : null,
            readOnly: label.contains('Data'),
            inputFormatters: label.contains('Data')
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                    LengthLimitingTextInputFormatter(10),
                  ]
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
    if (label.contains('Nome')) {
      return 'Digite o nome completo do paciente (será convertido para MAIÚSCULAS)';
    } else if (label.contains('Data')) {
      return 'dd/mm/aaaa';
    } else if (label.contains('Carteira')) {
      return 'Número da carteira ou documento';
    }
    return '';
  }
}
