class PerformanceScoreCalculator {
  static const Map<String, int> operationWeights = <String, int>{
    'consulta': 1,
    'alteracao': 3,
    'alteração': 3,
    'inclusao': 5,
    'inclusão': 5,
    'exclusao': 7,
    'exclusão': 7,
    'relatorio': 2,
    'relatório': 2,
    'fechamento': 15,
    'login': 0,
  };

  static int resolveOperationWeight(String operacao) {
    final String normalized = operacao.trim().toLowerCase();
    return operationWeights[normalized] ?? 1;
  }

  static int calculateScoreFromOperations(
    Map<String, int> operationsByType,
  ) {
    int total = 0;
    operationsByType.forEach((String operacao, int count) {
      total += resolveOperationWeight(operacao) * count;
    });
    return total;
  }

  static int calculateStarCount(int scorePercent) {
    if (scorePercent >= 95) {
      return 5;
    }
    if (scorePercent >= 85) {
      return 4;
    }
    if (scorePercent >= 70) {
      return 3;
    }
    if (scorePercent >= 50) {
      return 2;
    }
    if (scorePercent >= 30) {
      return 1;
    }
    return 0;
  }

  static String resolveLevelLabel(int starCount) {
    switch (starCount) {
      case 5:
        return 'Nível Ouro';
      case 4:
        return 'Nível Prata';
      case 3:
        return 'Nível Bronze';
      default:
        return 'Em evolução';
    }
  }

  static String resolveMedalTier(int position) {
    if (position == 1) {
      return 'ouro';
    }
    if (position == 2) {
      return 'prata';
    }
    if (position == 3) {
      return 'bronze';
    }
    return '';
  }
}
