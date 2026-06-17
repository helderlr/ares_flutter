class CnpjFormatter {
  static String format(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '';
    }
    final String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) {
      return raw;
    }
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.'
        '${digits.substring(5, 8)}/${digits.substring(8, 12)}-'
        '${digits.substring(12, 14)}';
  }
}
