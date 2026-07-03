import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/screen_capture_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/protected_ui.dart';
import '../../../core/widgets/share_format_sheet.dart';
import '../../login/models/user_model.dart';
import '../../login/services/auth_service.dart';
import '../../relatorio_cirurgia/models/relatorio_cirurgia_model.dart';
import '../../relatorio_cirurgia/models/relatorio_list_filters.dart';
import '../../relatorio_cirurgia/services/relatorio_cirurgia_service_paginado.dart';
import '../../relatorio_cirurgia/services/relatorio_cirurgia_service.dart';
import '../../relatorio_cirurgia/services/relatorio_filter_state.dart';
import '../models/registro_hora_list_filters.dart';
import '../models/registro_hora_situacao_filter.dart';
import '../widgets/registro_hora_filter_dialog.dart';
import '../services/registro_hora_location_service.dart';
import '../services/registro_hora_service.dart';
import '../services/registro_hora_lista_pdf_service.dart';
import '../../relatorio_cirurgia/services/relatorio_tipo_cirurgia_enrichment_service.dart';
import 'registro_hora_mapa_page.dart';

class RegistroHoraCirurgiaPage extends StatefulWidget {
  final List<RelatorioCirurgia>? initialItens;
  final RelatorioListFilters? filters;
  final RelatorioCirurgia? relatorio;

  const RegistroHoraCirurgiaPage({
    super.key,
    this.initialItens,
    this.filters,
    this.relatorio,
  });

  bool get isSingleRelatorio => relatorio != null;

  @override
  State<RegistroHoraCirurgiaPage> createState() =>
      _RegistroHoraCirurgiaPageState();
}

class _RegistroHoraCirurgiaPageState extends State<RegistroHoraCirurgiaPage> {
  final RegistroHoraService _service = RegistroHoraService();
  final RelatorioCirurgiaService _relatorioService = RelatorioCirurgiaService();
  final RelatorioCirurgiaServicePaginado _listService =
      RelatorioCirurgiaServicePaginado();
  final RegistroHoraListaPdfService _pdfService = RegistroHoraListaPdfService();
  final RelatorioTipoCirurgiaEnrichmentService _enrichmentService =
      RelatorioTipoCirurgiaEnrichmentService();
  final GlobalKey _shareKey = GlobalKey();
  final List<RelatorioCirurgia> _itens = <RelatorioCirurgia>[];
  RegistroHoraListFilters _filters = const RegistroHoraListFilters();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSharing = false;
  String? _errorMessage;
  int? _loggedCodins;

  bool get _canEditHorarios => widget.isSingleRelatorio;

  bool get _filtersActive => _filters.hasActiveFilters;

  @override
  void initState() {
    super.initState();
    _loadLoggedCodins();
    _loadItens();
  }

  Future<void> _loadLoggedCodins() async {
    final int? codins = await AuthService.getCurrentCodins();
    if (!mounted) {
      return;
    }
    setState(() => _loggedCodins = codins);
  }

