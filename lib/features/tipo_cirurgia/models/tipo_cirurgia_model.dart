class TipoCirurgia {
  final int codcir;
  final String nomcir;
  final String? descir;
  final double? valcir;
  final int? codUsu;

  const TipoCirurgia({
    required this.codcir,
    required this.nomcir,
    this.descir,
    this.valcir,
    this.codUsu,
  });

  int get id => codcir;
  String get name => nomcir;
  String get description => descir ?? 'Descrição não disponível';
  String get value => valcir != null
      ? 'R\$ ${valcir!.toStringAsFixed(2)}'
      : 'Valor não disponível';

  bool canEditByUser(int? loggedCodusu) {
    if (loggedCodusu == null || codUsu == null) {
      return false;
    }
    return codUsu == loggedCodusu;
  }

  factory TipoCirurgia.fromJson(Map<String, dynamic> json) {
    final dynamic codigo = json['codcir'] ?? json['codigo'];
    final dynamic nome = json['nomcir'] ?? json['nome'];
    final dynamic descricao = json['descir'];
    final dynamic valor = json['valcir'];
    return TipoCirurgia(
      codcir: codigo is int
          ? codigo
          : (codigo is String ? int.tryParse(codigo) ?? 0 : 0),
      nomcir: nome is String && nome.isNotEmpty
          ? nome
          : 'Tipo Cirurgia ${codigo ?? 'N/A'}',
      descir: descricao is String && descricao.isNotEmpty ? descricao : null,
      valcir: valor is double
          ? valor
          : (valor is int
              ? valor.toDouble()
              : (valor is String ? double.tryParse(valor) : null)),
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
      'codcir': codcir,
      'nomcir': nomcir,
      'descir': descir,
      'valcir': valcir,
      'cod_usu': codUsu,
    };
  }

  TipoCirurgia copyWith({
    int? codcir,
    String? nomcir,
    String? descir,
    double? valcir,
    int? codUsu,
  }) {
    return TipoCirurgia(
      codcir: codcir ?? this.codcir,
      nomcir: nomcir ?? this.nomcir,
      descir: descir ?? this.descir,
      valcir: valcir ?? this.valcir,
      codUsu: codUsu ?? this.codUsu,
    );
  }
}

class TipoCirurgiaPaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const TipoCirurgiaPaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory TipoCirurgiaPaginationInfo.fromJson(Map<String, dynamic> json) {
    return TipoCirurgiaPaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 50,
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}

class TipoCirurgiaPaginatedResponse {
  final List<TipoCirurgia> tiposCirurgia;
  final TipoCirurgiaPaginationInfo pagination;

  const TipoCirurgiaPaginatedResponse({
    required this.tiposCirurgia,
    required this.pagination,
  });

  factory TipoCirurgiaPaginatedResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data') && json.containsKey('pagination')) {
      final List<dynamic> data = json['data'] ?? [];
      final tiposCirurgia =
          data.map((item) => TipoCirurgia.fromJson(item)).toList();
      final pagination =
          TipoCirurgiaPaginationInfo.fromJson(json['pagination'] ?? {});

      return TipoCirurgiaPaginatedResponse(
        tiposCirurgia: tiposCirurgia,
        pagination: pagination,
      );
    }

    final List<dynamic> data = json is List ? json as List<dynamic> : [];
    final tiposCirurgia =
        data.map((item) => TipoCirurgia.fromJson(item)).toList();

    final pagination = TipoCirurgiaPaginationInfo(
      currentPage: 1,
      pageSize: 50,
      totalRecords: tiposCirurgia.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );

    return TipoCirurgiaPaginatedResponse(
      tiposCirurgia: tiposCirurgia,
      pagination: pagination,
    );
  }

  factory TipoCirurgiaPaginatedResponse.fromList(List<dynamic> data) {
    final tiposCirurgia =
        data.map((item) => TipoCirurgia.fromJson(item)).toList();

    final pagination = TipoCirurgiaPaginationInfo(
      currentPage: 1,
      pageSize: 50,
      totalRecords: tiposCirurgia.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );

    return TipoCirurgiaPaginatedResponse(
      tiposCirurgia: tiposCirurgia,
      pagination: pagination,
    );
  }
}





























