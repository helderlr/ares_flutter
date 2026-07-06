class PerformanceFormatters {
  static String formatHoursMinutes(int totalMinutes) {
    if (totalMinutes <= 0) {
      return '0h';
    }
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  static String formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }

  static String formatPercent(double value) {
    return '${value.toStringAsFixed(0)}%';
  }

  static String formatMonthLabel(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String formatIsoDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String formatTimeLabel(String hora) {
    if (hora.length >= 5) {
      return hora.substring(0, 5);
    }
    return hora;
  }
}
