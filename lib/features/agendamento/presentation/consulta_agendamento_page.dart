import 'package:flutter/material.dart';
import '../../../core/widgets/protected_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../../login/services/auth_service.dart';
import '../../../core/permissions/user_permissions.dart';
import '../models/agendamento_model.dart';
import '../services/agendamento_service.dart';
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
  AgendaAccess _access = const AgendaAccess(
    canCopy: false,
    canEdit: false,
    canCancel: false,
    canDelete: false,
  );
  bool _isReady = false;
  final TextEditingController _motivoCancelamentoController =
      TextEditingController();

  Future<void> _showCancelamentoDialog() async {
    return showProtectedDialog<void>(
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
        _currentAgendamento.nummov,
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
    final UserPermissions permissions = await AuthService.getUserPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _access = _currentAgendamento.evaluateAccess(permissions);
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
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        bottom: _access.hasAnyAction && _isReady ? _buildTopActionBar() : null,
      ),
      body: !_isReady || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ..._buildAlertBanners(),
                ..._buildDetailFields(),
              ],
            ),
    );
  }

  List<Widget> _buildAlertBanners() {
    final List<Widget> banners = <Widget>[];
    if (_access.otherUserMessage != null) {
      banners.add(_buildAlertBanner(
        _access.otherUserMessage!,
        Colors.orange.shade50,
        Colors.orange.shade800,
        Icons.person_outline,
      ));
    }
    if (_access.situacaoBlockReason != null) {
      banners.add(_buildAlertBanner(
        _access.situacaoBlockReason!,
        Colors.red.shade50,
        Colors.red.shade800,
        Icons.info_outline,
      ));
    }
    if (banners.isEmpty) {
      return banners;
    }
    banners.add(const SizedBox(height: 8));
    return banners;
  }

  Widget _buildAlertBanner(
    String message,
    Color backgroundColor,
    Color textColor,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopActionBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        color: Colors.lightBlue.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (_access.canCopy)
              _buildTopActionItem(
                icon: Icons.content_copy_outlined,
                label: 'Copiar',
                onTap: _copiarAgendamento,
              ),
            if (_access.canCancel)
              _buildTopActionItem(
                icon: Icons.cancel_outlined,
                label: 'Cancelar',
                onTap: _showCancelamentoDialog,
              ),
            if (_access.canEdit)
              _buildTopActionItem(
                icon: Icons.edit_outlined,
                label: 'Editar',
                onTap: _editAgendamento,
              ),
            if (_access.canDelete)
              _buildTopActionItem(
                icon: Icons.delete_outline,
                label: 'Excluir',
                onTap: _showDeleteConfirmation,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copiarAgendamento() async {
    if (!_access.canCopy) {
      return;
    }
    final dynamic result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => AgendamentoFormPage(
          copyFrom: _currentAgendamento,
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  List<Widget> _buildDetailFields() {
    final AgendaCirurgia agendamento = _currentAgendamento;
    return <Widget>[
      _buildInfoField('No Agenda', agendamento.nummov.toString(), false),
      _buildInfoField('Paciente', _textOrEmpty(agendamento.nompac), true),
      _buildInfoField('Médico', _textOrEmpty(agendamento.nommed), true),
      _buildInfoField('Hospital/Clínica', _textOrEmpty(agendamento.nomcli), true),
      _buildInfoField('Convênio', _textOrEmpty(agendamento.nomconv), true),
      _buildInfoField(
        'Tipo Cirurgia',
        _textOrEmpty(agendamento.nomcirTipo),
        true,
      ),
      _buildInfoField(
        'Descrição Cirurgia',
        _textOrEmpty(agendamento.nomcir),
        true,
      ),
      _buildInfoField(
        'Data Cirurgia',
        _formatDate(agendamento.datcir),
        true,
      ),
      _buildInfoField('Hora Cirurgia', _textOrEmpty(agendamento.horcir), true),
      _buildInfoField(
        'Data Lançamento',
        _formatDate(agendamento.datlan),
        true,
      ),
      _buildInfoField('Hora Lancto', _textOrEmpty(agendamento.horlan), true),
      _buildInfoField(
        'Digitado por',
        _textOrEmpty(agendamento.nomusu),
        true,
      ),
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
      _buildInfoField(
        'Solicitante',
        _textOrEmpty(agendamento.solicitou),
        true,
      ),
      _buildInfoField(
        'Lado',
        agendamento.lado != null && agendamento.lado!.trim().isNotEmpty
            ? _getLadoDescription(agendamento.lado!)
            : '',
        true,
      ),
      _buildInfoField('Material Cirurgia', _textOrEmpty(agendamento.matcir), true),
      _buildInfoField(
        'Situação',
        agendamento.situacaoDisplayLabel,
        false,
      ),
      _buildInfoField('Vendedor', _textOrEmpty(agendamento.nomven), true),
      _buildInfoField(
        'Data Cirurgia Original',
        _formatDate(agendamento.datcirOriginal),
        true,
      ),
      _buildInfoField(
        'Data Saída Material',
        _formatDate(agendamento.datsai),
        true,
      ),
      _buildInfoField('Hora Saída Material', _textOrEmpty(agendamento.horsai), true),
      _buildInfoField(
        'Instrumentador',
        _textOrEmpty(agendamento.nominstru1),
        true,
      ),
      _buildInfoField(
        'Nº Requisição',
        agendamento.numreq?.toString() ?? '',
        false,
      ),
      _buildInfoField(
        'No Rel Cirurgia',
        agendamento.nrelcir?.toString() ?? '',
        false,
      ),
      _buildInfoField(
        'Nº Pedido',
        _textOrEmpty(agendamento.numeroPedido) != ''
            ? _textOrEmpty(agendamento.numeroPedido)
            : (agendamento.numpedv?.toString() ?? ''),
        false,
      ),
      _buildInfoField(
        'Data Cancelamento',
        _formatDate(agendamento.dataCancelamento),
        true,
      ),
      _buildInfoField(
        'Hora Cancelamento',
        _textOrEmpty(agendamento.horaCancelamento),
        true,
      ),
      _buildInfoField(
        'Motivo Cancelamento',
        _textOrEmpty(agendamento.motivoCancelamento),
        true,
      ),
    ];
  }

  String _textOrEmpty(String? value) {
    if (value == null) {
      return '';
    }
    return value.trim();
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
    if (primrev == null || primrev.trim().isEmpty) {
      return '';
    }
    switch (primrev.toUpperCase()) {
      case 'P':
        return 'Primária';
      case 'R':
        return 'Revisão';
      default:
        return primrev.trim();
    }
  }

  String _getSimNaoDescription(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return '';
    }
    switch (valor.toUpperCase()) {
      case 'S':
        return 'Sim';
      case 'N':
        return 'Não';
      default:
        return valor.trim();
    }
  }

  void _editAgendamento() async {
    if (!_access.canEdit) {
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
    showProtectedDialog(
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
