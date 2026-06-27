import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../menu/model/menu_option.dart';
import '../../menu/presentation/menu_drawer.dart';

class RegistroHoraCirurgiaPage extends StatefulWidget {
  const RegistroHoraCirurgiaPage({super.key});

  @override
  State<RegistroHoraCirurgiaPage> createState() =>
      _RegistroHoraCirurgiaPageState();
}

class _RegistroHoraCirurgiaPageState extends State<RegistroHoraCirurgiaPage> {
  final List<Map<String, dynamic>> _registros = [
    {
      'id': 1,
      'paciente': 'João Silva',
      'cirurgia': 'Cirurgia Cardíaca',
      'dataCirurgia': '2025-01-15',
      'horaInicio': '08:00',
      'horaFim': '12:00',
      'duracao': '4h 00min',
      'status': 'Concluída',
    },
    {
      'id': 2,
      'paciente': 'Maria Santos',
      'cirurgia': 'Cirurgia Ortopédica',
      'dataCirurgia': '2025-01-15',
      'horaInicio': '14:00',
      'horaFim': '16:30',
      'duracao': '2h 30min',
      'status': 'Em Andamento',
    },
    {
      'id': 3,
      'paciente': 'Pedro Oliveira',
      'cirurgia': 'Cirurgia Neurológica',
      'dataCirurgia': '2025-01-16',
      'horaInicio': '09:00',
      'horaFim': '11:45',
      'duracao': '2h 45min',
      'status': 'Concluída',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Hora Cirurgia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
      ),
      drawer: MenuDrawer(
        userName: '',
        userPhone: '',
        atendimento: const <MenuOption>[],
        faturamento: const <MenuOption>[],
        estoque: const <MenuOption>[],
        footerOptions: const <MenuOption>[],
        onOptionTap: (MenuOption option) {},
      ),
      body: Column(
        children: [
          // Header com informações
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.lightBlue.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Controle de Tempo de Cirurgias',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightBlue,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Acompanhe o tempo de duração das cirurgias e registre os horários de início e fim.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),

          // Lista de registros
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _registros.length,
              itemBuilder: (context, index) {
                final registro = _registros[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 2.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                registro['paciente'],
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(registro['status'])
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: _getStatusColor(registro['status'])
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                registro['status'],
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(registro['status']),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          registro['cirurgia'],
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.calendar_today,
                                label: 'Data',
                                value: _formatDate(registro['dataCirurgia']),
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.access_time,
                                label: 'Início',
                                value: registro['horaInicio'],
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.schedule,
                                label: 'Fim',
                                value: registro['horaFim'],
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.timer,
                                label: 'Duração',
                                value: registro['duracao'],
                                isHighlight: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _editarRegistro(registro),
                              icon: const Icon(Icons.edit, size: 16.0),
                              label: const Text('Editar'),
                            ),
                            const SizedBox(width: 8.0),
                            TextButton.icon(
                              onPressed: () => _visualizarDetalhes(registro),
                              icon: const Icon(Icons.visibility, size: 16.0),
                              label: const Text('Detalhes'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarRegistro,
        backgroundColor: AppColors.lightBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16.0,
          color: isHighlight ? AppColors.lightBlue : Colors.grey[600],
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: isHighlight ? AppColors.lightBlue : Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Concluída':
        return Colors.green;
      case 'Em Andamento':
        return Colors.orange;
      case 'Cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return date;
  }

  void _editarRegistro(Map<String, dynamic> registro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Registro'),
        content:
            const Text('Funcionalidade de edição será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _visualizarDetalhes(Map<String, dynamic> registro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes - ${registro['paciente']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cirurgia: ${registro['cirurgia']}'),
            Text('Data: ${_formatDate(registro['dataCirurgia'])}'),
            Text('Horário: ${registro['horaInicio']} - ${registro['horaFim']}'),
            Text('Duração: ${registro['duracao']}'),
            Text('Status: ${registro['status']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _adicionarRegistro() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Registro'),
        content: const Text(
            'Funcionalidade de adicionar registro será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
