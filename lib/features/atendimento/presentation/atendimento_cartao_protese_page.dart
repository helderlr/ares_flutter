import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/cartao_protese_model.dart';
import '../services/cartao_protese_service_paginado.dart';

class AtendimentoCartaoProtesePage extends StatefulWidget {
  const AtendimentoCartaoProtesePage({super.key});

  @override
  State<AtendimentoCartaoProtesePage> createState() =>
      _AtendimentoCartaoProtesePageState();
}

class _AtendimentoCartaoProtesePageState
    extends State<AtendimentoCartaoProtesePage> {
  final CartaoProteseServicePaginado _service = CartaoProteseServicePaginado();
  final List<CartaoProtese> _itens = <CartaoProtese>[];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  CartaoProtesePaginationInfo? _pagination;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  Timer? _searchDebounce;
  String? _errorMessage;

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
      _errorMessage = null;
      _itens.clear();
    });
    try {
      final CartaoProtesePaginatedResponse response =
          await _service.fetchPaginated(
        page: 1,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
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
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || _pagination == null || !_pagination!.hasNextPage) {
      return;
    }
    setState(() => _isLoadingMore = true);
    try {
      final CartaoProtesePaginatedResponse response =
          await _service.fetchNextPage(
        _pagination!,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartao Protese'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar paciente, medico, hospital...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                onPressed: _loadFirstPage,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (_itens.isEmpty) {
      return const Center(child: Text('Nenhum cartao protese encontrado.'));
    }
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _itens.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          if (index >= _itens.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildItem(_itens[index]);
        },
      ),
    );
  }

  Widget _buildItem(CartaoProtese item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      title: Text(
        item.titulo,
        style: AppTheme.listItemTitleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Cod: ${item.codigo}', style: AppTheme.listItemSubtitleStyle),
          if (item.medico != null)
            Text('Med: ${item.medico}', style: AppTheme.listItemSubtitleStyle),
          if (item.hospital != null)
            Text('Hosp: ${item.hospital}', style: AppTheme.listItemSubtitleStyle),
          if (item.tipoProtese != null)
            Text('Protese: ${item.tipoProtese}', style: AppTheme.listItemSubtitleStyle),
          Text(
            'Data Cir: ${item.dataCirurgiaDisplay}',
            style: AppTheme.listItemSubtitleStyle,
          ),
          if (item.situacao != null)
            Text('Sit: ${item.situacao}', style: AppTheme.listItemSubtitleStyle),
        ],
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.lightBlue.withOpacity(0.15),
        child: const Icon(Icons.credit_card, color: AppColors.lightBlue),
      ),
    );
  }
}
