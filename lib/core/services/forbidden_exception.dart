class ForbiddenException implements Exception {
  final String message;

  const ForbiddenException([
    this.message = 'Empresa não autorizada. Selecione outra empresa ou faça login novamente.',
  ]);

  @override
  String toString() => message;
}
