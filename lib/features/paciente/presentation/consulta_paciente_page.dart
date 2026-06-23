import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../login/services/auth_service.dart';
import '../../../core/permissions/user_permissions.dart';
import '../services/paciente_service.dart';
import '../services/paciente_service_paginado.dart';
import 'paciente_form_page.dart';

class ConsultaPacientePage extends StatefulWidget {
  final Patient paciente;

  const ConsultaPacientePage({
    super.key,
    required this.paciente,
  });

  @override
  State<ConsultaPacientePage> createState() => _ConsultaPacientePageState();
}

class _ConsultaPacientePageState extends State<ConsultaPacientePage> {
  late Patient _currentPaciente;
  final PacienteService _pacienteService = PacienteService();
  bool _isLoading = false;
  bool _canEdit = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _currentPaciente = widget.paciente;
    _loadPacienteDetails();
  }

  Future<void> _loadPermissions() async {
    final UserPermissions permissions = await AuthService.getUserPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _canEdit = _currentPaciente.canEditByUser(
        permissions.codusu,
        isAdmin: permissions.isAdmin,
        isUserActive: permissions.isActive,
      );
      _isReady = true;
    });
  }

  Future<void> _loadPacienteDetails() async {
    try {
      final Map<String, dynamic>? data =
          await _pacienteService.getPacienteById(_currentPaciente.codpac);
      if (!mounted) {
        return;
      }
      if (data != null) {
        final dynamic payload = data['data'] ?? data;
        if (payload is Map<String, dynamic>) {
          setState(() {
            _currentPaciente = Patient.fromJson(payload);
          });
        }
      }
      await _loadPermissions();
    } catch (_) {
      await _loadPermissions();
    }
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
        title: const Text('Consulta Paciente'),
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildInfoField(
                  'Código',
                  _currentPaciente.id.toString(),
                  false,
                ),
                _buildInfoField('Nome', _currentPaciente.name, true),
                _buildInfoField(
                  'Data de Nascimento',
                  _formatDate(_currentPaciente.birthDate),
                  true,
                ),
              ],
            ),
          ),
          if (_canEdit)
            Container(
              width: double.infinity,
              height: 60,
              color: AppColors.lightBlue,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : _showDeleteConfirmation,
                      child: Container(
                        color: Colors.transparent,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'EXCLUIR',
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
                            builder: (context) => PacienteFormPage(
                              paciente: _currentPaciente,
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
                            Icon(Icons.edit, color: Colors.white, size: 24),
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
          Text(label, style: AppTheme.consultaLabelStyle),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.consultaValueStyle(isEditable: isEditable),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, height: 1),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty || date == 'null' || date == 'Data não disponível') {
      return 'Data não disponível';
    }
    try {
      final String cleanDate = date.trim();
      if (cleanDate.contains('T')) {
        final List<String> parts = cleanDate.split('T').first.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }
      if (cleanDate.contains('-')) {
        final List<String> parts = cleanDate.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }
      if (cleanDate.contains('/')) {
        return cleanDate;
      }
      return cleanDate;
    } catch (_) {
      return 'Data inválida';
    }
  }

  void _showDeleteConfirmation() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o paciente "${_currentPaciente.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePaciente();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePaciente() async {
    setState(() => _isLoading = true);
    try {
      await _pacienteService.deletePaciente(_currentPaciente.codpac);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente excluído com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
