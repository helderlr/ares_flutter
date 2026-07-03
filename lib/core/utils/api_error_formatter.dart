class ApiErrorFormatter {
  static String format(Object error) {
    String message = error.toString();
    if (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }
    final String lower = message.toLowerCase();
    if (lower.contains('token ausente') ||
        lower.contains('token jwt') ||
        lower.contains('token não encontrado')) {
      return 'Sessão sem token. Saia do app e faça login novamente.';
    }
    if (message.contains('<!DOCTYPE html>') || message.contains('<html')) {
      if (message.contains('404')) {
        return 'Endpoint não encontrado (404). Faça login novamente ou '
            'verifique se a API cartao-protese foi deployada no servidor.';
      }
      if (message.contains('502')) {
        return 'Servidor temporariamente indisponível (502).';
      }
      return 'Erro de comunicação com o servidor. Tente novamente mais tarde.';
    }
    if (message.length > 280) {
      return '${message.substring(0, 280)}...';
    }
    return message;
  }
}
