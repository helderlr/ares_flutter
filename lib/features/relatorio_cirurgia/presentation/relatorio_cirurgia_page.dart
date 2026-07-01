import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/relatorio_cirurgia_model.dart';
import '../models/relatorio_list_filters.dart';
import '../services/relatorio_cirurgia_service_paginado.dart';
import '../widgets/relatorio_filter_dialog.dart';
import 'relatorio_cirurgia_form_page.dart';

class RelatorioCirurgiaPage extends StatefulWidget {
  const RelatorioCirurgiaPage({super.key});

  @override
  State<RelatorioCirurgiaPage> createState() => _RelatorioCirurgiaPageState();
}

class _RelatorioCirurgiaPageState extends State<RelatorioCirurgiaPage> {
  final RelatorioCirurgiaServicePaginado _service =
      RelatorioCirurgiaServicePaginado();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<RelatorioCirurgia> _itens = <RelatorioCirurgia>[];
  RelatorioCirurgiaPaginationInfo? _pagination;
  RelatorioListFilters _filters = RelatorioListFilters(
    dateFrom: DateTime.now(),
    dateTo: RelatorioListFilters.maxAllowedDate(),
  );
  bool _isLoading = false;
  bool _isLoadingMore = false;
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
      _filters = RelatorioListFilters(
        dateFrom: result.dateFrom ?? DateTime.now(),
        dateTo: result.dateTo ?? RelatorioListFilters.maxAllowedDate(),
        dateField: result.dateField,
        hospitalQuery: result.hospitalQuery,
        medicoQuery: result.medicoQuery,
        convenioQuery: result.convenioQuery,
        pacienteQuery: result.pacienteQuery,
        digitadoPorQuery: result.digitadoPorQuery,
        numrelQuery: result.numrelQuery,
        nagecirQuery: result.nagecirQuery,
        codinsQuery: result.codinsQuery,
        codcirQuery: result.codcirQuery,
        codProdutoQuery: result.codProdutoQuery,
        tipoQuery: result.tipoQuery,
        lado: result.lado,
        sexo: result.sexo,
        darVisto: result.darVisto,
        relProblema: result.relProblema,
        relComAgenda: result.relComAgenda,
        relComPedido: result.relComPedido,
      );
    });
    await _loadFirstPage();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openForm([RelatorioCirurgia? item]) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RelatorioCirurgiaFormPage(relatorio: item),
      ),
    );
    if (saved == true) {
      await _loadFirstPage();
    }
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
            onPressed: _isLoading ? null : _openFilters,
            icon: Badge(
              isLabelVisible: _filtersActive,
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
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
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _itens.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (BuildContext context, int index) {
                            if (index >= _itens.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final RelatorioCirurgia item = _itens[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(
                                  '${item.pacienteName} • ${item.dataCirurgiaDisplay}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Mov: ${item.nummov} • Rel: ${item.numrel ?? '—'}',
                                    ),
                                    Text(
                                      'Agenda: ${item.nagecir ?? '—'} • ${item.medicoName}',
                                    ),
                                    Text(item.hospitalName),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openForm(item),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
