import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/screen_capture_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/share_format_sheet.dart';
import '../models/relatorio_cirurgia_model.dart';
import '../models/relatorio_list_filters.dart';
import '../services/relatorio_cirurgia_service_paginado.dart';
import '../services/relatorio_cirurgia_pdf_service.dart';
import '../services/relatorio_filter_state.dart';
import '../widgets/relatorio_filter_dialog.dart';
import '../widgets/relatorio_status_legend.dart';
import '../../agendamento/services/agenda_relatorio_export_service.dart';
import '../../agendamento/services/empresa_report_service.dart';
import '../../login/models/user_model.dart';
import '../../login/services/auth_service.dart';
import 'consulta_relatorio_cirurgia_page.dart';
import 'relatorio_cirurgia_form_page.dart';

class RelatorioCirurgiaPage extends StatefulWidget {
  const RelatorioCirurgiaPage({super.key});

  @override
  State<RelatorioCirurgiaPage> createState() => _RelatorioCirurgiaPageState();
}

class _RelatorioCirurgiaPageState extends State<RelatorioCirurgiaPage> {
  final RelatorioCirurgiaServicePaginado _service =
      RelatorioCirurgiaServicePaginado();
  final RelatorioCirurgiaPdfService _pdfService =
      RelatorioCirurgiaPdfService();
  final EmpresaReportService _empresaService = EmpresaReportService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _shareKey = GlobalKey();
  final List<RelatorioCirurgia> _itens = <RelatorioCirurgia>[];
  RelatorioCirurgiaPaginationInfo? _pagination;
  RelatorioListFilters _filters = const RelatorioListFilters();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSharing = false;
  String _searchQuery = '';
  Timer? _searchDebounce;

  bool get _filtersActive => _filters.hasActiveFilters;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
      _itens.clear();
    });
    try {
      final RelatorioCirurgiaPaginatedResponse response =
          await _service.fetchPaginated(
        page: 1,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        filters: _filters,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _itens.addAll(response.itens);
        _pagination = response.pagination;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      _showError(error.toString());
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || _pagination == null || !_pagination!.hasNextPage) {
      return;
    }
    setState(() => _isLoadingMore = true);
    try {
      final RelatorioCirurgiaPaginatedResponse response =
          await _service.fetchNextPage(
        _pagination!,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        filters: _filters,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _itens.addAll(response.itens);
        _pagination = response.pagination;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingMore = false);
      _showError(error.toString());
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final String query = _searchController.text.trim();
      if (query == _searchQuery) {
        return;
      }
      _searchQuery = query;
      _loadFirstPage();
    });
  }

  Future<void> _openFilters() async {
    final RelatorioListFilters? result = await RelatorioFilterDialog.show(
      context,
      initial: _filters,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _filters = result;
    });
    RelatorioFilterState.update(result);
    await _loadFirstPage();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openConsulta(RelatorioCirurgia item) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ConsultaRelatorioCirurgiaPage(relatorio: item),
      ),
    );
    if (changed == true) {
      await _loadFirstPage();
    }
  }

  Future<void> _openNewForm() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const RelatorioCirurgiaFormPage(),
      ),
    );
    if (saved == true) {
      await _loadFirstPage();
    }
  }

  Future<void> _shareRelatorioList() async {
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
          fileName: 'relatorio_cirurgia_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Relatório Cirurgia Ares',
        );
        return;
      }
      final List<RelatorioCirurgia> items =
          await _service.fetchAllRelatorios(filters: _filters);
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum registro para compartilhar.')),
        );
        return;
      }
      final UserModel? user = await AuthService.getCurrentUser();
      final empresa = await _empresaService.fetchReportData();
      final Uint8List pdf = await _pdfService.buildRelatorioCirurgiaPdf(
        items: items,
        filters: _filters,
        empresa: empresa,
        usuario: user,
      );
      await AgendaRelatorioExportService.sharePdf(
        bytes: pdf,
        fileName: 'rel_cirurgia_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Widget _buildRelatorioItem(RelatorioCirurgia item) {
    final String horaCirurgia = item.horaInicioDisplay == '—'
        ? ''
        : item.horaInicioDisplay;
    final String dataLinha = horaCirurgia.isEmpty
        ? 'Data: ${item.dataCirurgiaDisplay}'
        : 'Data: ${item.dataCirurgiaDisplay} às $horaCirurgia';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RelatorioStatusLegend.buildBallForRelatorio(item, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => _openConsulta(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.pacienteName,
                    style: AppTheme.listItemTitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rel: ${item.nummov}',
                    style: AppTheme.listItemSubtitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Cirurgia: ${item.tipoCirurgiaDisplay}',
                    style: AppTheme.listItemSubtitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dataLinha,
                    style: AppTheme.listItemSubtitleStyle.copyWith(
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Médico: ${item.medicoName}',
                    style: AppTheme.listItemSubtitleStyle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Convênio: ${item.convenioName}',
                    style: AppTheme.listItemSubtitleStyle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Hospital: ${item.hospitalName}',
                    style: AppTheme.listItemSubtitleStyle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatorio de Cirurgia'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            onPressed: _isSharing || _isLoading ? null : _shareRelatorioList,
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
          IconButton(
            onPressed: _isLoading ? null : _openFilters,
            icon: Badge(
              isLabelVisible: _filtersActive,
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _shareKey,
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar paciente, médico, hospital...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _itens.isEmpty
                        ? const Center(child: Text('Nenhum relatório encontrado.'))
                        : RefreshIndicator(
                            onRefresh: _loadFirstPage,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount:
                                  _itens.length + (_isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (BuildContext context, int index) {
                                if (index >= _itens.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _buildRelatorioItem(_itens[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        color: Colors.lightBlue,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                onTap: () => RelatorioStatusLegend.showLegendDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: const Text(
                    'Legenda',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () => _openNewForm(),
                child: const Icon(Icons.add, size: 32, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
