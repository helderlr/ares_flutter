import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/form_action_bar.dart';
import '../services/tipo_cirurgia_service.dart';
import '../models/tipo_cirurgia_model.dart';

class TipoCirurgiaFormPage extends StatefulWidget {
  final TipoCirurgia? tipoCirurgia;

  const TipoCirurgiaFormPage({super.key, this.tipoCirurgia});

  @override
  State<TipoCirurgiaFormPage> createState() => _TipoCirurgiaFormPageState();
}

class _TipoCirurgiaFormPageState extends State<TipoCirurgiaFormPage> {
  final TipoCirurgiaService _tipoCirurgiaService = TipoCirurgiaService();
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.tipoCirurgia != null;
    if (_isEditing) {
      _nomeController.text = widget.tipoCirurgia!.nomcir.toUpperCase();
      _descricaoController.text = widget.tipoCirurgia!.descir ?? '';
      if (widget.tipoCirurgia!.valcir != null) {
        _valorController.text = widget.tipoCirurgia!.valcir!.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _saveTipoCirurgia() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nome = _nomeController.text.trim();
      final descricao = _descricaoController.text.trim();
      final valorTexto = _valorController.text.trim();
      double? valor;

      if (valorTexto.isNotEmpty) {
        valor = double.tryParse(valorTexto.replaceAll(',', '.'));
        if (valor == null) {
          _showErrorSnackBar(
              'Valor inválido. Use apenas números com ponto ou vírgula para decimais.');
          return;
        }
      }

      if (widget.tipoCirurgia != null) {
        // Atualizar tipo de cirurgia existente
        await _tipoCirurgiaService.updateTipoCirurgia(
          codcir: widget.tipoCirurgia!.codcir,
          nome: nome,
          descricao: descricao.isNotEmpty ? descricao : null,
          valor: valor,
        );

        _showSuccessSnackBar('Tipo de cirurgia atualizado com sucesso!');
      } else {
        // Criar novo tipo de cirurgia
        final result = await _tipoCirurgiaService.createTipoCirurgia(
          nome: nome,
          descricao: descricao.isNotEmpty ? descricao : null,
          valor: valor,
        );

        print('✅ Resultado da criação: $result');
        _showSuccessSnackBar('Tipo de cirurgia criado com sucesso!');
      }

      // Retorna true para indicar que houve mudança
      Navigator.of(context).pop(true);
    } catch (e) {
      print('❌ Erro ao salvar tipo de cirurgia: $e');
      _showErrorSnackBar('Erro ao salvar tipo de cirurgia: ${e.toString()}');
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
        title: Text(_isEditing ? 'Editar Tipo Cirurgia' : 'Novo Tipo Cirurgia'),
        elevation: 0,
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: <Widget>[
                  _buildInputField(
                    'Nome',
                    _nomeController,
                    true,
                    Icons.healing,
                  ),
                  _buildInputField(
                    'Descrição (opcional)',
                    _descricaoController,
                    false,
                    Icons.description,
                  ),
                  _buildValueField(
                    'Valor (opcional)',
                    _valorController,
                    false,
                    Icons.attach_money,
                  ),
                ],
              ),
            ),
            FormActionBar(
              isLoading: _isLoading,
              isEditing: _isEditing,
              onCancel: () => Navigator.of(context).pop(),
              onSave: _saveTipoCirurgia,
            ),
          ],
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

  Widget _buildValueField(String label, TextEditingController controller,
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
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
      return 'Digite o nome do tipo de cirurgia';
    } else if (label.contains('Descrição')) {
      return 'Digite a descrição do tipo de cirurgia';
    } else if (label.contains('Valor')) {
      return 'Digite o valor do tipo de cirurgia (ex: 1250.50)';
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





























