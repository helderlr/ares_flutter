import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../services/tipo_cirurgia_service_paginado.dart';
import '../models/tipo_cirurgia_model.dart';
import 'consulta_tipo_cirurgia_page.dart';
import 'tipo_cirurgia_form_page.dart';

class TipoCirurgiaPage extends StatefulWidget {
  const TipoCirurgiaPage({super.key});

  @override
  State<TipoCirurgiaPage> createState() => _TipoCirurgiaPageState();
}

class _TipoCirurgiaPageState extends State<TipoCirurgiaPage> {
  final TipoCirurgiaServicePaginado _service = TipoCirurgiaServicePaginado();
  final List<TipoCirurgia> _allTiposCirurgia = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  TipoCirurgiaPaginationInfo? _pagination;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _currentSortBy = 'name';
  String _currentSortOrder = 'asc';
  String _currentSearchQuery = '';
  bool _hasMoreData = true;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    print('🚀 Inicializando TipoCirurgiaPage');
    print('🔍 _currentSearchQuery inicial: "$_currentSearchQuery"');
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    print('🔄 _loadFirstPage chamado - _isLoading: $_isLoading');
    if (_isLoading) {
      print('⚠️ Já está carregando, ignorando chamada');
      return;
    }

    print('🔄 Definindo _isLoading = true');
    setState(() {
      _isLoading = true;
      _allTiposCirurgia.clear();
      _hasMoreData = true;
    });

    try {
      print('🔄 Carregando primeira página...');
      print('🔍 Parâmetros de busca:');
      print('  - Página: 1');
      print('  - Tamanho: 50');
      print('  - Ordenação: $_currentSortBy $_currentSortOrder');
      print('  - Busca: "$_currentSearchQuery"');

      final response = await _service.fetchTiposCirurgiaPaginated(
        page: 1,
        pageSize: 50,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        searchQuery: _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
      );

      print('🔄 Definindo _isLoading = false');
      setState(() {
        _allTiposCirurgia.addAll(response.tiposCirurgia);
        _pagination = response.pagination;
        _hasMoreData = response.pagination.hasNextPage;
        _isLoading = false;
      });

      print(
          '✅ Primeira página carregada: ${response.tiposCirurgia.length} tipos de cirurgia');
      print('📊 Total de registros: ${response.pagination.totalRecords}');
    } catch (e) {
      print('❌ Erro ao carregar primeira página: $e');
      print('🔄 Definindo _isLoading = false (erro)');
      setState(() => _isLoading = false);
      _handleError(e);
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMoreData || _pagination == null) return;

    setState(() => _isLoadingMore = true);

    try {
      print('🔄 Carregando próxima página...');
      final response = await _service.fetchNextPage(
        _pagination!,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        searchQuery: _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
      );

      setState(() {
        _allTiposCirurgia.addAll(response.tiposCirurgia);
        _pagination = response.pagination;
        _hasMoreData = response.pagination.hasNextPage;
        _isLoadingMore = false;
      });

      print(
          '✅ Próxima página carregada: ${response.tiposCirurgia.length} tipos de cirurgia');
    } catch (e) {
      print('❌ Erro ao carregar próxima página: $e');
      setState(() => _isLoadingMore = false);
      _handleError(e);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  void _onSearchChanged() {
    print('🔍 _onSearchChanged chamado');
    print('📝 Texto atual: "${_searchController.text}"');

    // Cancela o timer anterior se existir
    _searchDebounceTimer?.cancel();

    // Cria um novo timer para debounce
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final newQuery = _searchController.text.trim();
      print('⏰ Timer executado');
      print('📝 Controller text: "${_searchController.text}"');
      print('🔍 Trimmed query: "$newQuery"');

      // Sempre executa a busca quando há mudança
      print('🔍 Comparando: "$_currentSearchQuery" vs "$newQuery"');
      if (newQuery != _currentSearchQuery) {
        print('🔍 Busca alterada: "$_currentSearchQuery" -> "$newQuery"');
        _currentSearchQuery = newQuery;

        print('🔄 Executando busca por: "$newQuery"');
        print('🔄 Chamando _loadFirstPage...');
        _loadFirstPage(); // Recarrega com busca server-side
      } else {
        print('⚠️ Query não alterada, não executando busca');
      }
    });
  }

  void _handleError(dynamic error) {
    // Para erros de "nenhum resultado encontrado", não mostra SnackBar
    if (error.toString().contains('404') ||
        error.toString().contains('Nenhum tipo de cirurgia encontrado')) {
      return;
    }

    // Para outros erros críticos, mostra mensagem amigável
    String userMessage;
    if (error.toString().contains('401')) {
      userMessage = 'Sessão expirada. Faça login novamente.';
    } else if (error.toString().contains('Erro de conexão')) {
      userMessage = 'Problema de conexão. Verifique sua internet.';
    } else {
      userMessage = 'Erro ao carregar dados. Tente novamente.';
    }

    _showErrorSnackBar(userMessage);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipo Cirurgia'),
        centerTitle: true,
        backgroundColor: AppColors.lightBlue,
        elevation: 0,
        actions: [],
      ),
      body: Column(
        children: [
          // Controle de pesquisa
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                ],
                onChanged: (value) {
                  print('🔍 onChanged chamado com: "$value"');
                  _onSearchChanged();
                },
                decoration: const InputDecoration(
                  hintText: 'Buscar tipo de cirurgia',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          // Lista de tipos de cirurgia
          Expanded(
            child: _isLoading && _allTiposCirurgia.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _allTiposCirurgia.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _currentSearchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.healing_outlined,
                              size: 64,
                              color: AppColors.lightBlue.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentSearchQuery.isNotEmpty
                                  ? 'Nenhum tipo de cirurgia encontrado'
                                  : 'Sem Tipos de Cirurgia',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: AppColors.lightBlue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Lista de tipos de cirurgia
                          Expanded(
                            child: ListView.separated(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _allTiposCirurgia.length,
                              separatorBuilder: (_, __) => const Divider(
                                color: Colors.grey,
                                height: 1,
                                thickness: 0.5,
                              ),
                              itemBuilder: (context, index) {
                                final tipoCirurgia = _allTiposCirurgia[index];
                                return _buildTipoCirurgiaItem(tipoCirurgia);
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.lightBlue,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 28),
              onPressed: () async {
                // Aguarda o resultado da criação
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const TipoCirurgiaFormPage(),
                  ),
                );

                // Se criou um novo tipo de cirurgia, recarrega a lista
                if (result == true) {
                  await _loadFirstPage();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoCirurgiaItem(TipoCirurgia tipoCirurgia) {
    return InkWell(
      onTap: () async {
        // Aguarda o resultado da consulta (se houve alteração)
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) =>
                ConsultaTipoCirurgiaPage(tipoCirurgia: tipoCirurgia),
          ),
        );

        // Se houve alteração, recarrega a lista
        if (result == true) {
          await _loadFirstPage();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            // Ícone do tipo de cirurgia
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.healing,
                color: AppColors.lightBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Informações do tipo de cirurgia
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do tipo de cirurgia
                  Text(
                    tipoCirurgia.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.listItemTitleStyle,
                  ),
                  const SizedBox(height: 4),
                  if (tipoCirurgia.description != 'Descrição não disponível')
                    Text(
                      'Descrição: ${tipoCirurgia.description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.listItemSubtitleStyle,
                    ),
                  if (tipoCirurgia.value != 'Valor não disponível')
                    Text(
                      'Valor: ${tipoCirurgia.value}',
                      style: AppTheme.listItemSubtitleStyle,
                    ),
                ],
              ),
            ),
            // Seta de navegação
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}





























