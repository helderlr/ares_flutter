import 'package:encrypt/encrypt.dart';
import 'dart:convert';

/// Serviço de criptografia AES para autenticação com a base de dados
class EncryptionService {
  static const String _defaultKey =
      'ARES_FLUTTER_2025'; // Chave padrão para criptografia

  /// Criptografa um texto usando AES-256-CBC
  ///
  /// [texto] - Texto a ser criptografado
  /// [chave] - Chave de criptografia (opcional, usa chave padrão se não fornecida)
  ///
  /// Retorna o texto criptografado em base64
  static String criptografarAES(String texto, {String? chave}) {
    try {
      final key = Key.fromUtf8(_ajustarChave(chave ?? _defaultKey));
      final iv = IV.fromLength(16); // IV com zeros (mesmo que o Delphi usa)

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      final encrypted = encrypter.encrypt(texto, iv: iv);
      return encrypted.base64;
    } catch (e) {
      print('❌ Erro ao criptografar: $e');
      throw Exception('Erro ao criptografar texto: $e');
    }
  }

  /// Descriptografa um texto criptografado em AES-256-CBC
  ///
  /// [textoCriptografado] - Texto criptografado em base64
  /// [chave] - Chave de criptografia (opcional, usa chave padrão se não fornecida)
  ///
  /// Retorna o texto descriptografado
  static String descriptografarAES(String textoCriptografado, {String? chave}) {
    try {
      final key = Key.fromUtf8(_ajustarChave(chave ?? _defaultKey));
      final iv = IV.fromLength(16); // IV com zeros

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final encrypted = Encrypted.fromBase64(textoCriptografado);

      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      print('❌ Erro ao descriptografar: $e');
      throw Exception('Erro ao descriptografar texto: $e');
    }
  }

  /// Ajusta a chave para 32 bytes (AES-256)
  ///
  /// [chave] - Chave original
  ///
  /// Retorna a chave ajustada para 32 bytes
  static String _ajustarChave(String chave) {
    if (chave.length >= 32) {
      return chave.substring(0, 32);
    }
    return chave.padRight(32, '0');
  }

  /// Gera hash da senha para comparação com o campo senhaw da API
  ///
  /// [senha] - Senha em texto plano
  /// [chave] - Chave de criptografia (opcional)
  ///
  /// Retorna a senha criptografada para comparação
  static String gerarHashSenha(String senha, {String? chave}) {
    return criptografarAES(senha, chave: chave);
  }

  /// Verifica se uma senha corresponde ao hash armazenado
  ///
  /// [senha] - Senha em texto plano
  /// [hashArmazenado] - Hash da senha armazenado na base de dados
  /// [chave] - Chave de criptografia (opcional)
  ///
  /// Retorna true se a senha corresponder ao hash
  static bool verificarSenha(String senha, String hashArmazenado,
      {String? chave}) {
    try {
      final hashSenha = gerarHashSenha(senha, chave: chave);
      return hashSenha == hashArmazenado;
    } catch (e) {
      print('❌ Erro ao verificar senha: $e');
      return false;
    }
  }

  /// Testa a funcionalidade de criptografia
  static void testarCriptografia() {
    print('🔐 Testando criptografia AES...');

    const textoTeste = 'senha123';
    const chaveTeste = 'ARES_FLUTTER_2025';

    try {
      // Teste de criptografia
      final criptografado = criptografarAES(textoTeste, chave: chaveTeste);
      print('✅ Texto criptografado: $criptografado');

      // Teste de descriptografia
      final descriptografado =
          descriptografarAES(criptografado, chave: chaveTeste);
      print('✅ Texto descriptografado: $descriptografado');

      // Teste de verificação
      final hashSenha = gerarHashSenha(textoTeste, chave: chaveTeste);
      final senhaValida =
          verificarSenha(textoTeste, hashSenha, chave: chaveTeste);
      print('✅ Verificação de senha: $senhaValida');

      print('🎉 Teste de criptografia concluído com sucesso!');
    } catch (e) {
      print('❌ Erro no teste de criptografia: $e');
    }
  }
}
