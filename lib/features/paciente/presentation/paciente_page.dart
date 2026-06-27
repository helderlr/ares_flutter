import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../services/paciente_service_paginado.dart';
import 'consulta_paciente_page.dart';
import 'paciente_form_page.dart';

class PacientePage extends StatefulWidget {
  const PacientePage({super.key});

  @override
  State<PacientePage> createState() => _PacientePageState();
}

class _PacientePageState extends State<PacientePage> {
  final PatientServicePaginado _service = PatientServicePaginado();
  final List<Patient> _allPatients = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  PaginationInfo? _pagination;
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
    print('🚀 Inicializando PacientePage');
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
      _allPatients.clear();
      _hasMoreData = true;
    });

    try {
      print('🔄 Carregando primeira página...');
      print('🔍 Parâmetros de busca:');
      print('  - Página: 1');
      print('  - Tamanho: 50');
      print('  - Ordenação: $_currentSortBy $_currentSortOrder');
      print('  - Busca: "$_currentSearchQuery"');

      final response = await _service.fetchPatientsPaginated(
        page: 1,
        pageSize: 50,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        searchQuery: _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
      );

      print('🔄 Definindo _isLoading = false');
      setState(() {
        _allPatients.addAll(response.patients);
        _pagination = response.pagination;
        _hasMoreData = response.pagination.hasNextPage;
        _isLoading = false;
      });

      print(
          '✅ Primeira página carregada: ${response.patients.length} pacientes');
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
        _allPatients.addAll(response.patients);
        _pagination = response.pagination;
        _hasMoreData = response.pagination.hasNextPage;
        _isLoadingMore = false;
      });

      print(
          '✅ Próxima página carregada: ${response.patients.length} pacientes');
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
    // Apenas deixa a interface mostrar "Nenhum paciente encontrado"
    if (error.toString().contains('404') ||
        error.toString().contains('Nenhum paciente encontrado')) {
      // Não faz nada - deixa a interface mostrar a mensagem amigável
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
        title: const Text('Pacientes'),
        centerTitle: true,
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
                color: Theme.of(context).colorScheme.surface,
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
                  hintText: 'Buscar paciente',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          // Lista de pacientes
          Expanded(
            child: _isLoading && _allPatients.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _allPatients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _currentSearchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.people_outline,
                              size: 64,
                              color: AppColors.lightBlue.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentSearchQuery.isNotEmpty
                                  ? 'Nenhum paciente encontrado'
                                  : 'Sem Pacientes',
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
                          // Lista de pacientes
                          Expanded(
                            child: ListView.separated(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _allPatients.length,
                              separatorBuilder: (_, __) => const Divider(
                                color: Colors.grey,
                                height: 1,
                                thickness: 0.5,
                              ),
                              itemBuilder: (context, index) {
                                final patient = _allPatients[index];
                                return _buildPatientItem(patient);
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PacienteFormPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientItem(Patient patient) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConsultaPacientePage(paciente: patient),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            // Ícone do paciente
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.lightBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Informações do paciente
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do paciente
                  Text(
                    patient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.listItemTitleStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nascimento: ${_formatDate(patient.birthDate)}',
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

String _formatDate(String date) {
  if (date.isEmpty || date == 'null' || date == 'Data não disponível') {
    return 'Data não disponível';
  }

  try {
    // Remove possíveis espaços e caracteres extras
    final cleanDate = date.trim();

    // Se contém 'T', é formato ISO (2023-12-25T00:00:00)
    if (cleanDate.contains('T')) {
      final parts = cleanDate.split('T').first.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }

    // Se é formato simples (2023-12-25)
    if (cleanDate.contains('-')) {
      final parts = cleanDate.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }

    // Se já está no formato brasileiro (25/12/2023)
    if (cleanDate.contains('/')) {
      return cleanDate;
    }

    return cleanDate;
  } catch (e) {
    return 'Data inválida';
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
