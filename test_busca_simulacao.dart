import 'dart:async';

void main() async {
  print('🔍 Testando simulação da busca...\n');

  String currentSearchQuery = '';
  Timer? searchDebounceTimer;

  void onSearchChanged(String newQuery) {
    // Cancela o timer anterior se existir
    searchDebounceTimer?.cancel();

    // Cria um novo timer para debounce
    searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final trimmedQuery = newQuery.trim();
      print('⏰ Timer executado - nova query: "$trimmedQuery"');

      // Sempre executa a busca quando há mudança
      if (trimmedQuery != currentSearchQuery) {
        print('🔍 Busca alterada: "$currentSearchQuery" -> "$trimmedQuery"');
        currentSearchQuery = trimmedQuery;

        print('🔄 Executando busca por: "$trimmedQuery"');
        // Aqui seria a chamada para _loadFirstPage()
      } else {
        print('⚠️ Query não alterada, não executando busca');
      }
    });
  }

  // Simula o usuário digitando
  print('🧪 Simulando digitação do usuário...\n');

  print('1. Usuário digita "A"');
  onSearchChanged('A');

  await Future.delayed(const Duration(milliseconds: 100));

  print('2. Usuário digita "AN"');
  onSearchChanged('AN');

  await Future.delayed(const Duration(milliseconds: 100));

  print('3. Usuário digita "ANT"');
  onSearchChanged('ANT');

  await Future.delayed(const Duration(milliseconds: 100));

  print('4. Usuário digita "ANTO"');
  onSearchChanged('ANTO');

  await Future.delayed(const Duration(milliseconds: 100));

  print('5. Usuário digita "ANTON"');
  onSearchChanged('ANTON');

  await Future.delayed(const Duration(milliseconds: 100));

  print('6. Usuário digita "ANTONI"');
  onSearchChanged('ANTONI');

  await Future.delayed(const Duration(milliseconds: 100));

  print('7. Usuário digita "ANTONIO"');
  onSearchChanged('ANTONIO');

  // Aguarda o timer executar
  print('\n⏳ Aguardando timer executar...');
  await Future.delayed(const Duration(milliseconds: 600));

  print('\n✅ Simulação concluída!');
  print('💡 Verifique se a busca foi executada apenas uma vez com "ANTONIO"');
}
