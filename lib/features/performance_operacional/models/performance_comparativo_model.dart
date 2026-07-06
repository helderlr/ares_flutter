class PerformanceComparativoUser {
  final int codusu;
  final String nome;
  final int horasMinutes;
  final int operacoes;
  final int pontuacao;
  final double eficiencia;
  final int ranking;
  final int starCount;

  const PerformanceComparativoUser({
    required this.codusu,
    required this.nome,
    required this.horasMinutes,
    required this.operacoes,
    required this.pontuacao,
    required this.eficiencia,
    required this.ranking,
    required this.starCount,
  });

  factory PerformanceComparativoUser.fromJson(Map<String, dynamic> json) {
    return PerformanceComparativoUser(
      codusu: _parseInt(json['codusu']),
      nome: json['nome']?.toString() ?? '',
      horasMinutes: _parseInt(json['horasMinutes']),
      operacoes: _parseInt(json['operacoes']),
      pontuacao: _parseInt(json['pontuacao']),
      eficiencia: _parseDouble(json['eficiencia']),
      ranking: _parseInt(json['ranking']),
      starCount: _parseInt(json['starCount']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PerformanceComparativoData {
  final PerformanceComparativoUser userA;
  final PerformanceComparativoUser userB;

  const PerformanceComparativoData({
    required this.userA,
    required this.userB,
  });

  factory PerformanceComparativoData.fromJson(Map<String, dynamic> json) {
    return PerformanceComparativoData(
      userA: PerformanceComparativoUser.fromJson(
        json['userA'] as Map<String, dynamic>,
      ),
      userB: PerformanceComparativoUser.fromJson(
        json['userB'] as Map<String, dynamic>,
      ),
    );
  }
}
