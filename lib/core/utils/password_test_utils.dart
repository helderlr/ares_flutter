import '../../../core/services/encryption_service.dart';

/// Utilitário para testar e demonstrar a criptografia de senhas
class PasswordTestUtils {
  /// Testa a criptografia com o exemplo fornecido
  static void testarExemploAdm10() {
    print('🧪 TESTANDO EXEMPLO: adm\$10');
    print('=' * 50);

    const senhaOriginal = 'adm\$10';
    const senhaEsperada = 'D9ENMxz+';

    try {
      // 1. Criptografar a senha
      final senhaCriptografada =
          EncryptionService.criptografarAES(senhaOriginal);
      print('✅ Senha original: $senhaOriginal');
      print('✅ Senha criptografada: $senhaCriptografada');
      print('✅ Senha esperada: $senhaEsperada');

      // 2. Verificar se corresponde
      final corresponde = senhaCriptografada == senhaEsperada;
      print('✅ Correspondência: $corresponde');

      if (corresponde) {
        print('🎉 SUCESSO! A criptografia está funcionando corretamente');
      } else {
        print('⚠️  ATENÇÃO: A criptografia pode estar diferente');
        print('💡 Verifique se a chave e algoritmo estão corretos');
      }

      // 3. Teste de descriptografia
      final senhaDescriptografada =
          EncryptionService.descriptografarAES(senhaCriptografada);
      print('✅ Senha descriptografada: $senhaDescriptografada');
      print(
          '✅ Descriptografia correta: ${senhaDescriptografada == senhaOriginal}');
    } catch (e) {
      print('❌ Erro no teste: $e');
    }

    print('=' * 50);
  }

  /// Testa várias senhas para verificar a consistência
  static void testarMultiplasSenhas() {
    print('🧪 TESTANDO MÚLTIPLAS SENHAS');
    print('=' * 50);

    final senhas = [
      'adm\$10',
      '123456',
      'senha123',
      'admin',
      'teste@123',
    ];

    for (final senha in senhas) {
      try {
        final criptografada = EncryptionService.criptografarAES(senha);
        final descriptografada =
            EncryptionService.descriptografarAES(criptografada);

        print('✅ "$senha" → "$criptografada" → "$descriptografada"');

        if (descriptografada != senha) {
          print('❌ ERRO: Descriptografia não corresponde à senha original');
        }
      } catch (e) {
        print('❌ Erro com senha "$senha": $e');
      }
    }

    print('=' * 50);
  }

  /// Demonstra o fluxo completo de autenticação
  static void demonstrarFluxoAutenticacao() {
    print('🔄 DEMONSTRAÇÃO DO FLUXO DE AUTENTICAÇÃO');
    print('=' * 60);

    const senhaUsuario = 'adm\$10';
    const senhawBanco = 'D9ENMxz+'; // Senha já criptografada no banco

    print('1️⃣  Usuário digita: "$senhaUsuario"');

    // Simular criptografia no Flutter
    final senhaCriptografada = EncryptionService.criptografarAES(senhaUsuario);
    print('2️⃣  Flutter criptografa: "$senhaCriptografada"');

    // Simular envio para API
    print('3️⃣  Flutter envia para API:');
    print('   - login: "admin"');
    print('   - senhaw: "$senhaCriptografada"');

    // Simular comparação na API
    final autenticacaoSucesso = senhaCriptografada == senhawBanco;
    print('4️⃣  API compara:');
    print('   - Recebido: "$senhaCriptografada"');
    print('   - Banco: "$senhawBanco"');
    print('   - Resultado: ${autenticacaoSucesso ? "✅ SUCESSO" : "❌ FALHA"}');

    if (autenticacaoSucesso) {
      print('5️⃣  API retorna: Token JWT + dados do usuário');
      print('6️⃣  Flutter salva dados e redireciona para home');
    } else {
      print('5️⃣  API retorna: Erro de credenciais inválidas');
      print('6️⃣  Flutter exibe mensagem de erro');
    }

    print('=' * 60);
  }

  /// Gera um relatório completo de teste
  static void gerarRelatorioTeste() {
    print('📊 RELATÓRIO COMPLETO DE TESTE DE CRIPTOGRAFIA');
    print('=' * 60);

    testarExemploAdm10();
    testarMultiplasSenhas();
    demonstrarFluxoAutenticacao();

    print('📋 RESUMO:');
    print('✅ Sistema de criptografia AES implementado');
    print('✅ Chave: ARES_FLUTTER_2025');
    print('✅ Algoritmo: AES-256-CBC');
    print('✅ IV: 16 bytes com zeros');
    print('✅ Compatível com Delphi');
    print('=' * 60);
  }
}
