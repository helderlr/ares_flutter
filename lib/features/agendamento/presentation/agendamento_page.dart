import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/theme/app_theme.dart';
import '../models/agendamento_model.dart';
import '../services/agendamento_service_paginado.dart';
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
  String? _filtroMedico;
  String? _filtroConvenio;
  String? _filtroHospital;
  String? _filtroTipoCirurgia;
  bool _filtrosAtivos = false;

  @override
  void initState() {
    super.initState();
    _setTodayFilter();
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

  Future<void> _loadFirstPage() async {
    print('🔄 _loadFirstPage chamado - _isLoading: $_isLoading');
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    print('🔄 Definindo _isLoading = true');

    try {
      print('🔄 Carregando primeira página...');
      print('🔍 Parâmetros de busca:');
      print('  - Página: 1');
      print('  - Tamanho: 50');
      print('  - Ordenação: date desc');
      print('  - Busca: "$_currentSearchQuery"');

      final response = await _service.fetchAgendamentosPaginated(
        page: 1,
        pageSize: 50,
        sortBy: 'date',
        sortOrder: 'desc',
        searchQuery: _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
      );

      setState(() {
        _agendamentos = response.agendamentos;
        _paginationInfo = response.pagination;
        _isLoading = false;
      });
      print('🔄 Definindo _isLoading = false');

      print(
          '✅ Primeira página carregada: ${_agendamentos.length} agendamentos');
      print('📊 Total de registros: ${_paginationInfo?.totalRecords}');
    } catch (e) {
      print('❌ Erro ao carregar primeira página: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = _formatUserError(e);
      });
      print('🔄 Definindo _isLoading = false (erro)');
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading ||
        _paginationInfo == null ||
        !_paginationInfo!.hasNextPage) {
      return;
    }

    print('📄 Carregando próxima página...');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _service.fetchNextPage(
        _paginationInfo!,
        sortBy: 'date',
        sortOrder: 'desc',
        searchQuery: _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
      );

      setState(() {
        _agendamentos.addAll(response.agendamentos);
        _paginationInfo = response.pagination;
        _isLoading = false;
      });

      print(
          '✅ Próxima página carregada: ${response.agendamentos.length} novos agendamentos');
    } catch (e) {
      print('❌ Erro ao carregar próxima página: $e');
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
    if (_isFilteringToday() || !_filtrosAtivos) {
      _setTodayFilter();
    }
    await _loadFirstPage();
  }

  void _navigateToForm([AgendaCirurgia? agendamento]) async {
    print('🔄 Navegando para formulário de agendamento...');
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AgendamentoFormPage(agendamento: agendamento),
      ),
    );

    if (result == true) {
      print('✅ Retornando do formulário - atualizando lista');
      await _refreshAgendamentos();
    }
  }

  void _navigateToConsulta(AgendaCirurgia agendamento) async {
    print('🔍 Navegando para consulta do agendamento: ${agendamento.id}');
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConsultaAgendamentoPage(agendamento: agendamento),
      ),
    );

    if (result == true) {
      print('✅ Retornando da consulta - atualizando lista');
      await _refreshAgendamentos();
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
      body: Column(
        children: [
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
                print('🔍 Campo de busca alterado: "$value"');
              },
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
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

    final List<AgendaCirurgia> agendamentosFiltrados =
        _aplicarFiltrosLocais(_agendamentos);
    if (agendamentosFiltrados.isEmpty && !_isLoading) {
      if (_isFilteringToday() &&
          _currentSearchQuery.isEmpty &&
          !_hasOtherFiltersActive()) {
        return _buildTodayEmptyState();
      }
      if (_agendamentos.isNotEmpty) {
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
              'Não há cirurgias agendadas para hoje.',
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
            onPressed: () {
              setState(() {
                _filtroDataInicio = null;
                _filtroDataFim = null;
                _filtroMedico = null;
                _filtroConvenio = null;
                _filtroHospital = null;
                _filtroTipoCirurgia = null;
                _filtrosAtivos = false;
              });
            },
            child: const Text('Limpar Filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendamentosList() {
    // Aplicar filtros locais
    final agendamentosFiltrados = _aplicarFiltrosLocais(_agendamentos);

    return RefreshIndicator(
      onRefresh: _refreshAgendamentos,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: agendamentosFiltrados.length + (_isLoading ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == agendamentosFiltrados.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final agendamento = agendamentosFiltrados[index];
          return _buildAgendamentoItem(agendamento);
        },
      ),
    );
  }

  Widget _buildAgendamentoItem(AgendaCirurgia agendamento) {
    return InkWell(
      onTap: () => _navigateToConsulta(agendamento),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            AgendaStatusLegend.buildBallForAgenda(agendamento, size: 28),
            const SizedBox(width: 16),
            Expanded(
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Cirurgia: ${agendamento.cirurgiaName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Data: ${agendamento.dataCirurgia} às ${agendamento.horaCirurgia}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Médico: ${agendamento.medicoName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Convênio: ${agendamento.convenioName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Hospital: ${agendamento.nomcli ?? 'Hospital não informado'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filtros'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtro por período de data
                    const Text(
                      'Período da Cirurgia:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    _filtroDataInicio ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setStateDialog(() {
                                  _filtroDataInicio = date;
                                });
                              }
                            },
                            child: Text(_filtroDataInicio != null
                                ? '${_filtroDataInicio!.day.toString().padLeft(2, '0')}/${_filtroDataInicio!.month.toString().padLeft(2, '0')}/${_filtroDataInicio!.year}'
                                : 'Data Início'),
                          ),
                        ),
                        const Text(' até '),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _filtroDataFim ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setStateDialog(() {
                                  _filtroDataFim = date;
                                });
                              }
                            },
                            child: Text(_filtroDataFim != null
                                ? '${_filtroDataFim!.day.toString().padLeft(2, '0')}/${_filtroDataFim!.month.toString().padLeft(2, '0')}/${_filtroDataFim!.year}'
                                : 'Data Fim'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filtro por médico
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Médico',
                        hintText: 'Nome do médico',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _filtroMedico = value.isEmpty ? null : value;
                      },
                      controller:
                          TextEditingController(text: _filtroMedico ?? ''),
                    ),
                    const SizedBox(height: 16),

                    // Filtro por convênio
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Convênio',
                        hintText: 'Nome do convênio',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _filtroConvenio = value.isEmpty ? null : value;
                      },
                      controller:
                          TextEditingController(text: _filtroConvenio ?? ''),
                    ),
                    const SizedBox(height: 16),

                    // Filtro por hospital
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Hospital',
                        hintText: 'Nome do hospital',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _filtroHospital = value.isEmpty ? null : value;
                      },
                      controller:
                          TextEditingController(text: _filtroHospital ?? ''),
                    ),
                    const SizedBox(height: 16),

                    // Filtro por tipo de cirurgia
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Cirurgia',
                        hintText: 'Nome da cirurgia',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _filtroTipoCirurgia = value.isEmpty ? null : value;
                      },
                      controller: TextEditingController(
                          text: _filtroTipoCirurgia ?? ''),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setStateDialog(() {
                      _filtroDataInicio = null;
                      _filtroDataFim = null;
                      _filtroMedico = null;
                      _filtroConvenio = null;
                      _filtroHospital = null;
                      _filtroTipoCirurgia = null;
                    });
                  },
                  child: const Text('Limpar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _aplicarFiltros();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _aplicarFiltros() {
    setState(() {
      _filtrosAtivos = _filtroDataInicio != null ||
          _filtroDataFim != null ||
          _filtroMedico != null ||
          _filtroConvenio != null ||
          _filtroHospital != null ||
          _filtroTipoCirurgia != null;
    });
    _loadFirstPage();
  }

  List<AgendaCirurgia> _aplicarFiltrosLocais(
      List<AgendaCirurgia> agendamentos) {
    return agendamentos.where((AgendaCirurgia agendamento) {
      if (_filtroDataInicio != null || _filtroDataFim != null) {
        final DateTime? dataCirurgia = agendamento.datcir;
        if (dataCirurgia == null) {
          return false;
        }
        final DateTime dataSomente = DateTime(
          dataCirurgia.year,
          dataCirurgia.month,
          dataCirurgia.day,
        );
        if (_filtroDataInicio != null) {
          final DateTime inicioSomente = DateTime(
            _filtroDataInicio!.year,
            _filtroDataInicio!.month,
            _filtroDataInicio!.day,
          );
          if (dataSomente.isBefore(inicioSomente)) {
            return false;
          }
        }
        if (_filtroDataFim != null) {
          final DateTime fimSomente = DateTime(
            _filtroDataFim!.year,
            _filtroDataFim!.month,
            _filtroDataFim!.day,
          );
          if (dataSomente.isAfter(fimSomente)) {
            return false;
          }
        }
      }

      // Filtro por médico
      if (_filtroMedico != null) {
        if (!agendamento.medicoName
            .toLowerCase()
            .contains(_filtroMedico!.toLowerCase())) return false;
      }

      // Filtro por convênio
      if (_filtroConvenio != null) {
        if (!agendamento.convenioName
            .toLowerCase()
            .contains(_filtroConvenio!.toLowerCase())) return false;
      }

      // Filtro por hospital
      if (_filtroHospital != null) {
        final hospital = agendamento.nomcli ?? '';
        if (!hospital.toLowerCase().contains(_filtroHospital!.toLowerCase()))
          return false;
      }

      // Filtro por tipo de cirurgia
      if (_filtroTipoCirurgia != null) {
        if (!agendamento.cirurgiaName
            .toLowerCase()
            .contains(_filtroTipoCirurgia!.toLowerCase())) return false;
      }

      return true;
    }).toList();
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
    return _filtroMedico != null ||
        _filtroConvenio != null ||
        _filtroHospital != null ||
        _filtroTipoCirurgia != null;
  }

  void _showAllAgendamentos() {
    setState(() {
      _filtroDataInicio = null;
      _filtroDataFim = null;
      _filtroMedico = null;
      _filtroConvenio = null;
      _filtroHospital = null;
      _filtroTipoCirurgia = null;
      _filtrosAtivos = false;
    });
  }

  void _filterTodayAgendamentos() {
    setState(() {
      _setTodayFilter();
      _filtroMedico = null;
      _filtroConvenio = null;
      _filtroHospital = null;
      _filtroTipoCirurgia = null;
    });
  }
}
