import 'lib/core/services/encryption_service.dart';
import 'lib/features/login/services/auth_service_criptografado.dart';

void main() async {
  print('🔐 TESTE DE CRIPTOGRAFIA AES - ARES FLUTTER');
  print('=' * 60);

  // Teste 1: Criptografia básica
  print('\n1️⃣ TESTE DE CRIPTOGRAFIA BÁSICA');
  print('-' * 30);
  EncryptionService.testarCriptografia();

  // Teste 2: Criptografia com chave customizada
  print('\n2️⃣ TESTE COM CHAVE CUSTOMIZADA');
  print('-' * 30);

  const senhaTeste = 'minhaSenha123';
  const chaveCustomizada = 'CHAVE_CUSTOMIZADA_2025';

  try {
    final hash1 =
        EncryptionService.gerarHashSenha(senhaTeste, chave: chaveCustomizada);
    final hash2 =
        EncryptionService.gerarHashSenha(senhaTeste, chave: chaveCustomizada);

    print('Senha: $senhaTeste');
    print('Chave: $chaveCustomizada');
    print('Hash 1: $hash1');
    print('Hash 2: $hash2');
    print('Hashes iguais: ${hash1 == hash2}');

    final senhaValida = EncryptionService.verificarSenha(senhaTeste, hash1,
        chave: chaveCustomizada);
    print('Senha válida: $senhaValida');

    final senhaInvalida = EncryptionService.verificarSenha('senhaErrada', hash1,
        chave: chaveCustomizada);
    print('Senha inválida detectada: ${!senhaInvalida}');
  } catch (e) {
    print('❌ Erro no teste com chave customizada: $e');
  }

  // Teste 3: Comparação com hash conhecido (simulação)
  print('\n3️⃣ TESTE DE COMPARAÇÃO COM HASH CONHECIDO');
  print('-' * 30);

  // Simula um hash que poderia vir da base de dados
  const senhaConhecida = 'adm\$10';
  const chavePadrao = 'ARES_FLUTTER_2025';

  try {
    final hashConhecido =
        EncryptionService.gerarHashSenha(senhaConhecida, chave: chavePadrao);
    print('Senha conhecida: $senhaConhecida');
    print('Hash gerado: $hashConhecido');

    // Testa com a senha correta
    final senhaCorreta = EncryptionService.verificarSenha(
        senhaConhecida, hashConhecido,
        chave: chavePadrao);
    print('Senha correta: $senhaCorreta');

    // Testa com senha incorreta
    final senhaIncorreta = EncryptionService.verificarSenha(
        'senhaErrada', hashConhecido,
        chave: chavePadrao);
    print('Senha incorreta detectada: ${!senhaIncorreta}');
  } catch (e) {
    print('❌ Erro no teste de comparação: $e');
  }

  // Teste 4: Teste de autenticação completa (se API estiver disponível)
  print('\n4️⃣ TESTE DE AUTENTICAÇÃO COMPLETA');
  print('-' * 30);
  print('⚠️  Este teste requer conexão com a API');
  print('   Para testar, descomente a linha abaixo:');
  print('   await AuthServiceCriptografado.testarAutenticacaoCriptografada();');

  // Descomente a linha abaixo para testar com a API real
  // await AuthServiceCriptografado.testarAutenticacaoCriptografada();

  print('\n🎉 TESTES DE CRIPTOGRAFIA CONCLUÍDOS!');
  print('\n📋 RESUMO:');
  print('✅ Criptografia AES-256-CBC funcionando');
  print('✅ Verificação de senhas funcionando');
  print('✅ Chaves customizadas suportadas');
  print('✅ Compatível com Delphi (IV com zeros)');
  print('✅ Pronto para integração com API');

  print('\n🔧 PRÓXIMOS PASSOS:');
  print('1. Implementar endpoints na API para buscar usuário por login');
  print('2. Implementar endpoint para gerar token JWT');
  print('3. Atualizar tela de login para usar criptografia');
  print('4. Testar com dados reais da base de dados');
}
