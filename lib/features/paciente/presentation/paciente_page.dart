import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'dart:convert';
import 'dart:io';
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
    // Extrai e trata os dados com mais cuidado
    // Usando os nomes corretos dos campos da API
    final codigo = json['codpac'] ?? json['codigo'];
    final nome = json['nompac'] ?? json['nome'];
    final dataNascimento = json['datnas'] ?? json['dataNascimento'];
    final carteira = json['carteira'];

    print('🔍 Dados brutos do paciente:');
    print('  codigo: $codigo (${codigo.runtimeType})');
    print('  nome: $nome (${nome.runtimeType})');
    print('  dataNascimento: $dataNascimento (${dataNascimento.runtimeType})');
    print('  carteira: $carteira (${carteira.runtimeType})');

    final processedPatient = Patient(
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

    print(
        '✅ Paciente processado: ${processedPatient.name} - ${processedPatient.birthDate}');
    return processedPatient;
  }
}

class PatientService {
  static const String baseUrl = 'https://45.162.242.43';

  Future<List<Patient>> fetchAllPatients() async {
    // URL específica que funciona
    final url = '$baseUrl/api/Paciente/list_paciente';

    print('🔍 DEBUG PACIENTES:');
    print('URL: $url');

    // Obtém o token JWT
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      print('❌ Token JWT não encontrado');
      throw Exception(
          'Token de autenticação não encontrado. Faça login novamente.');
    }

    print('🔑 Token encontrado: ${token.substring(0, 20)}...');

    try {
      // Para HTTPS, usa HttpClient customizado para aceitar certificados auto-assinados
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) {
          print('🔒 Aceitando certificado auto-assinado para $host:$port');
          return true;
        };

      final request = await httpClient.getUrl(Uri.parse(url));
      request.headers.set('Accept', '*/*');
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');

      print('📤 Requisição enviada com token...');

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('📥 Resposta recebida:');
      print('Status: ${httpResponse.statusCode}');
      print('Headers: ${httpResponse.headers}');
      print(
          'Body: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...');

      if (httpResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(responseBody);
        print('✅ Dados recebidos: ${data.length} pacientes');

        final patients = data
            .map((json) {
              try {
                print('🔍 Processando paciente: $json');
                final patient = Patient.fromJson(json);
                print(
                    '✅ Paciente processado: ${patient.name} - ${patient.birthDate}');
                return patient;
              } catch (e) {
                print('❌ Erro ao processar paciente: $e');
                print('Dados problemáticos: $json');
                print('Tipo dos dados: ${json.runtimeType}');
                print('Campos disponíveis: ${json.keys.toList()}');
                return null;
              }
            })
            .where((patient) => patient != null)
            .cast<Patient>()
            .toList();

        print('✅ Pacientes processados: ${patients.length}');
        httpClient.close();
        return patients;
      } else if (httpResponse.statusCode == 401) {
        print('❌ Erro 401: Token inválido ou expirado');
        httpClient.close();
        throw Exception(
            'Token de autenticação inválido ou expirado. Faça login novamente.');
      } else {
        print('❌ Erro HTTP: ${httpResponse.statusCode}');
        httpClient.close();
        throw Exception(
            'Erro na API: ${httpResponse.statusCode} - $responseBody');
      }
    } catch (e) {
      print('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão: $e');
    }
  }
}

class PacientePage extends StatefulWidget {
  const PacientePage({super.key});

  @override
  State<PacientePage> createState() => _PacientePageState();
}

