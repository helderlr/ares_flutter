class RelatorioFieldLabels {
  static String? snToDisplay(String? apiValue) {
    if (apiValue == null || apiValue.trim().isEmpty) {
      return null;
    }
    final String normalized = apiValue.trim().toUpperCase();
    if (normalized == 'S') {
      return 'Sim';
    }
    if (normalized == 'N') {
      return 'Não';
    }
    return apiValue.trim();
  }

  static String? displayToSn(String? displayValue) {
    if (displayValue == null || displayValue.trim().isEmpty) {
      return null;
    }
    final String normalized = displayValue.trim().toLowerCase();
    if (normalized == 'sim' || normalized == 's') {
      return 'S';
    }
    if (normalized == 'nao' || normalized == 'não' || normalized == 'n') {
      return 'N';
    }
    return displayValue.trim().toUpperCase();
  }

  static String displaySnForPdf(String? apiValue) {
    final String? display = snToDisplay(apiValue);
    if (display == null) {
      return '';
    }
    return display == 'Não' ? 'Nao' : display;
  }

  static String? priRevToDisplay(String? apiValue) {
    if (apiValue == null || apiValue.trim().isEmpty) {
      return null;
    }
    final String normalized = apiValue.trim().toUpperCase();
    if (normalized == 'P') {
      return 'Primaria';
    }
    if (normalized == 'R') {
      return 'Revisao';
    }
    return apiValue.trim();
  }

  static String? displayToPriRev(String? displayValue) {
    if (displayValue == null || displayValue.trim().isEmpty) {
      return null;
    }
    final String normalized = displayValue.trim().toLowerCase();
    if (normalized.startsWith('prim')) {
      return 'P';
    }
    if (normalized.startsWith('rev')) {
      return 'R';
    }
    return displayValue.trim().toUpperCase();
  }

  static String displayPriRevForPdf(String? apiValue) {
    return priRevToDisplay(apiValue) ?? '';
  }

  static String sexoToDisplay(String? apiValue) {
    if (apiValue == null || apiValue.trim().isEmpty) {
      return '';
    }
    final String normalized = apiValue.trim().toUpperCase();
    if (normalized == 'M') {
      return 'Masculino';
    }
    if (normalized == 'F') {
      return 'Feminino';
    }
    return apiValue.trim();
  }

  static String ladoToDisplay(String? apiValue) {
    if (apiValue == null || apiValue.trim().isEmpty) {
      return '';
    }
    switch (apiValue.trim().toUpperCase()) {
      case 'D':
        return 'Direito';
      case 'E':
        return 'Esquerdo';
      case 'A':
        return 'Ambos';
      default:
        return apiValue.trim();
    }
  }
}
