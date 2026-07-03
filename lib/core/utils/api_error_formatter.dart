class ApiErrorFormatter {
  static String format(Object error) {
    String message = error.toString();
    if (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }
    if (message.contains('<!DOCTYPE html>') || message.contains('<html')) {
      if (message.contains('404')) {
        return 'Serviço não encontrado (404). O endpoint da API pode não estar disponível.';
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
