class CartaoProtese {
  final int nummov;
  final DateTime? datcir;
  final int? codpac;
  final String? nacImp;
  final String? lado;
  final String? priRev;
  final int? codmed;
  final DateTime? datmov;
  final int? codcli;
  final String? tipo;
  final int? numreq;
  final int? nrelcir;
  final String? sistemaAplicado;
  final int? codusu;
  final String? horlan;
  final int? numpedv;
  final int? codcir;
  final String? nnompac;
  final String? nnomcli;
  final String? nnommed;
  final String? nnomfab;
  final String? nomcirTipo;
  final String? crmMedico;
  final DateTime? createdAt;

  const CartaoProtese({
    required this.nummov,
    this.datcir,
    this.codpac,
    this.nacImp,
    this.lado,
    this.priRev,
    this.codmed,
    this.datmov,
    this.codcli,
    this.tipo,
    this.numreq,
    this.nrelcir,
    this.sistemaAplicado,
    this.codusu,
    this.horlan,
    this.numpedv,
    this.codcir,
    this.nnompac,
    this.nnomcli,
    this.nnommed,
    this.nnomfab,
    this.nomcirTipo,
    this.crmMedico,
    this.createdAt,
  });

  String get pacienteName => nnompac?.trim().isNotEmpty == true
      ? nnompac!.trim()
      : 'Paciente não informado';

  String get medicoName => nnommed?.trim().isNotEmpty == true
      ? nnommed!.trim()
      : 'Médico não informado';

  String get hospitalName => nnomcli?.trim().isNotEmpty == true
      ? nnomcli!.trim()
      : 'Hospital não informado';

  String get tipoCirurgiaName => nomcirTipo?.trim().isNotEmpty == true
      ? nomcirTipo!.trim()
      : (codcir != null ? 'Cód. $codcir' : 'Tipo não informado');

  String get dataCirurgiaDisplay => _formatDate(datcir);

  String get dataEmissaoDisplay => _formatDate(datmov);

  String get horaEmissaoDisplay {
    final String? hora = horlan?.trim();
    if (hora == null || hora.isEmpty) {
      return '—';
    }
    return hora.length >= 5 ? hora.substring(0, 5) : hora;
  }

  String get componentesDisplay =>
      sistemaAplicado?.trim().isNotEmpty == true
          ? sistemaAplicado!.trim()
          : '—';

  factory CartaoProtese.fromJson(Map<String, dynamic> json) {
    return CartaoProtese(
      nummov: _parseInt(json['nummov']) ?? 0,
      datcir: _parseDate(json['datcir']),
      codpac: _parseInt(json['codpac']),
      nacImp: _parseString(json['nac_imp'] ?? json['nacImp']),
      lado: _parseString(json['lado']),
      priRev: _parseString(json['pri_rev'] ?? json['priRev']),
      codmed: _parseInt(json['codmed']),
      datmov: _parseDate(json['datmov']),
      codcli: _parseInt(json['codcli']),
      tipo: _parseString(json['tipo']),
      numreq: _parseInt(json['numreq']),
      nrelcir: _parseInt(json['nrelcir']),
      sistemaAplicado: _parseString(
        json['sistema_aplicado'] ?? json['sistemaAplicado'],
      ),
      codusu: _parseInt(json['codusu']),
      horlan: _parseString(json['horlan']),
      numpedv: _parseInt(json['numpedv']),
      codcir: _parseInt(json['codcir']),
      nnompac: _parseString(json['nnompac'] ?? json['pac_nome']),
      nnomcli: _parseString(json['nnomcli'] ?? json['cli_nome']),
      nnommed: _parseString(json['nnommed'] ?? json['med_nome']),
      nnomfab: _parseString(json['nnomfab']),
      nomcirTipo: _parseString(
        json['nomcir_tipo'] ?? json['tipo_cir_nome'] ?? json['nomcir_'],
      ),
      crmMedico: _parseString(json['crm_med'] ?? json['crm']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toWriteJson() {
    return <String, dynamic>{
      if (datcir != null) 'datcir': _toApiDate(datcir!),
      if (codpac != null) 'codpac': codpac,
      if (nacImp != null) 'nac_imp': nacImp,
      if (lado != null && lado!.isNotEmpty) 'lado': lado,
      if (priRev != null) 'pri_rev': priRev,
      if (codmed != null) 'codmed': codmed,
      if (datmov != null) 'datmov': _toApiDate(datmov!),
      if (codcli != null) 'codcli': codcli,
      if (tipo != null && tipo!.isNotEmpty) 'tipo': tipo,
      if (numreq != null) 'numreq': numreq,
      if (nrelcir != null) 'nrelcir': nrelcir,
      if (sistemaAplicado != null) 'sistema_aplicado': sistemaAplicado,
      if (codusu != null) 'codusu': codusu,
      if (horlan != null) 'horlan': horlan,
      if (numpedv != null) 'numpedv': numpedv,
      if (codcir != null) 'codcir': codcir,
      if (nnompac != null) 'nnompac': nnompac,
      if (nnomcli != null) 'nnomcli': nnomcli,
      if (nnommed != null) 'nnommed': nnommed,
      if (nnomfab != null) 'nnomfab': nnomfab,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static String? _parseString(dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    final String text = value.toString();
    if (text.length >= 10) {
      return DateTime.tryParse(text.substring(0, 10));
    }
    return DateTime.tryParse(text);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value.toString());
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return '—';
    }
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String _toApiDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class CartaoProtesePaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;

  const CartaoProtesePaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
  });

  bool get hasNextPage => currentPage < totalPages;

  factory CartaoProtesePaginationInfo.fromJson(Map<String, dynamic> json) {
    return CartaoProtesePaginationInfo(
      currentPage: json['currentPage'] as int? ?? json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 50,
      totalRecords: json['totalRecords'] as int? ?? json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}

class CartaoProtesePaginatedResponse {
  final List<CartaoProtese> itens;
  final CartaoProtesePaginationInfo pagination;

  const CartaoProtesePaginatedResponse({
    required this.itens,
    required this.pagination,
  });
}
