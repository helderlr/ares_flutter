import 'package:flutter/material.dart';
import '../../../core/permissions/user_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/consulta_action_bar.dart';
import '../../login/services/auth_service.dart';
import '../models/medico_model.dart';
import '../services/medico_service.dart';
import '../services/medico_service_paginado.dart';
import 'medico_form_page.dart';

class ConsultaMedicoPage extends StatefulWidget {
  final Medico medico;

  const ConsultaMedicoPage({
    super.key,
    required this.medico,
  });

  @override
  State<ConsultaMedicoPage> createState() => _ConsultaMedicoPageState();
}

class _ConsultaMedicoPageState extends State<ConsultaMedicoPage> {
  late Medico _currentMedico;
  final MedicoServicePaginado _medicoQueryService = MedicoServicePaginado();
  final MedicoService _medicoService = MedicoService();
  bool _isLoading = false;
  bool _canEdit = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _currentMedico = widget.medico;
    _loadMedicoDetails();
  }

  Future<void> _loadPermissions() async {
    final UserPermissions permissions = await AuthService.getUserPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _canEdit = _currentMedico.canEditByUser(
        permissions.codusu,
        isAdmin: permissions.isAdmin,
        isUserActive: permissions.isActive,
      );
      _isReady = true;
    });
  }

  Future<void> _loadMedicoDetails() async {
    try {
      final Medico? medico =
          await _medicoQueryService.getMedicoById(_currentMedico.codmed);
      if (!mounted) {
        return;
      }
      if (medico != null) {
        setState(() {
          _currentMedico = medico;
        });
      }
      await _loadPermissions();
    } catch (_) {
      await _loadPermissions();
    }
  }

  Future<void> _deleteMedico() async {
    // Mostrar diálogo de confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Tem certeza que deseja excluir o médico "${_currentMedico.name}"?'),
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

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      print('🗑️ Excluindo médico: ${_currentMedico.name}');
      await _medicoService.deleteMedico(_currentMedico.codmed);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Médico excluído com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true); // Retorna true para indicar alteração
      }
    } catch (e) {
      print('❌ Erro ao excluir médico: $e');

      if (mounted) {
        String errorMessage = 'Erro ao excluir médico';

        if (e.toString().contains('Token')) {
          errorMessage = 'Sessão expirada. Faça login novamente.';
        } else if (e.toString().contains('não encontrado')) {
          errorMessage = 'Médico não encontrado.';
        } else if (e.toString().contains('relacionamentos')) {
          errorMessage =
              'Não é possível excluir este médico. Existem consultas ou outros registros relacionados.';
        } else if (e.toString().contains('conexão')) {
          errorMessage = 'Erro de conexão. Verifique sua internet.';
        } else if (e.toString().contains('servidor')) {
          errorMessage = 'Erro do servidor. Tente novamente mais tarde.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta Médico'),
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
      body: Column(
        children: [
          // Lista de campos (sem título)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildInfoField(
                    'Código', _currentMedico.codmed.toString(), false),
                _buildInfoField(
                    'Nome', _currentMedico.nommed.toUpperCase(), true),
                _buildInfoField('CRM', _currentMedico.crmNumber, true),
                _buildInfoField(
                    'Especialidade', _currentMedico.specialty, true),
              ],
            ),
          ),
          if (_canEdit)
            ConsultaActionBar(
              items: <ConsultaActionItem>[
                ConsultaActionItem(
                  icon: Icons.edit_outlined,
                  label: 'Editar',
                  onTap: () async {
                    final bool? result =
                        await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) =>
                            MedicoFormPage(medico: _currentMedico),
                      ),
                    );
                    if (result == true && mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
                ConsultaActionItem(
                  icon: Icons.delete_outline,
                  label: _isLoading ? 'Excluindo...' : 'Excluir',
                  isLoading: _isLoading,
                  onTap: _deleteMedico,
                ),
              ],
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              value,
              style: AppTheme.consultaValueStyle(isEditable: isEditable),
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
}
