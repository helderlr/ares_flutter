import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../login/services/auth_service.dart';
import '../../../core/permissions/user_permissions.dart';
import '../models/hospital_model.dart';
import '../services/hospital_service.dart';
import 'hospital_form_page.dart';

class ConsultaHospitalPage extends StatefulWidget {
  final Hospital hospital;

  const ConsultaHospitalPage({
    super.key,
    required this.hospital,
  });

  @override
  State<ConsultaHospitalPage> createState() => _ConsultaHospitalPageState();
}

class _ConsultaHospitalPageState extends State<ConsultaHospitalPage> {
  late Hospital _currentHospital;
  final HospitalService _hospitalService = HospitalService();
  bool _isLoading = false;
  bool _canEdit = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _currentHospital = widget.hospital;
    _initializePage();
  }

  Future<void> _initializePage() async {
    if (!_currentHospital.isHospital) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro não é hospital/clínica (clihos ≠ S).'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    final UserPermissions permissions = await AuthService.getUserPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _canEdit = _currentHospital.canEditByUser(
        permissions.codusu,
        isAdmin: permissions.isAdmin,
        isUserActive: permissions.isActive,
      );
      _isReady = true;
    });
  }

  Future<void> _deleteHospital() async {
    // Mostrar diálogo de confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Tem certeza que deseja excluir o hospital "${_currentHospital.name}"?'),
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
      print('🗑️ Excluindo hospital: ${_currentHospital.name}');
      await _hospitalService.deleteHospital(_currentHospital.codcli);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hospital excluído com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true); // Retorna true para indicar alteração
      }
    } catch (e) {
      print('❌ Erro ao excluir hospital: $e');

      if (mounted) {
        String errorMessage = 'Erro ao excluir hospital';

        if (e.toString().contains('Token')) {
          errorMessage = 'Sessão expirada. Faça login novamente.';
        } else if (e.toString().contains('não encontrado')) {
          errorMessage = 'Hospital não encontrado.';
        } else if (e.toString().contains('relacionamentos')) {
          errorMessage =
              'Não é possível excluir este hospital. Existem consultas ou outros registros relacionados.';
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
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Consulta Hospital'),
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
          // Lista de campos (sem título)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildInfoField(
                    'Código', _currentHospital.codcli.toString(), false),
                _buildInfoField(
                    'Nome', _currentHospital.nomcli.toUpperCase(), true),
                _buildInfoField(
                    'Nome Fantasia', _currentHospital.fantasyName, true),
                _buildInfoField(
                    'Hospital', _currentHospital.hospitalSimNaoLabel, false),
                _buildInfoField('Endereço', _currentHospital.address, true),
                _buildInfoField(
                    'Número', _currentHospital.numeroFormatado, true),
                _buildInfoField(
                    'Bairro', _currentHospital.bairroFormatado, true),
                _buildInfoField(
                    'Cidade', _currentHospital.cidadeFormatada, true),
                _buildInfoField('CEP', _currentHospital.cepFormatado, true),
                _buildInfoField(
                    'Complemento', _currentHospital.complementoFormatado, true),
                _buildInfoField(
                    'Estado', _currentHospital.estadoFormatado, true),
                _buildInfoField('CNPJ', _currentHospital.cnpj, true),
                _buildInfoField('Telefone', _currentHospital.phone, true),
              ],
            ),
          ),
          // Rodapé igual à imagem
          // Botão do Mapa
          if (_currentHospital.address.isNotEmpty)
            InkWell(
              onTap: () async {
                final endereco =
                    '${_currentHospital.address}, ${_currentHospital.numeroFormatado}, ${_currentHospital.bairroFormatado}, ${_currentHospital.cidadeFormatada}, ${_currentHospital.estadoFormatado}'
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim();

                // Primeiro tenta abrir no app do Google Maps
                final mapsUrl = Uri.parse(
                    'google.navigation:q=${Uri.encodeComponent(endereco)}');

                try {
                  final mapsInstalled = await canLaunchUrl(mapsUrl);

                  if (mapsInstalled) {
                    await launchUrl(mapsUrl);
                  } else {
                    // Se não tiver o app, abre no navegador
                    final webUrl = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(endereco)}');
                    await launchUrl(webUrl, mode: LaunchMode.inAppWebView);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao abrir o Google Maps'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Container(
                width: double.infinity,
                height: 60,
                color: Colors.grey[200],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF4285F4), // Cor do Google Maps
                    size: 32,
                  ),
                ),
              ),
            ),
          // Botões de ação
          if (_canEdit)
            Container(
              width: double.infinity,
              height: 60,
              color: AppColors.lightBlue,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading
                          ? null
                          : () async {
                              final bool? result =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (context) => HospitalFormPage(
                                    hospital: _currentHospital,
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
                  Container(
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _isLoading ? null : _deleteHospital,
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
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'EXCLUINDO...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 24,
                                  ),
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
