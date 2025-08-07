import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/paciente_service_paginado.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Consulta Paciente',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                _buildInfoField('Código', widget.paciente.id.toString(), false),
                _buildInfoField('Nome', widget.paciente.name, true),
                _buildInfoField('Data de Nascimento',
                    _formatDate(widget.paciente.birthDate), true),
              ],
            ),
          ),
          // Rodapé igual à imagem
          Container(
            width: double.infinity,
            height: 60,
            color: AppColors.lightBlue,
            child: Row(
              children: [
                // Botão EXCLUIR
                Expanded(
                  child: InkWell(
                    onTap: () => _showDeleteConfirmation(),
                    child: Container(
                      color: Colors.transparent,
                      child: const Row(
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
                // Linha divisória
                Container(
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                // Botão EDITAR
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Funcionalidade de editar
                      _showSuccessSnackBar(
                          'Funcionalidade de editar será implementada em breve.');
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
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Valor
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: isEditable ? FontWeight.normal : FontWeight.w500,
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

  String _formatDate(String date) {
    if (date.isEmpty || date == 'null' || date == 'Data não disponível') {
      return 'Data não disponível';
    }

    try {
      // Remove possíveis espaços e caracteres extras
      final cleanDate = date.trim();

      // Se contém 'T', é formato ISO (2023-12-25T00:00:00)
      if (cleanDate.contains('T')) {
        final parts = cleanDate.split('T').first.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }

      // Se é formato simples (2023-12-25)
      if (cleanDate.contains('-')) {
        final parts = cleanDate.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }

      // Se já está no formato brasileiro (25/12/2023)
      if (cleanDate.contains('/')) {
        return cleanDate;
      }

      return cleanDate;
    } catch (e) {
      return 'Data inválida';
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o paciente "${widget.paciente.name}"?',
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Editar Paciente',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Editar Dados Pessoais'),
                onTap: () {
                  Navigator.of(context).pop();
                  _editPersonalData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Editar Endereço'),
                onTap: () {
                  Navigator.of(context).pop();
                  _editAddress();
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Editar Contatos'),
                onTap: () {
                  Navigator.of(context).pop();
                  _editContacts();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deletePaciente() {
    // Implementar lógica de exclusão
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paciente excluído com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

  void _editPersonalData() {
    // Implementar navegação para edição de dados pessoais
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Editar dados pessoais...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editAddress() {
    // Implementar navegação para edição de endereço
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Editar endereço...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editContacts() {
    // Implementar navegação para edição de contatos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Editar contatos...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
