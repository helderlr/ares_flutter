class Hospital {
  final int codcli;
  final String nomcli;
  final String? nomfan;
  final String? endcli;
  final String? f01cli;
  final String? cgccli;
  final String? cpfcli;
  final String? clihos;
  final int? codUsu;
  // Novos campos de endereço (nomes corretos da API)
  final String? baicli; // bairro
  final String? cidcli; // cidade
  final String? estcli; // estado
  final String? cepcli; // cep
  final String? comple; // complemento
  final String? numero; // número do endereço

  const Hospital({
    required this.codcli,
    required this.nomcli,
    this.nomfan,
    this.endcli,
    this.f01cli,
    this.cgccli,
    this.cpfcli,
    this.clihos,
    this.codUsu,
    this.baicli,
    this.cidcli,
    this.estcli,
    this.cepcli,
    this.comple,
    this.numero,
  });

  // Getters para compatibilidade com código existente
  int get id => codcli;
  String get name => nomcli;
  String get fantasyName => nomfan ?? '';
  String get address => endcli ?? '';
  String get phone => f01cli ?? '';
  String get cnpj => cgccli ?? '';
  String get cpf => cpfcli ?? '';
  String get hospitalClinic => clihos ?? '';
  bool get isHospital =>
      (clihos ?? 'S').trim().toUpperCase() == 'S';

  String get hospitalSimNaoLabel => isHospital ? 'Sim' : 'Não';

  bool canEditByUser(int? loggedCodusu) {
    if (loggedCodusu == null || codUsu == null) {
      return false;
    }
    return codUsu == loggedCodusu;
  }

  // Novos getters
  String get numeroFormatado => numero ?? '';
  String get bairroFormatado => baicli ?? '';
  String get cidadeFormatada => cidcli ?? '';
  String get cepFormatado => cepcli ?? '';
  String get complementoFormatado => comple ?? '';
  String get estadoFormatado => estcli ?? '';

  factory Hospital.fromJson(Map<String, dynamic> json) {
    final codigo = json['codcli'] ?? json['codigo'];
    final nome = json['nomcli'] ?? json['nome'];

    return Hospital(
      codcli: codigo is int
          ? codigo
          : (codigo is String ? int.tryParse(codigo) ?? 0 : 0),
      nomcli: nome is String && nome.isNotEmpty
          ? nome
          : 'Cliente ${codigo ?? 'N/A'}',
      nomfan: json['nomfan'] is String && json['nomfan'].isNotEmpty
          ? json['nomfan']
          : null,
      endcli: json['endcli'] is String && json['endcli'].isNotEmpty
          ? json['endcli']
          : null,
      f01cli: json['f01cli'] is String && json['f01cli'].isNotEmpty
          ? json['f01cli']
          : null,
      cgccli: json['cgccli'] is String && json['cgccli'].isNotEmpty
          ? json['cgccli']
          : null,
      cpfcli: json['cpfcli'] is String && json['cpfcli'].isNotEmpty
          ? json['cpfcli']
          : null,
      clihos: _parseClihos(json['clihos'] ?? json['CLIHOS']),
      codUsu: _parseCodUsu(json['cod_usu'] ?? json['codusu'] ?? json['COD_USU']),
      baicli: json['baicli'] is String && json['baicli'].isNotEmpty
          ? json['baicli']
          : null,
      cidcli: json['cidcli'] is String && json['cidcli'].isNotEmpty
          ? json['cidcli']
          : null,
      estcli: json['estcli'] is String && json['estcli'].isNotEmpty
          ? json['estcli']
          : null,
      cepcli: json['cepcli'] is String && json['cepcli'].isNotEmpty
          ? json['cepcli']
          : null,
      comple: json['comple'] is String && json['comple'].isNotEmpty
          ? json['comple']
          : null,
      numero: json['numero'] is String && json['numero'].isNotEmpty
          ? json['numero']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codcli': codcli,
      'nomcli': nomcli,
      'nomfan': nomfan,
      'endcli': endcli,
      'f01cli': f01cli,
      'cgccli': cgccli,
      'cpfcli': cpfcli,
      'clihos': clihos,
      'cod_usu': codUsu,
      'baicli': baicli,
      'cidcli': cidcli,
      'estcli': estcli,
      'cepcli': cepcli,
      'comple': comple,
      'numero': numero,
    };
  }

  Hospital copyWith({
    int? codcli,
    String? nomcli,
    String? nomfan,
    String? endcli,
    String? f01cli,
    String? cgccli,
    String? cpfcli,
    String? clihos,
    int? codUsu,
    String? baicli,
    String? cidcli,
    String? estcli,
    String? cepcli,
    String? comple,
    String? numero,
  }) {
    return Hospital(
      codcli: codcli ?? this.codcli,
      nomcli: nomcli ?? this.nomcli,
      nomfan: nomfan ?? this.nomfan,
      endcli: endcli ?? this.endcli,
      f01cli: f01cli ?? this.f01cli,
      cgccli: cgccli ?? this.cgccli,
      cpfcli: cpfcli ?? this.cpfcli,
      clihos: clihos ?? this.clihos,
      codUsu: codUsu ?? this.codUsu,
      baicli: baicli ?? this.baicli,
      cidcli: cidcli ?? this.cidcli,
      estcli: estcli ?? this.estcli,
      cepcli: cepcli ?? this.cepcli,
      comple: comple ?? this.comple,
      numero: numero ?? this.numero,
    );
  }

  static String? _parseClihos(dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    return text;
  }

  static int? _parseCodUsu(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }
}

class HospitalPaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const HospitalPaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory HospitalPaginationInfo.fromJson(Map<String, dynamic> json) {
    return HospitalPaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 50,
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}

class HospitalPaginatedResponse {
  final List<Hospital> hospitais;
  final HospitalPaginationInfo pagination;

  const HospitalPaginatedResponse({
    required this.hospitais,
    required this.pagination,
  });

  factory HospitalPaginatedResponse.fromJson(Map<String, dynamic> json) {
    // Verifica se é o formato esperado com data e pagination
    if (json.containsKey('data') && json.containsKey('pagination')) {
      final List<dynamic> data = json['data'] ?? [];
      final hospitais = data.map((item) => Hospital.fromJson(item)).toList();
      final pagination =
          HospitalPaginationInfo.fromJson(json['pagination'] ?? {});

      return HospitalPaginatedResponse(
        hospitais: hospitais,
        pagination: pagination,
      );
    }

    // Se não tem data/pagination, assume que é uma lista direta
    // e cria uma paginação simulada
    final List<dynamic> data = json is List ? json as List<dynamic> : [];
    final hospitais = data.map((item) => Hospital.fromJson(item)).toList();

    // Cria paginação simulada para compatibilidade
    final pagination = HospitalPaginationInfo(
      currentPage: 1,
      pageSize: 50,
      totalRecords: hospitais.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );

    return HospitalPaginatedResponse(
      hospitais: hospitais,
      pagination: pagination,
    );
  }

  // Construtor para quando a API retorna uma lista diretamente
  factory HospitalPaginatedResponse.fromList(List<dynamic> data) {
    final hospitais = data.map((item) => Hospital.fromJson(item)).toList();

    // Cria paginação simulada
    final pagination = HospitalPaginationInfo(
      currentPage: 1,
      pageSize: 50,
      totalRecords: hospitais.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );

    return HospitalPaginatedResponse(
      hospitais: hospitais,
      pagination: pagination,
    );
  }
}
