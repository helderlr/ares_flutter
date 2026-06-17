import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../login/services/auth_service.dart';
import '../services/tipo_cirurgia_service.dart';
import '../models/tipo_cirurgia_model.dart';
import 'tipo_cirurgia_form_page.dart';

class ConsultaTipoCirurgiaPage extends StatefulWidget {
  final TipoCirurgia tipoCirurgia;

  const ConsultaTipoCirurgiaPage({super.key, required this.tipoCirurgia});

  @override
  State<ConsultaTipoCirurgiaPage> createState() =>
      _ConsultaTipoCirurgiaPageState();
}

class _ConsultaTipoCirurgiaPageState extends State<ConsultaTipoCirurgiaPage> {
  final TipoCirurgiaService _tipoCirurgiaService = TipoCirurgiaService();
  late TipoCirurgia _currentTipoCirurgia;
  bool _isLoading = false;
  bool _canEdit = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _currentTipoCirurgia = widget.tipoCirurgia;
    _loadTipoCirurgiaDetails();
  }

  Future<void> _loadPermissions() async {
    final int? loggedCodusu = await AuthService.getCurrentCodusu();
    if (!mounted) {
      return;
    }
    setState(() {
      _canEdit = _currentTipoCirurgia.canEditByUser(loggedCodusu);
      _isReady = true;
    });
  }

  Future<void> _loadTipoCirurgiaDetails() async {
    try {
      final Map<String, dynamic>? data = await _tipoCirurgiaService
          .getTipoCirurgiaById(_currentTipoCirurgia.codcir);
      if (!mounted) {
        return;
      }
      if (data != null) {
        final dynamic payload = data['data'] ?? data;
        if (payload is Map<String, dynamic>) {
          setState(() {
            _currentTipoCirurgia = TipoCirurgia.fromJson(payload);
          });
        }
      }
      await _loadPermissions();
    } catch (_) {
      await _loadPermissions();
    }
  }

  Future<void> _deleteTipoCirurgia() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Deseja realmente excluir o tipo de cirurgia "${_currentTipoCirurgia.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await _tipoCirurgiaService
            .deleteTipoCirurgia(_currentTipoCirurgia.codcir);
        _showSuccessSnackBar('Tipo de cirurgia excluído com sucesso!');
        // Retorna true para indicar que houve mudança
        Navigator.of(context).pop(true);
      } catch (e) {
        print('❌ Erro ao excluir tipo de cirurgia: $e');
        _showErrorSnackBar('Erro ao excluir tipo de cirurgia: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
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
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Consulta Tipo Cirurgia'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de campos (sem título)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildInfoField(
                    'Código', _currentTipoCirurgia.codcir.toString(), false),
                _buildInfoField(
                    'Nome', _currentTipoCirurgia.name.toUpperCase(), true),
                if (_currentTipoCirurgia.description !=
                    'Descrição não disponível')
                  _buildInfoField(
                      'Descrição', _currentTipoCirurgia.description, true),
                if (_currentTipoCirurgia.value != 'Valor não disponível')
                  _buildInfoField('Valor', _currentTipoCirurgia.value, true),
              ],
            ),
          ),
          // Rodapé igual à imagem
          if (_canEdit)
            Container(
              width: double.infinity,
              height: 60,
              color: AppColors.lightBlue,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : () => _deleteTipoCirurgia(),
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 24,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _isLoading ? 'EXCLUINDO...' : 'EXCLUIR',
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
                  Container(
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final bool? result =
                            await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (context) => TipoCirurgiaFormPage(
                              tipoCirurgia: _currentTipoCirurgia,
                            ),
                          ),
                        );
                        if (result == true && mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'EDITAR',
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
    );
  }

  Widget _buildInfoField(String label, String value, bool isEditable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (título em negrito)
          Text(label, style: AppTheme.consultaLabelStyle),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.consultaValueStyle(isEditable: isEditable),
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
}





























