import '../../../core/utils/cnpj_formatter.dart';

class EmpresaModel {
  final String id;
  final String nome;
  final String? cnpj;
  final String? logomarcaUrl;
  final int? codusu;

  const EmpresaModel({
    required this.id,
    required this.nome,
    this.cnpj,
    this.logomarcaUrl,
    this.codusu,
  });

  String get formattedCnpj => CnpjFormatter.format(cnpj);

  String get displayLabel {
    if (formattedCnpj.isNotEmpty) {
      return '$nome • $formattedCnpj';
    }
    return nome;
  }

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    final String? logoRaw = json['logomarcaUrl']?.toString() ??
        json['logomarca']?.toString() ??
        json['logomarca_url']?.toString();
    final String? logo =
        logoRaw != null && logoRaw.trim().isNotEmpty ? logoRaw.trim() : null;
    return EmpresaModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      cnpj: json['cnpj']?.toString(),
      logomarcaUrl: logo,
      codusu: json['codusu'] is int
          ? json['codusu'] as int
          : int.tryParse(json['codusu']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      if (cnpj != null) 'cnpj': cnpj,
      if (logomarcaUrl != null) 'logomarcaUrl': logomarcaUrl,
      if (codusu != null) 'codusu': codusu,
    };
  }

  @override
  String toString() => 'EmpresaModel(id: $id, nome: $nome)';
}
