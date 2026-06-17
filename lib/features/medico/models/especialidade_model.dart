class Especialidade {
  final int codesp;
  final String nome;

  const Especialidade({
    required this.codesp,
    required this.nome,
  });

  factory Especialidade.fromJson(Map<String, dynamic> json) {
    final dynamic codespRaw =
        json['codesp'] ?? json['codEsp'] ?? json['CODESP'] ?? json['codigo'];
    final dynamic nomeRaw = json['nome'] ??
        json['nomesp'] ??
        json['NOME'] ??
        json['descricao'] ??
        json['descesp'];
    return Especialidade(
      codesp: _parseCodesp(codespRaw),
      nome: nomeRaw?.toString().trim() ?? '',
    );
  }

  static int _parseCodesp(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
