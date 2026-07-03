class CartaoProteseFieldLabels {
  static const Map<String, String> nacImpLabels = <String, String>{
    'N': 'Nacional',
    'I': 'Importado',
  };

  static const Map<String, String> priRevLabels = <String, String>{
    'P': 'Primaria',
    'R': 'Revisao',
  };

  static const Map<String, String> ladoLabels = <String, String>{
    'D': 'Direito',
    'E': 'Esquerdo',
    'A': 'Ambos',
  };

  static const Map<String, String> tipoProteseLabels = <String, String>{
    '1': 'Quadril',
    '2': 'Joelho',
    '3': 'Ombro',
    '4': 'Outros',
  };

  static String nacImpToDisplay(String? value) {
    if (value == null || value.isEmpty) {
      return '—';
    }
    final String key = value.trim().toUpperCase();
    return nacImpLabels[key] ?? value;
  }

  static String priRevToDisplay(String? value) {
    if (value == null || value.isEmpty) {
      return '—';
    }
    final String key = value.trim().toUpperCase();
    return priRevLabels[key] ?? value;
  }

  static String ladoToDisplay(String? value) {
    if (value == null || value.isEmpty) {
      return '—';
    }
    final String key = value.trim().toUpperCase();
    return ladoLabels[key] ?? value;
  }

  static String tipoProteseToDisplay(String? value) {
    if (value == null || value.isEmpty) {
      return '—';
    }
    final String key = value.trim();
    final String? label = tipoProteseLabels[key];
    if (label != null) {
      return '$key=$label';
    }
    return value;
  }

  static String snToApiDisplay(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }
    return value;
  }
}
