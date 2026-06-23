class UserPermissions {
  final int? codusu;
  final bool isAdmin;
  final bool isActive;

  const UserPermissions({
    this.codusu,
    this.isAdmin = false,
    this.isActive = true,
  });

  bool get canPerformEdits => isActive;

  bool canEditRecord({
    required int? recordCodusu,
    String? recordAtivo,
  }) {
    if (!isActive) {
      return false;
    }
    if (_isInactiveFlag(recordAtivo)) {
      return false;
    }
    if (isAdmin) {
      return true;
    }
    if (codusu == null || recordCodusu == null) {
      return false;
    }
    return codusu == recordCodusu;
  }

  static bool _isInactiveFlag(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }
    return value.trim().toUpperCase() == 'N';
  }

  static bool parseAdminFlag(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }
    final String normalized = value.trim().toUpperCase();
    return normalized == 'S' || normalized.startsWith('S');
  }

  static bool parseActiveFlag(String? value) {
    if (value == null || value.trim().isEmpty) {
      return true;
    }
    return value.trim().toUpperCase() != 'N';
  }
}