  Future<void> _loadItens() async {
    if (widget.relatorio != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _itens.clear();
      });
      try {
        final RelatorioCirurgia? fresh =
            await _relatorioService.getById(widget.relatorio!.nummov);
        if (!mounted) {
          return;
        }
        final RelatorioCirurgia base = fresh ?? widget.relatorio!;
        final RelatorioCirurgia enriched =
            await _enrichmentService.enrichItem(base);
        if (!mounted) {
          return;
        }
        setState(() {
          _itens.add(enriched);
          _isLoading = false;
        });
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _itens.add(widget.relatorio!);
          _isLoading = false;
          _errorMessage = error.toString();
        });
      }
      return;
    }
    if (widget.initialItens != null && widget.initialItens!.isNotEmpty) {
      setState(() {
        _itens
          ..clear()
          ..addAll(widget.initialItens!);
        _errorMessage = null;
      });
      return;
    }
    final RegistroHoraListFilters? widgetFilters = widget.filters != null
        ? RegistroHoraListFilters(relatorioFilters: widget.filters!)
        : null;
    RegistroHoraListFilters activeFilters = widgetFilters ?? _filters;
    if (widgetFilters == null &&
        !activeFilters.hasActiveFilters &&
        RelatorioFilterState.hasActiveFilters) {
      activeFilters = RegistroHoraListFilters(
        relatorioFilters: RelatorioFilterState.activeFilters!,
      );
    }
    if (!activeFilters.hasActiveFilters) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _itens.clear();
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _itens.clear();
    });
    try {
      final List<RelatorioCirurgia> rawItens;
      if (activeFilters.situacao != RegistroHoraSituacaoFilter.todos) {
        rawItens = await _listService.fetchAllRelatorios(
          filters: activeFilters.relatorioFilters,
        );
      } else {
        final RelatorioCirurgiaPaginatedResponse response =
            await _listService.fetchPaginated(
          page: 1,
          filters: activeFilters.relatorioFilters,
        );
        rawItens = response.itens;
      }
      if (!mounted) {
        return;
      }
      final List<RelatorioCirurgia> filtered = rawItens
          .where(activeFilters.situacao.matches)
          .toList();
      final List<RelatorioCirurgia> enriched =
          await _enrichmentService.enrichItens(filtered);
      if (!mounted) {
        return;
      }
      setState(() {
        _itens.addAll(enriched);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _shareList() async {
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum registro para compartilhar.')),
      );
      return;
    }
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
          fileName: 'registro_hora_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Registro Hora Ares',
        );
      } else {
        final UserModel? user = await AuthService.getCurrentUser();
        final String userName = user?.nome ?? 'Usuário';
        final Uint8List pdf = await _pdfService.buildListaPdf(
          items: _itens,
          filters: _filters,
          userName: userName,
        );
        await ScreenCaptureService.sharePdfFile(
          bytes: pdf,
          fileName: 'registro_hora_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Registro Hora Ares',
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

  Future<void> _openFilters() async {
    if (widget.isSingleRelatorio) {
      return;
    }
    final RegistroHoraListFilters? result = await RegistroHoraFilterDialog.show(
      context,
      initial: _filters,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() => _filters = result);
    RelatorioFilterState.update(result.relatorioFilters);
    await _loadItens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Hora Cirurgia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(widget.isSingleRelatorio),
          tooltip: 'Voltar',
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _isSharing || _isLoading || _itens.isEmpty
                ? null
                : _shareList,
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
          if (!widget.isSingleRelatorio)
            IconButton(
              onPressed: _isLoading ? null : _openFilters,
              icon: Badge(
                isLabelVisible: _filtersActive,
                child: const Icon(Icons.filter_list),
              ),
              tooltip: 'Filtros',
            ),
        ],
      ),
      body: RepaintBoundary(
        key: _shareKey,
        child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
              children: <Widget>[
                Text(
                  'Controle de Tempo de Cirurgias',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightBlue,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe o tempo de duração das cirurgias e registre os horários de início e fim.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_errorMessage!),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadItens,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (_itens.isEmpty) {
      return const Center(child: Text('Nenhum relatório encontrado.'));
    }
    return RefreshIndicator(
      onRefresh: _loadItens,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _itens.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildCard(_itens[index], index);
        },
      ),
    );
  }

  Widget _buildCard(RelatorioCirurgia item, int index) {
    final String statusLabel = item.registroHoraStatusLabel;
    final Color statusColor = _statusColor(item.registroHoraStatus);
    final String noRel = '${item.numrel ?? item.nummov}';
    final String instrumentador = _resolveInstrumentadorLabel(item);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    item.pacienteName,
                    style: AppTheme.listItemTitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(statusLabel, statusColor),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoLine('Data Cir:', item.dataCirurgiaDisplay),
            _buildInfoLine('No rel:', noRel),
            _buildInfoLine('Med:', item.medicoName),
            _buildInfoLine('Conv:', item.convenioName),
            _buildInfoLine('Cir:', item.tipoCirurgiaDisplay),
            _buildInfoLine('Instrumentador:', instrumentador),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.access_time,
                    label: 'Início',
                    value: item.horaInicioDisplay,
                    compact: true,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.schedule,
                    label: 'Fim',
                    value: item.horaFimDisplay,
                    compact: true,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.timer,
                    label: 'Duração',
                    value: item.duracaoRegistroHoraDisplay,
                    isHighlight: true,
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (_canEditHorarios) ...<Widget>[
                  TextButton.icon(
                    onPressed: item.canRegistrarHoraInicio && !_isSaving
                        ? () => _registrarHora(item, index, RegistroHoraCampo.inicio)
                        : null,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Início'),
                  ),
                  TextButton.icon(
                    onPressed: item.canRegistrarHoraFim && !_isSaving
                        ? () => _registrarHora(item, index, RegistroHoraCampo.fim)
                        : null,
                    icon: const Icon(Icons.stop, size: 16),
                    label: const Text('Fim'),
                  ),
                ],
                TextButton.icon(
                  onPressed: () => _abrirDetalhes(item),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Detalhes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _resolveInstrumentadorLabel(RelatorioCirurgia item) {
    if (item.codins != null && item.codins! > 0) {
      final String nome = item.instrumentadorDisplay;
      if (nome != '—' && !nome.startsWith('Cód.')) {
        return nome;
      }
      return '${item.codins}';
    }
    if (_loggedCodins != null && _loggedCodins! > 0) {
      return '${_loggedCodins!}';
    }
    return '—';
  }

  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '$label $value',
        style: AppTheme.listItemSubtitleStyle.copyWith(fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
    bool compact = false,
  }) {
    final double valueSize = compact ? 11 : 14;
    final double labelSize = compact ? 10 : 12;
    return Column(
      children: <Widget>[
        Icon(
          icon,
          size: compact ? 14 : 16,
          color: isHighlight ? AppColors.lightBlue : Colors.grey.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: labelSize, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w600,
            color: isHighlight ? AppColors.lightBlue : Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _statusColor(RegistroHoraStatus status) {
    switch (status) {
      case RegistroHoraStatus.concluida:
        return Colors.green;
      case RegistroHoraStatus.emAndamento:
        return Colors.orange;
      case RegistroHoraStatus.pendente:
        return Colors.grey;
    }
  }

  Future<void> _registrarHora(
    RelatorioCirurgia item,
    int index,
    RegistroHoraCampo campo,
  ) async {
    if (!_service.podeRegistrarCampo(item, campo)) {
      final String message = campo == RegistroHoraCampo.fim
          ? 'Registre a hora de início antes da hora de fim.'
          : 'Este horário não pode ser registrado no momento.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    final TimeOfDay initial = TimeOfDay.now();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(_service.labelCampo(campo)),
        content: Text(
          campo == RegistroHoraCampo.inicio
              ? 'Informe a hora de início da cirurgia. A localização atual será registrada.'
              : 'Informe a hora de fim da cirurgia. A localização atual será registrada.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) {
      return;
    }
    final TimeOfDay? picked = await showProtectedTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) {
      return;
    }
    final DateTime hora = _service.buildDataHoraBase(item, picked);
    if (campo == RegistroHoraCampo.fim &&
        item.isDuracaoMenorQueMinutos(
          hora,
          minutos: RegistroHoraService.duracaoMinimaAvisoMinutos,
        )) {
      final bool? confirmarCurta = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Duração curta'),
          content: Text(
            'A diferença entre o fim e o início é inferior a '
            '${RegistroHoraService.duracaoMinimaAvisoMinutos} minutos. '
            'Deseja registrar mesmo assim?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      );
      if (confirmarCurta != true || !mounted) {
        return;
      }
    }
    setState(() => _isSaving = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Registrando hora e localização...'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final RegistroHoraLocationCapture? localizacao =
          await RegistroHoraLocationService.capture();
      final int? codinsToSave =
          item.codins ?? (_loggedCodins != null && _loggedCodins! > 0
              ? _loggedCodins
              : null);
      final RelatorioCirurgia atualizado = await _service.salvarHora(
        item: item,
        campo: campo,
        hora: hora,
        localizacao: localizacao,
        codins: codinsToSave,
      );
      final RelatorioCirurgia? refreshed =
          await _relatorioService.getById(item.nummov);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      setState(() {
        _itens[index] = refreshed ?? atualizado;
        _isSaving = false;
      });
      final String campoLabel =
          campo == RegistroHoraCampo.inicio ? 'início' : 'fim';
      final String locationMsg = localizacao == null
          ? 'Hora de $campoLabel salva. Localização não capturada.'
          : 'Hora de $campoLabel e localização salvas com sucesso.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locationMsg)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $error')),
      );
    }
  }

  Future<void> _abrirDetalhes(RelatorioCirurgia item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegistroHoraMapaPage(relatorio: item),
      ),
    );
  }
}
