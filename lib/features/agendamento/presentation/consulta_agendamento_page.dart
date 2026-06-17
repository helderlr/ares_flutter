import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../login/services/auth_service.dart';
import '../models/agendamento_model.dart';
import '../services/agendamento_service.dart';
import '../widgets/agenda_status_legend.dart';
import 'agendamento_form_page.dart';

class ConsultaAgendamentoPage extends StatefulWidget {
  final AgendaCirurgia agendamento;

  const ConsultaAgendamentoPage({Key? key, required this.agendamento})
      : super(key: key);

  @override
  State<ConsultaAgendamentoPage> createState() =>
      _ConsultaAgendamentoPageState();
}

class _ConsultaAgendamentoPageState extends State<ConsultaAgendamentoPage> {
  final AgendamentoService _service = AgendamentoService();
  late AgendaCirurgia _currentAgendamento;
  bool _isLoading = false;
  bool _canEdit = false;
  bool _isReady = false;
  final TextEditingController _motivoCancelamentoController =
      TextEditingController();

  Future<void> _showCancelamentoDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Cirurgia'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Por favor, informe o motivo do cancelamento:'),
                const SizedBox(height: 16),
                TextField(
                  controller: _motivoCancelamentoController,
                  decoration: const InputDecoration(
                    hintText: 'Digite o motivo do cancelamento',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
                _motivoCancelamentoController.clear();
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                if (_motivoCancelamentoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Por favor, informe o motivo do cancelamento'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _cancelarCirurgia();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelarCirurgia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final motivo = _motivoCancelamentoController.text.trim();
      await _service.cancelarAgendamento(
        _currentAgendamento.id,
        motivo,
        DateTime.now(),
      );

      _motivoCancelamentoController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cirurgia cancelada com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retorna true para atualizar a lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar cirurgia: ${e.toString()}'),
            backgroundColor: Colors.red,
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
  void dispose() {
    _motivoCancelamentoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentAgendamento = widget.agendamento;
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final int? loggedCodusu = await AuthService.getCurrentCodusu();
    if (!mounted) {
      return;
    }
    setState(() {
      _canEdit = _currentAgendamento.canEditByUser(loggedCodusu);
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          tooltip: 'Voltar',
        ),
        actions: [],
      ),
      body: !_isReady || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: _buildDetailFields(),
                  ),
                ),
                if (_canEdit)
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _showDeleteConfirmation,
                            child: Container(
                              color: Colors.lightBlue,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete, color: Colors.white),
                                  Text(
                                    'EXCLUIR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _editAgendamento,
                            child: Container(
                              color: Colors.lightBlue,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit, color: Colors.white),
                                  Text(
                                    'EDITAR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _showCancelamentoDialog,
                            child: Container(
                              color: Colors.lightBlue,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel_outlined,
                                      color: Colors.white),
                                  Text(
                                    'CANCELAR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
                SizedBox(
                  height: 50,
                  child: InkWell(
                    onTap: () => AgendaStatusLegend.showLegendDialog(context),
                    child: Container(
                      width: double.infinity,
                      color: Colors.lightBlue.shade700,
                      alignment: Alignment.center,
                      child: const Text(
                        'Legenda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildDetailFields() {
    final AgendaCirurgia agendamento = _currentAgendamento;
    final Color statusColor =
        AgendaStatusLegend.colorForAgenda(agendamento);
    final List<Widget> fields = <Widget>[
      _buildStatusHeader(agendamento.visualStatusLabel, statusColor),
      _buildInfoField('No Agenda', agendamento.nummov.toString(), false),
      _buildInfoField('Paciente', agendamento.pacienteName, true),
      _buildInfoField('Médico', agendamento.medicoName, true),
      _buildInfoField('Hospital/Clínica', agendamento.hospitalName, true),
      _buildInfoField('Convênio', agendamento.convenioName, true),
      _buildInfoField(
        'Tipo Cirurgia',
        agendamento.nomcirTipo ?? agendamento.codcir?.toString() ?? 'Não informado',
        true,
      ),
      _buildInfoField('Descrição Cirurgia', agendamento.cirurgiaName, true),
      _buildInfoField('Data Cirurgia', agendamento.dataCirurgia, true),
      _buildInfoField('Hora Cirurgia', agendamento.horaCirurgia, true),
      _buildInfoField('Data Emissão', agendamento.dataEmissao, true),
      _buildInfoField('Hora Emissão', agendamento.horaEmissao, true),
      _buildInfoField(
        'Primária/Revisão',
        _getPrimariaRevisaoDescription(agendamento.primrev),
        true,
      ),
      _buildInfoField(
        'Agenda Cancelada',
        _getSimNaoDescription(agendamento.agendaCancelada),
        true,
      ),
      _buildInfoField(
        'Cirurgia Urgência',
        _getSimNaoDescription(agendamento.cirurgiaUrgencia),
        true,
      ),
      _buildInfoField('Solicitante', agendamento.solicitanteName, true),
      _buildInfoField(
        'Lado',
        agendamento.lado != null && agendamento.lado!.isNotEmpty
            ? _getLadoDescription(agendamento.lado!)
            : 'Não informado',
        true,
      ),
      _buildInfoField('Material Cirurgia', agendamento.materialCirurgia, true),
      _buildSituacaoField(agendamento, statusColor),
      _buildInfoField('Vendedor', agendamento.vendedorName, true),
      _buildInfoField(
        'Data Cirurgia Original',
        agendamento.dataCirurgiaOriginal,
        true,
      ),
      _buildInfoField('Data Saída Material', agendamento.dataSaidaMaterial, true),
      _buildInfoField('Hora Saída Material', agendamento.horaSaidaMaterial, true),
      _buildInfoField('Instrumentador', agendamento.instrumentadorName, true),
      _buildInfoField('Nº Requisição', agendamento.numeroRequisicao, false),
      _buildInfoField('Nº Pedido', agendamento.numeroPedidoTexto, false),
      _buildInfoField(
        'Observações',
        agendamento.obsage?.trim().isNotEmpty == true
            ? agendamento.obsage!.trim()
            : 'Não informado',
        true,
      ),
    ];
    if (agendamento.agendaCancelada?.toUpperCase() == 'S') {
      fields.addAll(<Widget>[
        _buildInfoField(
          'Data Cancelamento',
          agendamento.dataCancelamentoFormatada,
          true,
        ),
        _buildInfoField(
          'Hora Cancelamento',
          agendamento.horaCancelamentoFormatada,
          true,
        ),
        _buildInfoField(
          'Motivo Cancelamento',
          agendamento.motivoCancelamentoTexto,
          true,
        ),
      ]);
    }
    return fields;
  }

  Widget _buildStatusHeader(String label, Color ballColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          AgendaStatusLegend.buildBall(ballColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTheme.consultaLabelStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSituacaoField(AgendaCirurgia agendamento, Color ballColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Situação',
            style: AppTheme.consultaLabelStyle,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                AgendaStatusLegend.buildBall(ballColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    agendamento.visualStatusLabel,
                    style: AppTheme.consultaValueStyle(),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value, bool isEditable,
      {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.consultaLabelStyle),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              value,
              style: AppTheme.consultaValueStyle(
                isEditable: isEditable,
                valueColor: valueColor,
              ),
            ),
          ),
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ],
      ),
    );
  }

  String _getLadoDescription(String lado) {
    switch (lado.toUpperCase()) {
      case 'D':
        return 'Direito';
      case 'E':
        return 'Esquerdo';
      case 'B':
        return 'Bilateral';
      default:
        return lado;
    }
  }

  String _getPrimariaRevisaoDescription(String? primrev) {
    if (primrev == null || primrev.isEmpty) return 'Não informado';
    switch (primrev.toUpperCase()) {
      case 'P':
        return 'Primária';
      case 'R':
        return 'Revisão';
      default:
        return primrev;
    }
  }

  String _getSimNaoDescription(String? valor) {
    if (valor == null || valor.isEmpty) return 'Não informado';
    switch (valor.toUpperCase()) {
      case 'S':
        return 'Sim';
      case 'N':
        return 'Não';
      default:
        return valor;
    }
  }

  void _editAgendamento() async {
    if (!_canEdit) {
      return;
    }
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AgendamentoFormPage(agendamento: _currentAgendamento),
      ),
    );

    if (result == true) {
      // Agendamento foi atualizado, voltar para a lista
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o agendamento de ${_currentAgendamento.pacienteName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAgendamento();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAgendamento() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success =
          await _service.deleteAgendamento(_currentAgendamento.nummov);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Voltar para a lista de agendamentos
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir agendamento: $e'),
            backgroundColor: Colors.red,
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
}
