class CartaoProtese {
  final int codigo;
  final String? paciente;
  final String? medico;
  final String? hospital;
  final String? tipoProtese;
  final String? situacao;
  final DateTime? dataCirurgia;

  const CartaoProtese({
    required this.codigo,
    this.paciente,
    this.medico,
    this.hospital,
    this.tipoProtese,
    this.situacao,
    this.dataCirurgia,
  });

  String get titulo => paciente?.trim().isNotEmpty == true
      ? paciente!.trim()
      : 'Cartao $codigo';

  String get dataCirurgiaDisplay {
    final DateTime? data = dataCirurgia;
    if (data == null) {
      return '—';
    }
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  factory CartaoProtese.fromJson(Map<String, dynamic> json) {
    final dynamic codigo = json['codigo'] ??
        json['nummov'] ??
        json['numcard'] ??
        json['NUMCARD'];
    return CartaoProtese(
      codigo: codigo is int
          ? codigo
          : int.tryParse(codigo?.toString() ?? '') ?? 0,
      paciente: _parseString(
        json['paciente'] ?? json['nompac'] ?? json['pac_nome'],
      ),
      medico: _parseString(json['medico'] ?? json['nommed'] ?? json['med_nome']),
      hospital: _parseString(json['hospital'] ?? json['nomcli'] ?? json['cli_nome']),
      tipoProtese: _parseString(
        json['tipo_protese'] ?? json['tipoprose'] ?? json['descricao'],
      ),
      situacao: _parseString(json['situacao'] ?? json['status']),
      dataCirurgia: _parseDate(json['datcir'] ?? json['data_cirurgia']),
    );
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
    return DateTime.tryParse(value.toString());
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
