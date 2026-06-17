import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../services/convenio_service.dart';
import '../models/convenio_model.dart';

class ConvenioFormPage extends StatefulWidget {
  final Convenio? convenio;

  const ConvenioFormPage({super.key, this.convenio});

  @override
  State<ConvenioFormPage> createState() => _ConvenioFormPageState();
}

class _ConvenioFormPageState extends State<ConvenioFormPage> {
  final ConvenioService _convenioService = ConvenioService();
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _telefoneController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.convenio != null;
    if (_isEditing) {
      _nomeController.text = widget.convenio!.nomcon.toUpperCase();
      _cnpjController.text = widget.convenio!.cnpjcon ?? '';
      _enderecoController.text = widget.convenio!.endcon ?? '';
      _telefoneController.text = widget.convenio!.fonecon ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _saveConvenio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nome = _nomeController.text.trim();
      final cnpj = _cnpjController.text.trim();
      final endereco = _enderecoController.text.trim();
      final telefone = _telefoneController.text.trim();

      if (widget.convenio != null) {
        // Atualizar convênio existente
        await _convenioService.updateConvenio(
          codcon: widget.convenio!.codcon,
          nome: nome,
          cnpj: cnpj.isNotEmpty ? cnpj : null,
          endereco: endereco.isNotEmpty ? endereco : null,
          telefone: telefone.isNotEmpty ? telefone : null,
        );

        _showSuccessSnackBar('Convênio atualizado com sucesso!');
      } else {
        // Criar novo convênio
        final result = await _convenioService.createConvenio(
          nome: nome,
          cnpj: cnpj.isNotEmpty ? cnpj : null,
          endereco: endereco.isNotEmpty ? endereco : null,
          telefone: telefone.isNotEmpty ? telefone : null,
        );

        print('✅ Resultado da criação: $result');
        _showSuccessSnackBar('Convênio criado com sucesso!');
      }

      // Retorna true para indicar que houve mudança
      Navigator.of(context).pop(true);
    } catch (e) {
      print('❌ Erro ao salvar convênio: $e');
      _showErrorSnackBar('Erro ao salvar convênio: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Convênio' : 'Novo Convênio'),
        backgroundColor: AppColors.lightBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildInputField(
                          'Nome', _nomeController, true, Icons.assignment),
                      const SizedBox(height: 16),
                      _buildInputField('CNPJ (opcional)', _cnpjController,
                          false, Icons.business),
                      const SizedBox(height: 16),
                      _buildInputField('Endereço (opcional)',
                          _enderecoController, false, Icons.location_on),
                      const SizedBox(height: 16),
                      _buildInputField('Telefone (opcional)',
                          _telefoneController, false, Icons.phone),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Botão de salvar
              ElevatedButton(
                onPressed: _isLoading ? null : _saveConvenio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Atualizar' : 'Salvar',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      bool isRequired, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            UpperCaseTextFormatter(),
          ],
          decoration: InputDecoration(
            hintText: _getHintText(label),
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: AppColors.lightBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.lightBlue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo é obrigatório';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  String _getHintText(String label) {
    if (label.contains('Nome')) {
      return 'Digite o nome do convênio';
    } else if (label.contains('CNPJ')) {
      return 'Digite o CNPJ do convênio';
    } else if (label.contains('Endereço')) {
      return 'Digite o endereço do convênio';
    } else if (label.contains('Telefone')) {
      return 'Digite o telefone do convênio';
    }
    return 'Digite $label';
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}





























