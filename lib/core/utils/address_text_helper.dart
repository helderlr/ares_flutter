class AddressTextHelper {
  static const Map<String, String> _brazilianStateNames = <String, String>{
    'AC': 'Acre',
    'AL': 'Alagoas',
    'AP': 'Amapá',
    'AM': 'Amazonas',
    'BA': 'Bahia',
    'CE': 'Ceará',
    'DF': 'Distrito Federal',
    'ES': 'Espírito Santo',
    'GO': 'Goiás',
    'MA': 'Maranhão',
    'MT': 'Mato Grosso',
    'MS': 'Mato Grosso do Sul',
    'MG': 'Minas Gerais',
    'PA': 'Pará',
    'PB': 'Paraíba',
    'PR': 'Paraná',
    'PE': 'Pernambuco',
    'PI': 'Piauí',
    'RJ': 'Rio de Janeiro',
    'RN': 'Rio Grande do Norte',
    'RS': 'Rio Grande do Sul',
    'RO': 'Rondônia',
    'RR': 'Roraima',
    'SC': 'Santa Catarina',
    'SP': 'São Paulo',
    'SE': 'Sergipe',
    'TO': 'Tocantins',
  };

  static String normalize(String value) {
    String text = value.trim();
    if (text.isEmpty) {
      return text;
    }
    text = text.replaceAll('\uFFFD', '');
    text = text.replaceAll(RegExp(r'Cear[^,\s]*'), 'Ceará');
    for (final MapEntry<String, String> entry in _brazilianStateNames.entries) {
      final RegExp ufPattern = RegExp('\\b${entry.key}\\b');
      if (ufPattern.hasMatch(text)) {
        continue;
      }
      final String broken = entry.value
          .substring(0, entry.value.length - 1)
          .replaceAll('á', 'a')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ã', 'a');
      if (broken.isNotEmpty) {
        text = text.replaceAll(RegExp('$broken\\W*'), '${entry.value}, ');
      }
    }
    text = text.replaceAll(RegExp(r',\s*,'), ',');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    if (text.endsWith(',')) {
      text = text.substring(0, text.length - 1);
    }
    return text.trim();
  }

  static String formatPlacemarkPart({
    required String? street,
    required String? subLocality,
    required String? locality,
    required String? administrativeArea,
  }) {
    final String stateLabel = _resolveStateLabel(administrativeArea);
    final List<String> parts = <String>[
      street ?? '',
      subLocality ?? '',
      locality ?? '',
      stateLabel,
    ].where((String part) => part.trim().isNotEmpty).toList();
    return normalize(parts.join(', '));
  }

  static String _resolveStateLabel(String? administrativeArea) {
    final String raw = administrativeArea?.trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }
    final String upper = raw.toUpperCase();
    if (_brazilianStateNames.containsKey(upper)) {
      return _brazilianStateNames[upper]!;
    }
    return normalize(raw);
  }
}
