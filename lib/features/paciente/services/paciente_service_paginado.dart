import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Patient {
  final int id;
  final String name;
  final String birthDate;
  final String planCardNumber;

  const Patient({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.planCardNumber,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    final codigo = json['codpac'] ?? json['codigo'];
    final nome = json['nompac'] ?? json['nome'];
    final dataNascimento = json['datnas'] ?? json['dataNascimento'];
    final carteira = json['carteira'];

    return Patient(
      id: codigo is int
          ? codigo
          : (codigo is String ? int.tryParse(codigo) ?? 0 : 0),
      name: nome is String && nome.isNotEmpty
          ? nome
          : 'Paciente ${codigo ?? 'N/A'}',
      birthDate: dataNascimento is String &&
              dataNascimento.isNotEmpty &&
              dataNascimento != 'null'
          ? dataNascimento
          : 'Data não disponível',
      planCardNumber: carteira is String && carteira.isNotEmpty
          ? carteira
          : 'Carteira não disponível',
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}

class PaginatedResponse {
  final List<Patient> patients;
  final PaginationInfo pagination;

  const PaginatedResponse({
    required this.patients,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    final patients = data.map((item) => Patient.fromJson(item)).toList();
    final pagination = PaginationInfo.fromJson(json['pagination'] ?? {});

    return PaginatedResponse(
      patients: patients,
      pagination: pagination,
    );
  }
}

class PatientServicePaginado {
  static const String baseUrl = 'https://45.162.242.43';

  /// Busca pacientes com paginação real
  Future<PaginatedResponse> fetchPatientsPaginated({
    required int page,
    required int pageSize,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    // Constrói a URL com parâmetros de paginação
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (sortBy != null) {
      queryParams['sortBy'] = sortBy;
    }
    if (sortOrder != null) {
      queryParams['sortOrder'] = sortOrder;
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search'] = searchQuery;
    }

    final uri = Uri.parse('$baseUrl/api/Paciente/list_paciente')
        .replace(queryParameters: queryParams);
    final url = uri.toString();

    print('🔍 DEBUG PAGINAÇÃO:');
    print('URL: $url');
    print('Página: $page, Tamanho: $pageSize');

    // Obtém o token JWT
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      throw Exception(
          'Token de autenticação não encontrado. Faça login novamente.');
    }

    try {
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;

      final request = await httpClient.getUrl(uri);
      request.headers.set('Accept', '*/*');
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('📥 Resposta recebida:');
      print('Status: ${httpResponse.statusCode}');

      if (httpResponse.statusCode == 200) {
        final data = json.decode(responseBody);
        print('✅ Dados paginados recebidos');

        final response = PaginatedResponse.fromJson(data);
        print(
            '📊 Página ${response.pagination.currentPage} de ${response.pagination.totalPages}');
        print('📋 ${response.patients.length} pacientes nesta página');
        print('📈 Total de registros: ${response.pagination.totalRecords}');

        httpClient.close();
        return response;
      } else if (httpResponse.statusCode == 401) {
        httpClient.close();
        throw Exception(
            'Token de autenticação inválido ou expirado. Faça login novamente.');
      } else {
        httpClient.close();
        throw Exception(
            'Erro na API: ${httpResponse.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Busca a próxima página
  Future<PaginatedResponse> fetchNextPage(
      PaginationInfo currentPagination) async {
    if (!currentPagination.hasNextPage) {
      throw Exception('Não há mais páginas para carregar');
    }

    return fetchPatientsPaginated(
      page: currentPagination.currentPage + 1,
      pageSize: currentPagination.pageSize,
    );
  }

  /// Busca a página anterior
  Future<PaginatedResponse> fetchPreviousPage(
      PaginationInfo currentPagination) async {
    if (!currentPagination.hasPreviousPage) {
      throw Exception('Não há página anterior');
    }

    return fetchPatientsPaginated(
      page: currentPagination.currentPage - 1,
      pageSize: currentPagination.pageSize,
    );
  }

  /// Busca uma página específica
  Future<PaginatedResponse> fetchPage(int page, {int pageSize = 10}) async {
    return fetchPatientsPaginated(
      page: page,
      pageSize: pageSize,
    );
  }
}

/// Exemplo de uso na página de pacientes
class PacientePagePaginada extends StatefulWidget {
  const PacientePagePaginada({super.key});

  @override
  State<PacientePagePaginada> createState() => _PacientePagePaginadaState();
}

class _PacientePagePaginadaState extends State<PacientePagePaginada> {
  final PatientServicePaginado _service = PatientServicePaginado();
  final List<Patient> _allPatients = [];
  PaginationInfo? _pagination;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _currentSortBy = 'name';
  String _currentSortOrder = 'asc';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.fetchPatientsPaginated(
        page: 1,
        pageSize: 10,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        searchQuery:
            _searchController.text.isEmpty ? null : _searchController.text,
      );

      setState(() {
        _allPatients.clear();
        _allPatients.addAll(response.patients);
        _pagination = response.pagination;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Tratar erro
    }
  }

  Future<void> _loadNextPage() async {
    if (_pagination == null || !_pagination!.hasNextPage || _isLoadingMore)
      return;

    setState(() => _isLoadingMore = true);
    try {
      final response = await _service.fetchNextPage(_pagination!);

      setState(() {
        _allPatients.addAll(response.patients);
        _pagination = response.pagination;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      // Tratar erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes (Paginado)'),
        actions: [
          // Controles de ordenação
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (String value) {
              // Implementar mudança de ordenação
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Por Nome')),
              const PopupMenuItem(value: 'id', child: Text('Por Código')),
              const PopupMenuItem(value: 'birthDate', child: Text('Por Data')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo de pesquisa
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar pacientes...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _loadFirstPage(),
            ),
          ),

          // Lista de pacientes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _allPatients.length +
                        (_pagination?.hasNextPage == true ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _allPatients.length) {
                        // Botão "Carregar mais"
                        return _buildLoadMoreButton();
                      }

                      final patient = _allPatients[index];
                      return _buildPatientItem(patient);
                    },
                  ),
          ),

          // Informações de paginação
          if (_pagination != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Página ${_pagination!.currentPage} de ${_pagination!.totalPages} '
                '(${_pagination!.totalRecords} total)',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isLoadingMore ? null : _loadNextPage,
        child: _isLoadingMore
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Carregando...'),
                ],
              )
            : const Text('Carregar Mais Pacientes'),
      ),
    );
  }

  Widget _buildPatientItem(Patient patient) {
    return ListTile(
      title: Text(patient.name),
      subtitle: Text('Nascimento: ${patient.birthDate}'),
      leading: CircleAvatar(
        child: Text(patient.name[0]),
      ),
    );
  }
}