class _PacientePageState extends State<PacientePage> {
  List<Patient> _allPatients = [];
  List<Patient> _visiblePatients = [];
  List<Patient> _filteredPatients = [];
  final int _pageSize = 15; // Mudou para 15 registros por página
  int _currentMax = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _sortOrder = 'name'; // 'name', 'id', 'birthDate'
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAllPatients();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllPatients() async {
    setState(() => _isLoading = true);
    try {
      print('🔄 Iniciando carregamento de pacientes...');
      _allPatients = await PatientService().fetchAllPatients();

      // Aplica a ordenação inicial
      _sortPatients();

      _filteredPatients = _allPatients;
      _addMorePatients();
      print(
          '✅ Carregamento concluído: ${_allPatients.length} pacientes ordenados por $_sortOrder');
    } catch (e) {
      print('❌ Erro ao carregar pacientes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar pacientes: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = List.from(_allPatients);
      } else {
        _filteredPatients = _allPatients.where((patient) {
          return patient.name.toLowerCase().contains(query) ||
              patient.planCardNumber.toLowerCase().contains(query);
        }).toList();
      }
      _currentMax = 0;
      _addMorePatients();
    });
  }

  void _addMorePatients() {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    final nextMax =
        (_currentMax + _pageSize).clamp(0, _filteredPatients.length);
    setState(() {
      _visiblePatients = _filteredPatients.sublist(0, nextMax);
      _currentMax = nextMax;
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _currentMax < _filteredPatients.length &&
        !_isLoadingMore) {
      _addMorePatients();
    }
  }

  void _changeSortOrder(String sortOrder) {
    setState(() {
      _sortOrder = sortOrder;
      _sortPatients();
      _currentMax = 0;
      _addMorePatients();
    });
  }

  void _sortPatients() {
    switch (_sortOrder) {
      case 'name':
        _allPatients.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'id':
        _allPatients.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'birthDate':
        _allPatients.sort((a, b) {
          final dateA = DateTime.tryParse(a.birthDate) ?? DateTime(1900);
          final dateB = DateTime.tryParse(b.birthDate) ?? DateTime(1900);
          return dateA.compareTo(dateB);
        });
        break;
    }

    // Reaplica o filtro atual mantendo a nova ordenação
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredPatients = List.from(_allPatients);
    } else {
      _filteredPatients = _allPatients.where((patient) {
        return patient.name.toLowerCase().contains(query) ||
            patient.planCardNumber.toLowerCase().contains(query);
      }).toList();
    }
  }

  IconData _getSortIcon() {
    switch (_sortOrder) {
      case 'name':
        return Icons.sort_by_alpha;
      case 'id':
        return Icons.numbers;
      case 'birthDate':
        return Icons.calendar_today;
      default:
        return Icons.sort_by_alpha;
    }
  }

  String _getSortText() {
    switch (_sortOrder) {
      case 'name':
        return 'Ordenado por Nome';
      case 'id':
        return 'Ordenado por Código';
      case 'birthDate':
        return 'Ordenado por Data Nascimento';
      default:
        return 'Ordenado por Nome';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pacientes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.lightBlue,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (String value) {
              _changeSortOrder(value);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, color: AppColors.lightBlue),
                    SizedBox(width: 8),
                    Text('Ordenar por Nome'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'id',
                child: Row(
                  children: [
                    Icon(Icons.numbers, color: AppColors.lightBlue),
                    SizedBox(width: 8),
                    Text('Ordenar por Código'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'birthDate',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.lightBlue),
                    SizedBox(width: 8),
                    Text('Ordenar por Data Nascimento'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          // Lista de pacientes em grid
          Expanded(
            child: _visiblePatients.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _visiblePatients.isEmpty
                    ? const Center(
                        child: Text(
                          'Sem Pacientes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: AppColors.lightBlue,
                          ),
                          textAlign: TextAlign.center,
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
                              itemCount: _visiblePatients.length,
                              separatorBuilder: (_, __) => const Divider(
                                color: Colors.grey,
                                height: 1,
                                thickness: 0.5,
                              ),
                              itemBuilder: (context, index) {
                                final patient = _visiblePatients[index];
                                return _buildPatientItem(patient);
                              },
                            ),
                          ),
                          // Indicador de carregamento
                          if (_isLoadingMore)
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'Carregando mais pacientes...',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          // Informações de paginação e ordenação
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Mostrando ${_visiblePatients.length} de ${_filteredPatients.length} pacientes',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getSortIcon(),
                                      color: AppColors.lightBlue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getSortText(),
                                      style: TextStyle(
                                        color: AppColors.lightBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                // ação de adicionar paciente
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientItem(Patient patient) {
    return Container(
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // Data de nascimento
                Text(
                  'Nascimento: ${_formatDate(patient.birthDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
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
