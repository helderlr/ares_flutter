class AtendimentoMapaHospital {
  final int? codcli;
  final String nome;
  final String endereco;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? cep;
  final int total;

  const AtendimentoMapaHospital({
    required this.codcli,
    required this.nome,
    required this.endereco,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.cep,
    required this.total,
  });

  String get fullAddress {
    final List<String> parts = <String>[];
    if (endereco.isNotEmpty) {
      parts.add(endereco);
    }
    if (bairro != null && bairro!.isNotEmpty) {
      parts.add(bairro!);
    }
    if (cidade != null && cidade!.isNotEmpty) {
      parts.add(cidade!);
    }
    if (estado != null && estado!.isNotEmpty) {
      parts.add(estado!);
    }
    if (cep != null && cep!.isNotEmpty) {
      parts.add(cep!);
    }
    return parts.join(', ');
  }

  factory AtendimentoMapaHospital.fromJson(Map<String, dynamic> json) {
    return AtendimentoMapaHospital(
      codcli: int.tryParse(json['codcli']?.toString() ?? ''),
      nome: json['nome']?.toString() ?? 'Sem hospital',
      endereco: json['endereco']?.toString() ?? '',
      bairro: json['bairro']?.toString(),
      cidade: json['cidade']?.toString(),
      estado: json['estado']?.toString(),
      cep: json['cep']?.toString(),
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
    );
  }
}

class AtendimentoCirurgiaMapaData {
  final List<AtendimentoMapaHospital> hospitais;

  const AtendimentoCirurgiaMapaData({required this.hospitais});

  factory AtendimentoCirurgiaMapaData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['hospitais'] as List<dynamic>? ?? [];
    return AtendimentoCirurgiaMapaData(
      hospitais: raw
          .map(
            (dynamic item) => AtendimentoMapaHospital.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
