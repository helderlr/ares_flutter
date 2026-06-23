import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../login/services/auth_service.dart';
import '../../../core/permissions/user_permissions.dart';
import '../services/convenio_service.dart';
import '../models/convenio_model.dart';
import 'convenio_form_page.dart';

class ConsultaConvenioPage extends StatefulWidget {
  final Convenio convenio;

  const ConsultaConvenioPage({super.key, required this.convenio});

  @override
  State<ConsultaConvenioPage> createState() => _ConsultaConvenioPageState();
}

class _ConsultaConvenioPageState extends State<ConsultaConvenioPage> {
  final ConvenioService _convenioService = ConvenioService();
  late Convenio _currentConvenio;
  bool _isLoading = false;
  bool _canEdit = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _currentConvenio = widget.convenio;
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final UserPermissions permissions = await AuthService.getUserPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _canEdit = _currentConvenio.canEditByUser(
        permissions.codusu,
        isAdmin: permissions.isAdmin,
        isUserActive: permissions.isActive,
      );
      _isReady = true;
    });
  }

  Future<void> _deleteConvenio() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Deseja realmente excluir o convênio "${_currentConvenio.name}"?'),
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
        await _convenioService.deleteConvenio(_currentConvenio.codcon);
        _showSuccessSnackBar('Convênio excluído com sucesso!');
        // Retorna true para indicar que houve mudança
        Navigator.of(context).pop(true);
      } catch (e) {
        print('❌ Erro ao excluir convênio: $e');
        _showErrorSnackBar('Erro ao excluir convênio: ${e.toString()}');
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
        title: const Text('Consulta Convênio'),
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
                    'Código', _currentConvenio.codcon.toString(), false),
                _buildInfoField(
                    'Nome', _currentConvenio.name.toUpperCase(), true),
                if (_currentConvenio.cnpj != 'CNPJ não disponível')
                  _buildInfoField('CNPJ', _currentConvenio.cnpj, true),
                if (_currentConvenio.address != 'Endereço não disponível')
                  _buildInfoField('Endereço', _currentConvenio.address, true),
                if (_currentConvenio.phone != 'Telefone não disponível')
                  _buildInfoField('Telefone', _currentConvenio.phone, true),
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
                      onTap: _isLoading ? null : () => _deleteConvenio(),
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
                            builder: (context) => ConvenioFormPage(
                              convenio: _currentConvenio,
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
