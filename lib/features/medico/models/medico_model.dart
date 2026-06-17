class Medico {
  final int codmed;
  final String nommed;
  final String? crm;
  final int? codesp;
  final String? especialidade;
  final int? codUsu;

  const Medico({
    required this.codmed,
    required this.nommed,
    this.crm,
    this.codesp,
    this.especialidade,
    this.codUsu,
  });

  int get id => codmed;
  String get name => nommed;
  String get crmNumber => crm ?? 'CRM não disponível';
  String get specialty => especialidade ?? 'Especialidade não disponível';

  bool canEditByUser(int? loggedCodusu) {
    if (loggedCodusu == null || codUsu == null) {
      return false;
    }
    return codUsu == loggedCodusu;
  }

  factory Medico.fromJson(Map<String, dynamic> json) {
    final dynamic codigo = json['codmed'] ?? json['codigo'];
    final dynamic nome = json['nommed'] ?? json['nome'];
    final dynamic crmMedico = json['crmmed'] ?? json['crm'];
    final dynamic codespRaw = json['codesp'] ?? json['codespe'];
    final int? codespValue = codespRaw is int
        ? codespRaw
        : int.tryParse(codespRaw?.toString() ?? '');
    final String? especialidadeNome = json['especialidade']?.toString() ??
        json['nomeEspecialidade']?.toString() ??
        json['nomesp']?.toString();
    return Medico(
      codmed: codigo is int
          ? codigo
          : (codigo is String ? int.tryParse(codigo) ?? 0 : 0),
      nommed: nome is String && nome.isNotEmpty
          ? nome
          : 'Médico ${codigo ?? 'N/A'}',
      crm: crmMedico is String && crmMedico.isNotEmpty ? crmMedico : null,
      codesp: codespValue,
      especialidade: especialidadeNome != null && especialidadeNome.isNotEmpty
          ? especialidadeNome
          : null,
      codUsu: _parseCodUsu(json['cod_usu'] ?? json['codusu'] ?? json['COD_USU']),
    );
  }

  static int? _parseCodUsu(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

  Medico withEspecialidadeNome(String? nome) {
    if (nome == null || nome.isEmpty) {
      return this;
    }
    return copyWith(especialidade: nome);
  }

  Map<String, dynamic> toJson() {
    return {
      'codmed': codmed,
      'nommed': nommed,
      'crmmed': crm,
      'codesp': codesp,
      'especialidade': especialidade,
      'cod_usu': codUsu,
    };
  }

  Medico copyWith({
    int? codmed,
    String? nommed,
    String? crm,
    int? codesp,
    String? especialidade,
    int? codUsu,
  }) {
    return Medico(
      codmed: codmed ?? this.codmed,
      nommed: nommed ?? this.nommed,
      crm: crm ?? this.crm,
      codesp: codesp ?? this.codesp,
      especialidade: especialidade ?? this.especialidade,
      codUsu: codUsu ?? this.codUsu,
    );
  }
}

class MedicoPaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const MedicoPaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory MedicoPaginationInfo.fromJson(Map<String, dynamic> json) {
    return MedicoPaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 50,
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}

class MedicoPaginatedResponse {
  final List<Medico> medicos;
  final MedicoPaginationInfo pagination;

  const MedicoPaginatedResponse({
    required this.medicos,
    required this.pagination,
  });

  factory MedicoPaginatedResponse.fromJson(Map<String, dynamic> json) {
    // Verifica se é o formato esperado com data e pagination
    if (json.containsKey('data') && json.containsKey('pagination')) {
      final List<dynamic> data = json['data'] ?? [];
      final medicos = data.map((item) => Medico.fromJson(item)).toList();
      final pagination =
          MedicoPaginationInfo.fromJson(json['pagination'] ?? {});

      return MedicoPaginatedResponse(
        medicos: medicos,
        pagination: pagination,
      );
    }

    // Se não tem data/pagination, assume que é uma lista direta
    // e cria uma paginação simulada
    final List<dynamic> data = json is List ? json as List<dynamic> : [];
    final medicos = data.map((item) => Medico.fromJson(item)).toList();

    // Cria paginação simulada para compatibilidade
    final pagination = MedicoPaginationInfo(
      currentPage: 1,
      pageSize: 50,
      totalRecords: medicos.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );

    return MedicoPaginatedResponse(
      medicos: medicos,
      pagination: pagination,
    );
  }

  // Construtor para quando a API retorna uma lista diretamente
  factory MedicoPaginatedResponse.fromList(List<dynamic> data) {
    final medicos = data.map((item) => Medico.fromJson(item)).toList();

    // Cria paginação simulada
    final pagination = MedicoPaginationInfo(
      currentPage: 1,
      pageSize: 50,
      totalRecords: medicos.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );

    return MedicoPaginatedResponse(
      medicos: medicos,
      pagination: pagination,
    );
  }
}
