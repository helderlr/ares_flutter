import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/services/screen_capture_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/share_format_sheet.dart';
import '../../../core/utils/api_error_formatter.dart';
import '../../login/models/user_model.dart';
import '../../login/services/auth_service.dart';
import '../models/cartao_protese_list_filters.dart';
import '../models/cartao_protese_model.dart';
import '../services/cartao_protese_lista_pdf_service.dart';
import '../services/cartao_protese_service_paginado.dart';
import '../widgets/cartao_protese_filter_dialog.dart';
import 'cartao_protese_form_page.dart';
import 'consulta_cartao_protese_page.dart';

class CartaoProteseListPage extends StatefulWidget {
  const CartaoProteseListPage({super.key});

  @override
  State<CartaoProteseListPage> createState() => _CartaoProteseListPageState();
}

class _CartaoProteseListPageState extends State<CartaoProteseListPage> {
  final CartaoProteseServicePaginado _service = CartaoProteseServicePaginado();
  final CartaoProteseListaPdfService _pdfService = CartaoProteseListaPdfService();
  final GlobalKey _shareKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<CartaoProtese> _itens = <CartaoProtese>[];
  CartaoProtesePaginationInfo? _paginationInfo;
  CartaoProteseListFilters _filters = const CartaoProteseListFilters();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentSearchQuery = '';
  Timer? _debounceTimer;
  bool _isSharing = false;

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
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final String query = _searchController.text.trim();
      if (query != _currentSearchQuery) {
        _currentSearchQuery = query;
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
    setState(() {
      _isLoading = true;
      _hasError = false;
      _itens.clear();
    });
    try {
      final CartaoProtesePaginatedResponse response =
          await _service.fetchPaginated(
        page: 1,
        searchQuery:
            _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
        filters: _filters,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _itens.addAll(response.itens);
        _paginationInfo = response.pagination;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _hasError = true;
        _errorMessage = ApiErrorFormatter.format(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_paginationInfo == null || !_paginationInfo!.hasNextPage) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final CartaoProtesePaginatedResponse response =
          await _service.fetchNextPage(
        _paginationInfo!,
        searchQuery:
            _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
        filters: _filters,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _itens.addAll(response.itens);
        _paginationInfo = response.pagination;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _showFilterDialog() async {
    final CartaoProteseListFilters? result =
        await CartaoProteseFilterDialog.show(
      context,
      initial: _filters,
    );
    if (result == null) {
      return;
    }
    setState(() => _filters = result);
    await _loadFirstPage();
  }

  Future<void> _navigateToForm({CartaoProtese? item}) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            CartaoProteseFormPage(cartao: item),
      ),
    );
    if (saved == true) {
      await _loadFirstPage();
    }
  }

  Future<void> _navigateToConsulta(CartaoProtese item) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            ConsultaCartaoProtesePage(cartao: item),
      ),
    );
    if (changed == true) {
      await _loadFirstPage();
    }
  }

  Future<void> _shareList() async {
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
          fileName: 'cartao_protese_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Cartão Prótese Ares',
        );
      } else {
        final List<CartaoProtese> allItems = await _service.fetchAll(
          filters: _filters,
          searchQuery:
              _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
        );
        if (!mounted) {
          return;
        }
        if (allItems.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum registro para compartilhar.')),
          );
          return;
        }
        final UserModel? user = await AuthService.getCurrentUser();
        final String userName = user?.nome ?? 'Usuário';
        final Uint8List pdf = await _pdfService.buildListaPdf(
          items: allItems,
          filters: _filters,
          userName: userName,
        );
        await ScreenCaptureService.sharePdfFile(
          bytes: pdf,
          fileName: 'cartao_protese_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Cartão Prótese Ares',
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
        title: const Text('Cartão Prótese'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _isSharing || _isLoading ? null : _shareList,
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
            icon: Icon(
              Icons.filter_list,
              color: _filtersActive ? Colors.orange : Colors.white,
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
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar paciente',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        color: Colors.lightBlue,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadFirstPage,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (_itens.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_itens.isEmpty) {
      return const Center(child: Text('Nenhum cartão encontrado.'));
    }
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _itens.length + (_isLoading ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          if (index >= _itens.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildListItem(_itens[index]);
        },
      ),
    );
  }

  Widget _buildListItem(CartaoProtese item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.credit_card, size: 28, color: Colors.green.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => _navigateToConsulta(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.pacienteName,
                    style: AppTheme.listItemTitleStyleOf(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No Cartão: ${item.nummov}',
                    style: AppTheme.listItemSubtitleStyleOf(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.numpedv != null)
                    Text(
                      'No Pedido: ${item.numpedv}',
                      style: AppTheme.listItemSubtitleStyleOf(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    'Cirurgia: ${item.tipoCirurgiaName}',
                    style: AppTheme.listItemSubtitleStyleOf(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Data: ${item.dataCirurgiaDisplay}',
                    style: AppTheme.listItemSubtitleStyleOf(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Médico: ${item.medicoName}',
                    style: AppTheme.listItemSubtitleStyleOf(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Hospital: ${item.hospitalName}',
                    style: AppTheme.listItemSubtitleStyleOf(context),
                    maxLines: 1,
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
}
