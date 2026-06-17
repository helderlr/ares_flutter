import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';

class Patient {
  final int codpac;
  final String nompac;
  final String? datnas;
  final String? carteira;
  final int? codUsu;

  const Patient({
    required this.codpac,
    required this.nompac,
    this.datnas,
    this.carteira,
    this.codUsu,
  });

  int get id => codpac;
  String get name => nompac;
  String get birthDate => datnas ?? 'Data não disponível';
  String get planCardNumber => carteira ?? 'Carteira não disponível';

  bool canEditByUser(int? loggedCodusu) {
    if (loggedCodusu == null || codUsu == null) {
      return false;
    }
    return codUsu == loggedCodusu;
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    final dynamic codigo = json['codpac'] ?? json['codigo'];
    final dynamic nome = json['nompac'] ?? json['nome'];
    final dynamic dataNascimento = json['datnas'] ?? json['dataNascimento'];
    final dynamic carteira = json['carteira'] ?? json['carpac'];
    return Patient(
      codpac: codigo is int
          ? codigo
          : (codigo is String ? int.tryParse(codigo) ?? 0 : 0),
      nompac: nome is String && nome.isNotEmpty
          ? nome
          : 'Paciente ${codigo ?? 'N/A'}',
      datnas: dataNascimento is String &&
              dataNascimento.isNotEmpty &&
              dataNascimento != 'null'
          ? dataNascimento
          : null,
      carteira: carteira is String && carteira.isNotEmpty ? carteira : null,
      codUsu: _parseCodUsu(json['cod_usu'] ?? json['codusu'] ?? json['COD_USU']),
    );
  }

  static int? _parseCodUsu(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'codpac': codpac,
      'nompac': nompac,
      'datnas': datnas,
      'carteira': carteira,
      'cod_usu': codUsu,
    };
  }

  Patient copyWith({
    int? codpac,
    String? nompac,
    String? datnas,
    String? carteira,
    int? codUsu,
  }) {
    return Patient(
      codpac: codpac ?? this.codpac,
      nompac: nompac ?? this.nompac,
      datnas: datnas ?? this.datnas,
      carteira: carteira ?? this.carteira,
      codUsu: codUsu ?? this.codUsu,
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
      pageSize: json['pageSize'] ?? 50,
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
    // Verifica se é o formato esperado com data e pagination
    if (json.containsKey('data') && json.containsKey('pagination')) {
      final List<dynamic> data = json['data'] ?? [];
      final patients = data.map((item) => Patient.fromJson(item)).toList();
      final pagination = PaginationInfo.fromJson(json['pagination'] ?? {});

      return PaginatedResponse(
        patients: patients,
        pagination: pagination,
      );
    }

    // Se não tem data/pagination, assume que é uma lista direta
    // e cria uma paginação simulada
    final List<dynamic> data = json is List ? json as List<dynamic> : [];
    final patients = data.map((item) => Patient.fromJson(item)).toList();

    // Cria paginação simulada para compatibilidade
    final pagination = PaginationInfo(
      currentPage: 1,
      pageSize: 50,
      totalRecords: patients.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );

    return PaginatedResponse(
      patients: patients,
      pagination: pagination,
    );
  }

  // Construtor para quando a API retorna uma lista diretamente
  factory PaginatedResponse.fromList(List<dynamic> data) {
    final patients = data.map((item) => Patient.fromJson(item)).toList();

    // Cria paginação simulada
    final pagination = PaginationInfo(
      currentPage: 1,
      pageSize: 50,
      totalRecords: patients.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );

    return PaginatedResponse(
      patients: patients,
      pagination: pagination,
    );
  }
}

class PatientServicePaginado {

  Future<PaginatedResponse> fetchPatientsPaginated({
    required int page,
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    final queryParams = <String, String>{
      'PageNumber': page.toString(),
      'PageSize': pageSize.toString(),
    };

    if (sortBy != null) {
      // Mapeia os campos para os nomes corretos da API
      String orderByField;
      switch (sortBy) {
        case 'name':
          orderByField = 'nompac';
          break;
        case 'id':
          orderByField = 'codpac';
          break;
        case 'birthDate':
          orderByField = 'datnas';
          break;
        default:
          orderByField = 'nompac';
      }
      queryParams['OrderBy'] = '$orderByField ${sortOrder ?? 'asc'}';
      print('📊 Ordenação configurada: $orderByField ${sortOrder ?? 'asc'}');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Usa o parâmetro correto da API: NOMPAC
      queryParams['NOMPAC'] = searchQuery;
      print('🔍 Parâmetro de busca adicionado: NOMPAC=$searchQuery');
      print('🔍 Query params atualizados: $queryParams');
    }

    final Map<String, String> paramsWithEmpresa =
        await HttpRequestHelper.withEmpresaId(queryParams);
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/paciente')
        .replace(queryParameters: paramsWithEmpresa);

    print('🔍 DEBUG PAGINAÇÃO:');
    print('URL: $uri');
    print('📋 Parâmetros enviados: $paramsWithEmpresa');

    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      print('📥 Resposta recebida:');
      print('Status: ${httpResponse.statusCode}');
      if (httpResponse.statusCode == 200) {
        final dynamic data = HttpRequestHelper.decodeResponse(responseBody);
        print('✅ Dados paginados recebidos');
        print('Tipo de resposta: ${data.runtimeType}');

        PaginatedResponse response;

        // Verifica se é uma lista direta ou objeto com data/pagination
        if (data is List) {
          print('📋 API retornou lista direta com ${data.length} pacientes');
          response = PaginatedResponse.fromList(data);
        } else if (data is Map<String, dynamic>) {
          print('📋 API retornou objeto com data e pagination');
          response = PaginatedResponse.fromJson(data);
        } else {
          throw Exception(
              'Formato de resposta inesperado: ${data.runtimeType}');
        }

        print(
            '📊 Página ${response.pagination.currentPage} de ${response.pagination.totalPages}');
        print('📋 ${response.patients.length} pacientes nesta página');
        print('📈 Total de registros: ${response.pagination.totalRecords}');
        if (searchQuery != null && searchQuery.isNotEmpty) {
          print(
              '🔍 Busca por "$searchQuery" retornou ${response.patients.length} resultados');
          if (response.patients.isNotEmpty) {
            print(
                '📝 Primeiros resultados: ${response.patients.take(3).map((p) => p.name).join(', ')}');
          }
        }

        httpClient.close();
        return response;
      } else if (httpResponse.statusCode == 401) {
        httpClient.close();
        await AuthService.handleSessionExpired();
        throw const UnauthorizedException();
      } else {
        httpClient.close();
        throw Exception(
            'Erro na API: ${httpResponse.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<PaginatedResponse> fetchNextPage(
    PaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasNextPage) {
      throw Exception('Não há mais páginas para carregar');
    }

    return fetchPatientsPaginated(
      page: currentPagination.currentPage + 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<PaginatedResponse> fetchPreviousPage(
    PaginationInfo currentPagination, {
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    if (!currentPagination.hasPreviousPage) {
      throw Exception('Não há página anterior');
    }

    return fetchPatientsPaginated(
      page: currentPagination.currentPage - 1,
      pageSize: currentPagination.pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
    );
  }

  Future<PaginatedResponse> fetchPage(
    int page, {
    int pageSize = 50,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) async {
    return fetchPatientsPaginated(
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: searchQuery,
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
