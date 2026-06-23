import '../../../core/permissions/user_permissions.dart';

class Convenio {
  final int codcon;
  final String nomcon;
  final String? cnpjcon;
  final String? endcon;
  final String? fonecon;
  final int? codUsu;
  final String? ativo;

  const Convenio({
    required this.codcon,
    required this.nomcon,
    this.cnpjcon,
    this.endcon,
    this.fonecon,
    this.codUsu,
    this.ativo,
  });

  int get id => codcon;
  String get name => nomcon;
  String get cnpj => cnpjcon ?? 'CNPJ não disponível';
  String get address => endcon ?? 'Endereço não disponível';
  String get phone => fonecon ?? 'Telefone não disponível';

  bool canEditByUser(
    int? loggedCodusu, {
    bool isAdmin = false,
    bool isUserActive = true,
  }) {
    return UserPermissions(
      codusu: loggedCodusu,
      isAdmin: isAdmin,
      isActive: isUserActive,
    ).canEditRecord(recordCodusu: codUsu, recordAtivo: ativo);
  }

  factory Convenio.fromJson(Map<String, dynamic> json) {
    final dynamic codigo = json['codcon'] ?? json['codigo'];
    final dynamic nome = json['nomcon'] ?? json['nome'];
    final dynamic cnpj = json['cnpjcon'] ?? json['cgccon'];
    final dynamic endereco = json['endcon'];
    final dynamic telefone = json['fonecon'] ?? json['foncon'];
    return Convenio(
      codcon: codigo is int
          ? codigo
          : (codigo is String ? int.tryParse(codigo) ?? 0 : 0),
      nomcon: nome is String && nome.isNotEmpty
          ? nome
          : 'Convênio ${codigo ?? 'N/A'}',
      cnpjcon: cnpj is String && cnpj.isNotEmpty ? cnpj : null,
      endcon: endereco is String && endereco.isNotEmpty ? endereco : null,
      fonecon: telefone is String && telefone.isNotEmpty ? telefone : null,
      codUsu: _parseCodUsu(json['cod_usu'] ?? json['codusu'] ?? json['COD_USU']),
      ativo: json['ativo']?.toString(),
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
      'codcon': codcon,
      'nomcon': nomcon,
      'cnpjcon': cnpjcon,
      'endcon': endcon,
      'fonecon': fonecon,
      'cod_usu': codUsu,
    };
  }

  Convenio copyWith({
    int? codcon,
    String? nomcon,
    String? cnpjcon,
    String? endcon,
    String? fonecon,
    int? codUsu,
  }) {
    return Convenio(
      codcon: codcon ?? this.codcon,
      nomcon: nomcon ?? this.nomcon,
      cnpjcon: cnpjcon ?? this.cnpjcon,
      endcon: endcon ?? this.endcon,
      fonecon: fonecon ?? this.fonecon,
      codUsu: codUsu ?? this.codUsu,
    );
  }
}

class ConvenioPaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const ConvenioPaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory ConvenioPaginationInfo.fromJson(Map<String, dynamic> json) {
    return ConvenioPaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 50,
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}

class ConvenioPaginatedResponse {
  final List<Convenio> convenios;
  final ConvenioPaginationInfo pagination;

  const ConvenioPaginatedResponse({
    required this.convenios,
    required this.pagination,
  });

  factory ConvenioPaginatedResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data') && json.containsKey('pagination')) {
      final List<dynamic> data = json['data'] ?? [];
      final convenios = data.map((item) => Convenio.fromJson(item)).toList();
      final pagination =
          ConvenioPaginationInfo.fromJson(json['pagination'] ?? {});

      return ConvenioPaginatedResponse(
        convenios: convenios,
        pagination: pagination,
      );
    }

    final List<dynamic> data = json is List ? json as List<dynamic> : [];
    final convenios = data.map((item) => Convenio.fromJson(item)).toList();

    final pagination = ConvenioPaginationInfo(
      currentPage: 1,
      pageSize: 50,
      totalRecords: convenios.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );

    return ConvenioPaginatedResponse(
      convenios: convenios,
      pagination: pagination,
    );
  }

  factory ConvenioPaginatedResponse.fromList(List<dynamic> data) {
    final convenios = data.map((item) => Convenio.fromJson(item)).toList();

    final pagination = ConvenioPaginationInfo(
      currentPage: 1,
      pageSize: 50,
      totalRecords: convenios.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );

    return ConvenioPaginatedResponse(
      convenios: convenios,
      pagination: pagination,
    );
  }
}





























