import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../core/widgets/protected_ui.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/share_format_sheet.dart';
import '../../../core/services/screen_capture_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/agendamento_model.dart';
import '../models/agenda_list_filters.dart';
import '../services/agendamento_service_paginado.dart';
import '../services/agenda_lista_pdf_service.dart';
import '../../login/models/user_model.dart';
import '../../login/services/auth_service.dart';
import '../widgets/agenda_filter_dialog.dart';
import '../widgets/agenda_status_legend.dart';
import 'agendamento_form_page.dart';
import 'consulta_agendamento_page.dart';

class AgendamentoPage extends StatefulWidget {
  const AgendamentoPage({Key? key}) : super(key: key);

  @override
  State<AgendamentoPage> createState() => _AgendamentoPageState();
}

class _AgendamentoPageState extends State<AgendamentoPage> {
  final AgendamentoServicePaginado _service = AgendamentoServicePaginado();
  final AgendaListaPdfService _listaPdfService = AgendaListaPdfService();
  final GlobalKey _shareKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<AgendaCirurgia> _agendamentos = [];
  AgendaCirurgiaPaginationInfo? _paginationInfo;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentSearchQuery = '';
  Timer? _debounceTimer;

  // Filtros
  DateTime? _filtroDataInicio;
  DateTime? _filtroDataFim;
  AgendaDateFilterField _filtroTipoData = AgendaDateFilterField.dataCirurgia;
  String? _filtroPaciente;
  String? _filtroNummov;
  String? _filtroMedico;
  String? _filtroConvenio;
  String? _filtroHospital;
  String? _filtroTipoCirurgia;
  String? _filtroInstrumentador;
  String? _filtroVendedor;
  AgendaTriFilter _filtroAgendaCancelada = AgendaTriFilter.todas;
  AgendaTriFilter _filtroAgendaComPedido = AgendaTriFilter.todas;
  AgendaTriFilter _filtroAgendaComRelatorio = AgendaTriFilter.todas;
  AgendaTriFilter _filtroAgendaCopia = AgendaTriFilter.todas;
  AgendaTipmarFilter _filtroTipoMarcacao = AgendaTipmarFilter.todas;
  AgendaLadoFilter _filtroLado = AgendaLadoFilter.todas;
  AgendaSituacaoFilter _filtroSituacao = AgendaSituacaoFilter.todos;
  bool _filtrosAtivos = false;
  bool _isSharing = false;
  final TextEditingController _filtroPacienteController =
      TextEditingController();
  final TextEditingController _filtroNummovController = TextEditingController();
  final TextEditingController _filtroMedicoController = TextEditingController();
  final TextEditingController _filtroConvenioController = TextEditingController();
  final TextEditingController _filtroHospitalController = TextEditingController();
  final TextEditingController _filtroTipoCirurgiaController =
      TextEditingController();
  final TextEditingController _filtroInstrumentadorController =
      TextEditingController();
  final TextEditingController _filtroVendedorController = TextEditingController();

  AgendaListFilters _buildListFilters() {
    return AgendaListFilters(
      dateFrom: _filtroDataInicio,
      dateTo: _filtroDataFim,
      dateField: _filtroTipoData,
      pacienteQuery: _filtroPaciente,
      nummovQuery: _filtroNummov,
      medicoQuery: _filtroMedico,
      convenioQuery: _filtroConvenio,
      hospitalQuery: _filtroHospital,
      tipoCirurgiaQuery: _filtroTipoCirurgia,
      instrumentadorQuery: _filtroInstrumentador,
      vendedorQuery: _filtroVendedor,
      agendaCancelada: _filtroAgendaCancelada,
      agendaComPedido: _filtroAgendaComPedido,
      agendaComRelatorio: _filtroAgendaComRelatorio,
      agendaCopia: _filtroAgendaCopia,
      tipoMarcacao: _filtroTipoMarcacao,
      lado: _filtroLado,
      situacaoAgenda: _filtroSituacao,
    );
  }

  InputDecoration _buildFilterDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  void _normalizeDateFilters() {
    if (_filtroDataInicio != null && _filtroDataFim != null) {
      final DateTime inicio = AgendaListFilters.dateOnly(_filtroDataInicio!);
      final DateTime fim = AgendaListFilters.dateOnly(_filtroDataFim!);
      if (inicio.isAfter(fim)) {
        _filtroDataInicio = fim;
        _filtroDataFim = inicio;
      }
    }
  }

