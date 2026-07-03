import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/permissions/user_permissions.dart';
import '../../../core/services/screen_capture_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/protected_ui.dart';
import '../../../core/widgets/share_format_sheet.dart';
import '../../agendamento/services/agenda_relatorio_export_service.dart';
import '../../agendamento/services/empresa_report_service.dart';
import '../../login/models/user_model.dart';
import '../../login/services/auth_service.dart';
import '../models/relatorio_cirurgia_model.dart';
import '../services/relatorio_cirurgia_pdf_service.dart';
import '../services/relatorio_cirurgia_service.dart';
import '../utils/relatorio_field_labels.dart';
import '../../registro_hora_cirurgia/presentation/registro_hora_cirurgia_page.dart';
import 'relatorio_cirurgia_form_page.dart';

class ConsultaRelatorioCirurgiaPage extends StatefulWidget {
  final RelatorioCirurgia relatorio;

  const ConsultaRelatorioCirurgiaPage({
    super.key,
    required this.relatorio,
  });

  @override
  State<ConsultaRelatorioCirurgiaPage> createState() =>
      _ConsultaRelatorioCirurgiaPageState();
}

class _ConsultaRelatorioCirurgiaPageState
    extends State<ConsultaRelatorioCirurgiaPage> {
  final RelatorioCirurgiaService _service = RelatorioCirurgiaService();
  final RelatorioCirurgiaPdfService _pdfService =
      RelatorioCirurgiaPdfService();
  final EmpresaReportService _empresaService = EmpresaReportService();
  final GlobalKey _shareKey = GlobalKey();
  late RelatorioCirurgia _currentRelatorio;
  bool _isLoading = false;
  bool _isSharing = false;
  bool _isReady = false;
  RelatorioAccess _access = const RelatorioAccess(
    canEdit: false,
    canDelete: false,
  );

  @override
  void initState() {
    super.initState();
    _currentRelatorio = widget.relatorio;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final RelatorioCirurgia? fresh =
          await _service.getById(widget.relatorio.nummov);
      final UserPermissions permissions =
          await AuthService.getUserPermissions();
      if (!mounted) {
        return;
      }
      setState(() {
        if (fresh != null) {
          _currentRelatorio = fresh;
        }
        _access = _currentRelatorio.evaluateAccess(permissions);
        _isReady = true;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _access = _currentRelatorio.evaluateAccess(
          const UserPermissions(),
        );
        _isReady = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _shareRelatorio() async {
    final ShareFormat? format = await ShareFormatSheet.show(context);
    if (format == null || !mounted) {
      return;
    }
    setState(() => _isSharing = true);
    try {
      if (format == ShareFormat.image) {
        final Uint8List? bytes =
            await ScreenCaptureService.capturePng(_shareKey);
        if (bytes == null) {
          throw Exception('Não foi possível capturar a imagem.');
        }
        await ScreenCaptureService.sharePngBytes(
          bytes: bytes,
          fileName: 'rel_cirurgia_${_currentRelatorio.nummov}',
          text: 'Rel Cirurgia ${_currentRelatorio.nummov}',
        );
      } else {
        final UserModel? user = await AuthService.getCurrentUser();
        final empresa = await _empresaService.fetchReportData();
        final Uint8List pdf = await _pdfService.buildSingleRelatorioPdf(
          item: _currentRelatorio,
          empresa: empresa,
          usuario: user,
        );
        await AgendaRelatorioExportService.sharePdf(
          bytes: pdf,
          fileName: 'rel_cirurgia_${_currentRelatorio.nummov}',
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _openRegistroHora() async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegistroHoraCirurgiaPage(
          relatorio: _currentRelatorio,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _loadDetail();
    }
  }

  Future<void> _editRelatorio() async {
    if (!_access.canEdit) {
      return;
    }
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            RelatorioCirurgiaFormPage(relatorio: _currentRelatorio),
      ),
    );
    if (saved == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _showDeleteConfirmation() {
    showProtectedDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o relatório de ${_currentRelatorio.pacienteName}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteRelatorio();
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

  Future<void> _deleteRelatorio() async {
    if (!_access.canDelete) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _service.delete(_currentRelatorio.nummov);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relatório excluído com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatorio Cirurgia'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _isSharing ? null : _shareRelatorio,
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share),
            tooltip: 'Compartilhar',
          ),
        ],
        bottom: _isReady ? _buildTopActionBar() : null,
      ),
      body: !_isReady || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RepaintBoundary(
              key: _shareKey,
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    ..._buildAlertBanners(),
                    ..._buildDetailFields(),
                  ],
                ),
              ),
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
    if (_access.concluidoMessage != null) {
      banners.add(_buildAlertBanner(
        _access.concluidoMessage!,
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
        children: <Widget>[
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
          children: <Widget>[
            _buildTopActionItem(
              icon: Icons.access_time,
              label: 'Registro',
              onTap: _openRegistroHora,
            ),
            if (_access.canEdit)
              _buildTopActionItem(
                icon: Icons.edit_outlined,
                label: 'Editar',
                onTap: _editRelatorio,
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
          children: <Widget>[
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

  List<Widget> _buildDetailFields() {
    final RelatorioCirurgia item = _currentRelatorio;
    return <Widget>[
      _buildInfoField('Rel', item.nummov.toString(), false),
      _buildInfoField('No Agenda', '${item.nagecir ?? ''}', false),
      _buildInfoField('Paciente', _textOrEmpty(item.pacNome), true),
      _buildInfoField('Medico', _textOrEmpty(item.medNome), true),
      _buildInfoField('Hospital/Clinica', _textOrEmpty(item.cliNome), true),
      _buildInfoField('Convenio', _textOrEmpty(item.convNome), true),
      _buildInfoField('Tipo Cirurgia', _textOrEmpty(item.tipoCirurgiaDisplay), true),
      _buildInfoField('Data Cirurgia', item.dataCirurgiaDisplay, true),
      _buildInfoField('Data Emissao', item.dataEmissaoDisplay, true),
      _buildInfoField('Inicio', _textOrEmpty(item.hrini), true),
      _buildInfoField('Fim', _textOrEmpty(item.hrfin), true),
      _buildInfoField(
        'Lado',
        RelatorioFieldLabels.ladoToDisplay(item.lado),
        true,
      ),
      _buildInfoField(
        'Primaria/Revisao',
        RelatorioFieldLabels.displayPriRevForPdf(item.priRev),
        true,
      ),
      _buildInfoField(
        'Sexo',
        RelatorioFieldLabels.sexoToDisplay(item.sexo),
        true,
      ),
      _buildInfoField(
        'Urgencia',
        RelatorioFieldLabels.displaySnForPdf(item.urgencia),
        true,
      ),
      _buildInfoField(
        'Rel Concluido',
        RelatorioFieldLabels.displaySnForPdf(item.status),
        true,
      ),
      _buildInfoField('Digitado por', item.digitadorLabel, false),
      _buildInfoField('Observacao', _textOrEmpty(item.historico), true),
      _buildInfoField(
        'Material da Cirurgia',
        _textOrEmpty(item.sistemaAplicado),
        true,
      ),
      _buildInfoField('Problema Cirurgia', _textOrEmpty(item.problema), true),
    ];
  }

  Widget _buildInfoField(String label, String value, bool isEditable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTheme.consultaLabelStyleOf(context)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTheme.consultaValueStyleOf(context, isEditable: isEditable),
            ),
          ),
          Divider(color: Colors.grey.shade300, height: 1),
        ],
      ),
    );
  }

  String _textOrEmpty(String? value) {
    return value?.trim() ?? '';
  }
}
