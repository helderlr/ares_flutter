class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException([
    this.message = 'Sessão expirada. Faça login novamente.',
  ]);

  @override
  String toString() => message;
}