  String _formatFilterDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  DateTime _clampPickerDate(
    DateTime value,
    DateTime minDate,
    DateTime maxDate,
  ) {
    if (value.isBefore(minDate)) {
      return minDate;
    }
    if (value.isAfter(maxDate)) {
      return maxDate;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _setTodayFilter() {
    final DateTime hoje = DateTime.now();
    _filtroDataInicio = DateTime(hoje.year, hoje.month, hoje.day);
    _filtroDataFim = DateTime(hoje.year, hoje.month, hoje.day);
    _filtrosAtivos = true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _filtroPacienteController.dispose();
    _filtroNummovController.dispose();
    _filtroMedicoController.dispose();
    _filtroConvenioController.dispose();
    _filtroHospitalController.dispose();
    _filtroTipoCirurgiaController.dispose();
    _filtroInstrumentadorController.dispose();
    _filtroVendedorController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query != _currentSearchQuery) {
        setState(() {
          _currentSearchQuery = query;
        });
        _loadFirstPage();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _paginationInfo != null &&
        _paginationInfo!.hasNextPage) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage({bool force = false}) async {
    if (_isLoading && !force) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    print('ðŸ”„ Definindo _isLoading = true');

    try {
      print('ðŸ”„ Carregando primeira pÃ¡gina...');
      print('ðŸ” ParÃ¢metros de busca:');
      print('  - PÃ¡gina: 1');
      print('  - Tamanho: 50');
      print('  - OrdenaÃ§Ã£o: date desc');
      print('  - Busca: "$_currentSearchQuery"');

      final response = await _service.fetchAgendamentosPaginated(
        page: 1,
        pageSize: 50,
        sortBy: 'date',
        sortOrder: 'desc',
        searchQuery: _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
        filters: _buildListFilters(),
      );

      setState(() {
        _agendamentos = response.agendamentos;
        _paginationInfo = response.pagination;
        _isLoading = false;
      });
      print('ðŸ”„ Definindo _isLoading = false');

      print(
          'âœ… Primeira pÃ¡gina carregada: ${_agendamentos.length} agendamentos');
      print('ðŸ“Š Total de registros: ${_paginationInfo?.totalRecords}');
    } catch (e) {
      print('âŒ Erro ao carregar primeira pÃ¡gina: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = _formatUserError(e);
      });
      print('ðŸ”„ Definindo _isLoading = false (erro)');
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading ||
        _paginationInfo == null ||
        !_paginationInfo!.hasNextPage) {
      return;
    }

    print('ðŸ“„ Carregando prÃ³xima pÃ¡gina...');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _service.fetchNextPage(
        _paginationInfo!,
        sortBy: 'date',
        sortOrder: 'desc',
        searchQuery: _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
        filters: _buildListFilters(),
      );

      setState(() {
        _agendamentos.addAll(response.agendamentos);
        _paginationInfo = response.pagination;
        _isLoading = false;
      });

      print(
          'âœ… PrÃ³xima pÃ¡gina carregada: ${response.agendamentos.length} novos agendamentos');
    } catch (e) {
      print('âŒ Erro ao carregar prÃ³xima pÃ¡gina: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = _formatUserError(e);
      });
    }
  }

  Future<void> _refreshAgendamentos() async {
    _service.clearCache();
    _currentSearchQuery = '';
    _searchController.clear();
    await _loadFirstPage();
  }

  void _navigateToForm([AgendaCirurgia? agendamento]) async {
    print('ðŸ”„ Navegando para formulÃ¡rio de agendamento...');
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AgendamentoFormPage(agendamento: agendamento),
      ),
    );

    if (result == true) {
      print('âœ… Retornando do formulÃ¡rio - atualizando lista');
      await _refreshAgendamentos();
    }
  }

  void _navigateToConsulta(AgendaCirurgia agendamento) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConsultaAgendamentoPage(agendamento: agendamento),
      ),
    );

    if (result == true) {
      await _refreshAgendamentos();
    }
  }

  Future<void> _shareAgendaList() async {
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
          throw Exception('NÃ£o foi possÃ­vel capturar a imagem.');
        }
        await ScreenCaptureService.sharePngBytes(
          bytes: bytes,
          fileName: 'agenda_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Agenda Ares',
        );
      } else {
        final AgendaListFilters filters = _buildListFilters();
        final List<AgendaCirurgia> items = await _service.fetchAllAgendamentos(
          filters: filters,
          searchQuery: _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
        );
        if (!mounted) {
          return;
        }
        if (items.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum registro para compartilhar.')),
          );
          return;
        }
        final UserModel? user = await AuthService.getCurrentUser();
        final String userName = user?.nome ?? 'UsuÃ¡rio';
        final Uint8List pdf = await _listaPdfService.buildListaPdf(
          items: items,
          filters: filters,
          userName: userName,
        );
        await ScreenCaptureService.sharePdfFile(
          bytes: pdf,
          fileName: 'agenda_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Agenda Ares',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(_isFilteringToday()
            ? 'Agenda - Hoje (${_formatDateDisplay(DateTime.now())})'
            : 'Agenda'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          tooltip: 'Voltar',
        ),
        actions: [
          IconButton(
            onPressed: _isSharing || _isLoading ? null : _shareAgendaList,
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
          if (_isFilteringToday())
            IconButton(
              icon: const Icon(Icons.calendar_view_month),
              onPressed: _showAllAgendamentos,
              tooltip: 'Ver todas as agendas',
            )
          else
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: _filterTodayAgendamentos,
              tooltip: 'Agendas de hoje',
            ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _filtrosAtivos ? Colors.orange : Colors.white,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filtros',
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
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar paciente',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: const BorderSide(color: Colors.lightBlue),
                    ),
                  ),
                  onChanged: (value) {
                    print('ðŸ” Campo de busca alterado: "$value"');
                  },
                ),
              ),
              Expanded(
                child: _buildContent(),
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
            children: [
              if (!_isFilteringToday())
                InkWell(
                  onTap: _filterTodayAgendamentos,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.today, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Hoje',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              InkWell(
                onTap: () => AgendaStatusLegend.showLegendDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
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
                onTap: () => _navigateToForm(),
                child: const Icon(
                  Icons.add,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return _buildErrorState();
    }

    if (_agendamentos.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_agendamentos.isEmpty && !_isLoading) {
      if (_isFilteringToday() &&
          _currentSearchQuery.isEmpty &&
          !_hasOtherFiltersActive()) {
        return _buildTodayEmptyState();
      }
      if (_filtrosAtivos || _currentSearchQuery.isNotEmpty) {
        return _buildNoResultsState();
      }
      return _buildEmptyState();
    }
    return _buildAgendamentosList();
  }

  Widget _buildTodayEmptyState() {
    final DateTime hoje = DateTime.now();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.today, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text(
              'Nenhum registro para o dia atual',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDateDisplay(hoje),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'NÃ£o hÃ¡ cirurgias agendadas para hoje.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAllAgendamentos,
              icon: const Icon(Icons.calendar_view_month),
              label: const Text('Ver todas as agendas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Erro ao carregar agendas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshAgendamentos,
            child: const Text('Tentar novamente'),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  String _formatUserError(Object error) {
    final String message = error.toString().replaceAll('Exception: ', '');
    if (message.length > 280) {
      return '${message.substring(0, 280)}...';
    }
    return message;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isFilteringToday() ? Icons.today : Icons.event_note,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _currentSearchQuery.isEmpty
                ? (_isFilteringToday()
                    ? 'Sem agendas para hoje'
                    : 'Sem agendas')
                : 'Nenhuma agenda encontrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          if (_currentSearchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'para "$_currentSearchQuery"',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
          if (_isFilteringToday()) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAllAgendamentos,
              icon: const Icon(Icons.calendar_view_month),
              label: const Text('Ver todas as agendas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.filter_list_off,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma agenda encontrada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'com os filtros aplicados',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showAllAgendamentos,
            child: const Text('Limpar Filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendamentosList() {
    return RefreshIndicator(
      onRefresh: _refreshAgendamentos,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _agendamentos.length + (_isLoading ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == _agendamentos.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final AgendaCirurgia agendamento = _agendamentos[index];
          return _buildAgendamentoItem(agendamento);
        },
      ),
    );
  }

  Widget _buildAgendamentoItem(AgendaCirurgia agendamento) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgendaStatusLegend.buildBallForAgenda(agendamento, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => _navigateToConsulta(agendamento),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agendamento.pacienteName,
                    style: AppTheme.listItemTitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No Agenda: ${agendamento.nummov}',
                    style: AppTheme.listItemSubtitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Cirurgia: ${agendamento.cirurgiaName}',
                    style: AppTheme.listItemSubtitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Data: ${agendamento.dataCirurgia} Ã s ${agendamento.horaCirurgia}',
                    style: AppTheme.listItemSubtitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'MÃ©dico: ${agendamento.medicoName}',
                    style: AppTheme.listItemSubtitleStyle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ConvÃªnio: ${agendamento.convenioName}',
                    style: AppTheme.listItemSubtitleStyle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Hospital: ${agendamento.nomcli ?? 'Hospital nÃ£o informado'}',
                    style: AppTheme.listItemSubtitleStyle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
            size: 16,
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final AgendaListFilters? result = await AgendaFilterDialog.show(
      context,
      initial: _buildListFilters(),
      requireDateRange: false,
      showClearButton: true,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _filtroDataInicio = result.dateFrom;
      _filtroDataFim = result.dateTo;
      _filtroTipoData = result.dateField;
      _filtroPaciente = result.pacienteQuery;
      _filtroNummov = result.nummovQuery;
      _filtroMedico = result.medicoQuery;
      _filtroConvenio = result.convenioQuery;
      _filtroHospital = result.hospitalQuery;
      _filtroTipoCirurgia = result.tipoCirurgiaQuery;
      _filtroInstrumentador = result.instrumentadorQuery;
      _filtroVendedor = result.vendedorQuery;
      _filtroAgendaCancelada = result.agendaCancelada;
      _filtroAgendaComPedido = result.agendaComPedido;
      _filtroAgendaComRelatorio = result.agendaComRelatorio;
      _filtroAgendaCopia = result.agendaCopia;
      _filtroTipoMarcacao = result.tipoMarcacao;
      _filtroLado = result.lado;
      _filtroSituacao = result.situacaoAgenda;
      _filtrosAtivos = result.hasActiveFilters;
    });
    _loadFirstPage(force: true);
  }

  void _aplicarFiltros() {
    _normalizeDateFilters();
    setState(() {
      _filtrosAtivos = _buildListFilters().hasActiveFilters;
    });
    _loadFirstPage(force: true);
  }

  String _formatDateDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool _isFilteringToday() {
    final today = DateTime.now();
    return _filtroDataInicio != null &&
        _filtroDataFim != null &&
        _isSameDay(_filtroDataInicio!, today) &&
        _isSameDay(_filtroDataFim!, today);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _hasOtherFiltersActive() {
    return _filtroPaciente != null ||
        _filtroNummov != null ||
        _filtroMedico != null ||
        _filtroConvenio != null ||
        _filtroHospital != null ||
        _filtroTipoCirurgia != null ||
        _filtroInstrumentador != null ||
        _filtroVendedor != null ||
        _filtroTipoData != AgendaDateFilterField.dataCirurgia ||
        _filtroAgendaCancelada != AgendaTriFilter.todas ||
        _filtroAgendaComPedido != AgendaTriFilter.todas ||
        _filtroAgendaComRelatorio != AgendaTriFilter.todas ||
        _filtroAgendaCopia != AgendaTriFilter.todas ||
        _filtroTipoMarcacao != AgendaTipmarFilter.todas ||
        _filtroLado != AgendaLadoFilter.todas ||
        _filtroSituacao != AgendaSituacaoFilter.todos;
  }

  void _clearTextFilters() {
    _filtroPaciente = null;
    _filtroNummov = null;
    _filtroMedico = null;
    _filtroConvenio = null;
    _filtroHospital = null;
    _filtroTipoCirurgia = null;
    _filtroInstrumentador = null;
    _filtroVendedor = null;
    _filtroTipoData = AgendaDateFilterField.dataCirurgia;
    _filtroAgendaCancelada = AgendaTriFilter.todas;
    _filtroAgendaComPedido = AgendaTriFilter.todas;
    _filtroAgendaComRelatorio = AgendaTriFilter.todas;
    _filtroAgendaCopia = AgendaTriFilter.todas;
    _filtroTipoMarcacao = AgendaTipmarFilter.todas;
    _filtroLado = AgendaLadoFilter.todas;
    _filtroSituacao = AgendaSituacaoFilter.todos;
    _filtroPacienteController.clear();
    _filtroNummovController.clear();
    _filtroMedicoController.clear();
    _filtroConvenioController.clear();
    _filtroHospitalController.clear();
    _filtroTipoCirurgiaController.clear();
    _filtroInstrumentadorController.clear();
    _filtroVendedorController.clear();
  }

  void _showAllAgendamentos() {
    setState(() {
      _filtroDataInicio = null;
      _filtroDataFim = null;
      _clearTextFilters();
      _filtrosAtivos = false;
    });
    _loadFirstPage(force: true);
  }

  void _filterTodayAgendamentos() {
    setState(() {
      _setTodayFilter();
      _clearTextFilters();
    });
    _loadFirstPage(force: true);
  }
}
