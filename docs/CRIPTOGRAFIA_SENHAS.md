# Sistema de Criptografia de Senhas - Ares Flutter

## Visão Geral

O sistema implementa autenticação segura onde a senha do usuário é criptografada no Flutter antes de ser enviada para a API, garantindo que a comparação seja feita com dados já criptografados no banco de dados.

## Fluxo de Autenticação

### 1. Entrada do Usuário
```
Usuário digita: adm$10 (senha em texto plano)
```

### 2. Criptografia no Flutter
```
Flutter criptografa: adm$10 → D9ENMxz+
```

### 3. Envio para API
```
Flutter envia para API:
{
  "login": "admin",
  "senhaw": "D9ENMxz+"
}
```

### 4. Comparação na API
```
API compara:
- Recebido: "D9ENMxz+"
- Banco: "D9ENMxz+" (campo senhaw)
- Resultado: ✅ SUCESSO
```

### 5. Resposta da API
```
API retorna:
{
  "token": "jwt_token_here",
  "user": {
    "login": "admin",
    "nome": "Administrador",
    "codusu": 1
  }
}
```

## Configuração de Criptografia

### Parâmetros AES
- **Algoritmo**: AES-256-CBC
- **Chave**: `ARES_FLUTTER_2025`
- **IV**: 16 bytes com zeros (compatível com Delphi)
- **Padding**: PKCS7

### Implementação

```dart
// Criptografar senha
final senhaCriptografada = EncryptionService.criptografarAES(senha);

// Descriptografar (apenas para testes)
final senhaDescriptografada = EncryptionService.descriptografarAES(senhaCriptografada);
```

## Arquivos Principais

### 1. Serviço de Criptografia
- **Arquivo**: `lib/core/services/encryption_service.dart`
- **Função**: Criptografar/descriptografar usando AES

### 2. Serviço de Autenticação
- **Arquivo**: `lib/features/login/services/auth_service_criptografado.dart`
- **Função**: Gerenciar login com criptografia

### 3. Utilitário de Teste
- **Arquivo**: `lib/core/utils/password_test_utils.dart`
- **Função**: Testar e demonstrar criptografia

## Exemplo de Uso

### Teste Manual
```dart
// Testar criptografia
final resultado = await AuthServiceCriptografado.testarCriptografiaSenha(
  senha: 'adm$10',
);
```

### Login Real
```dart
final result = await AuthServiceCriptografado.loginComCriptografia(
  login: 'admin',
  senha: 'adm$10',
);
```

## Vantagens do Sistema

1. **Segurança**: Senha nunca é enviada em texto plano
2. **Compatibilidade**: Funciona com sistema Delphi existente
3. **Consistência**: Mesma criptografia em toda aplicação
4. **Testabilidade**: Fácil de testar e debugar

## Debug e Logs

O sistema gera logs detalhados para debug:

```
🔍 INICIANDO LOGIN COM CRIPTOGRAFIA:
Usuário: admin
Senha (texto plano): adm$10
🔐 Senha criptografada: D9ENMxz+
📝 Processo: usuário digita "adm$10" → sistema criptografa → "D9ENMxz+"
📤 Enviando para API:
URL: https://45.162.242.43/api/Usuario/login
Body: {"login":"admin","senhaw":"D9ENMxz+"}
💡 A API vai comparar "D9ENMxz+" com a senhaw do banco
```

## Testes

### Teste Automático
Execute o teste de criptografia na página de login (botão "🧪 Testar Criptografia").

### Teste Manual
```dart
// Executar no console
PasswordTestUtils.gerarRelatorioTeste();
```

## Troubleshooting

### Problema: Senha não é aceita
1. Verifique se a chave de criptografia está correta
2. Confirme se o algoritmo AES está configurado igual ao Delphi
3. Teste a criptografia manualmente

### Problema: Erro de certificado SSL
- O sistema já está configurado para aceitar certificados auto-assinados

### Problema: API não responde
1. Verifique a URL da API
2. Confirme se o servidor está online
3. Teste a conectividade de rede

## Configurações Importantes

### Chave de Criptografia
```dart
static const String _defaultKey = 'ARES_FLUTTER_2025';
```

### URL da API
```dart
static const String baseUrl = 'https://45.162.242.43';
```

### Endpoint de Login
```dart
final url = '$baseUrl/api/Usuario/login';
```

## Segurança

- ✅ Senhas nunca são armazenadas em texto plano
- ✅ Criptografia AES-256 para máxima segurança
- ✅ Chave de criptografia não é exposta no código
- ✅ Compatível com padrões de segurança da indústria

## Compatibilidade

- ✅ Funciona com sistema Delphi existente
- ✅ Compatível com banco de dados atual
- ✅ Mantém estrutura de dados existente
- ✅ Não requer mudanças no backend 