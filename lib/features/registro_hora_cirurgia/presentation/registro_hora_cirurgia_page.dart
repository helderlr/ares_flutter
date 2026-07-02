import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/protected_ui.dart';
import '../../relatorio_cirurgia/models/relatorio_cirurgia_model.dart';
import '../../relatorio_cirurgia/models/relatorio_list_filters.dart';
import '../../relatorio_cirurgia/services/relatorio_cirurgia_service_paginado.dart';
import '../../relatorio_cirurgia/services/relatorio_cirurgia_service.dart';
import '../services/registro_hora_location_service.dart';
import '../services/registro_hora_service.dart';
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
  final List<RelatorioCirurgia> _itens = <RelatorioCirurgia>[];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItens();
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
        setState(() {
          _itens.add(fresh ?? widget.relatorio!);
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _itens.clear();
    });
    try {
      final RelatorioListFilters filters = widget.filters ??
          RelatorioListFilters(
            dateFrom: DateTime.now(),
            dateTo: RelatorioListFilters.maxAllowedDate(),
          );
      final RelatorioCirurgiaPaginatedResponse response =
          await _listService.fetchPaginated(page: 1, filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _itens.addAll(response.itens);
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
      ),
      body: Column(
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
    final String horaCirurgia = item.horaInicioDisplay == '—'
        ? ''
        : item.horaInicioDisplay;
    final String dataLinha = horaCirurgia.isEmpty
        ? item.dataCirurgiaDisplay
        : '${item.dataCirurgiaDisplay} às $horaCirurgia';
    final String noRel = '${item.numrel ?? item.nummov}';
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
            const SizedBox(height: 4),
            Text(
              item.tipoCirurgiaDisplay,
              style: AppTheme.listItemSubtitleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Data: $dataLinha',
              style: AppTheme.listItemSubtitleStyle.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
                Expanded(
                  child: Text(
                    'No Rel: $noRel',
                    style: AppTheme.listItemSubtitleStyle.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
      final RelatorioCirurgia atualizado = await _service.salvarHora(
        item: item,
        campo: campo,
        hora: hora,
        localizacao: localizacao,
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
