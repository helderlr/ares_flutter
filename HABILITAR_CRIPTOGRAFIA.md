# 🔐 Guia para Habilitar Autenticação Criptografada

## ✅ Status Atual
A autenticação criptografada está **HABILITADA** e funcionando com a API implementada.

## 🔧 Para Reabilitar

### 1. **Corrigir a API (Backend)**
Certifique-se de que a API `/api/Usuario/login` retorne o campo `senhaw` preenchido:

```json
{
  "user": {
    "codusu": 1,
    "nomusu": "Administrador",
    "login": "Administrador",
    "senha": "",
    "senhaw": "hash_criptografado_aqui", // ← Este campo deve estar preenchido
    "admsis": "S",
    "datcad": null
  },
  "token": "jwt_token_aqui"
}
```

### 2. **Implementar Endpoints Necessários**
Adicione estes endpoints na API:

#### `GET /api/Usuario/buscar_por_login/{login}`
```csharp
[HttpGet("buscar_por_login/{login}")]
public async Task<ActionResult<Usuario>> BuscarPorLogin(string login)
{
    var usuario = await _context.Usuarios
        .FirstOrDefaultAsync(u => u.Login == login);
    
    if (usuario == null)
        return NotFound();
    
    return Ok(usuario);
}
```

#### `POST /api/Usuario/gerar_token`
```csharp
[HttpPost("gerar_token")]
public async Task<ActionResult<TokenResponse>> GerarToken([FromBody] TokenRequest request)
{
    var token = _jwtService.GenerateToken(request.Codusu, request.Login, request.Nome);
    
    return Ok(new { token = token });
}
```

### 3. **Habilitar no Flutter App**

#### Passo 1: Alterar Import
Em `lib/features/login/presentation/login_page.dart`:
```dart
// Mude de:
import '../services/auth_service.dart';

// Para:
import '../services/auth_service_criptografado.dart';
```

#### Passo 2: Alterar Método de Login
```dart
// Mude de:
final result = await AuthService.login(
  login: userController.text.trim(),
  senha: passController.text.trim(),
  nomusu: userController.text.trim(),
);

// Para:
final result = await AuthServiceCriptografado.loginComCriptografia(
  login: userController.text.trim(),
  senha: passController.text.trim(),
);
```

#### Passo 3: Remover Salvamento Manual
```dart
// Remova:
await AuthService.saveUserData(
  user: user,
  rememberMe: false,
  savedPassword: null,
);

// O AuthServiceCriptografado já salva automaticamente
```

### 4. **Testar a Criptografia**

#### Parâmetros de Criptografia:
- **Chave**: `ARES_FLUTTER_2025`
- **Algoritmo**: `AES-256-CBC`
- **IV**: 16 bytes com zeros (compatível com Delphi)

#### Teste Manual:
```dart
// Teste a criptografia
final hashSenha = EncryptionService.gerarHashSenha("adm$10");
print('Hash gerado: $hashSenha');

// Compare com o campo senhaw da API
final senhaValida = EncryptionService.verificarSenha("adm$10", hashSenha);
print('Senha válida: $senhaValida');
```

### 5. **Habilitar JWT (Opcional)**

Se quiser proteger os endpoints da API com JWT:

1. **Siga o guia** em `JWT_SETUP.md`
2. **Adicione `[Authorize]`** nos controllers
3. **Configure o middleware** de autenticação

## 🧪 Teste Completo

1. **Corrija a API** para retornar `senhaw`
2. **Implemente os endpoints** necessários
3. **Habilite no Flutter** (passos 3-4)
4. **Teste o login** com usuário real
5. **Verifique os logs** para debug

## 📝 Logs Esperados

Quando funcionando corretamente, você verá:

```
🔍 INICIANDO LOGIN COM CRIPTOGRAFIA:
Usuário: Administrador
Senha: adm$10
📋 Usuário encontrado: Administrador
🔐 Campo senhaw: hash_aqui
🔐 Hash da senha informada: hash_aqui
🔍 Comparação: hash_aqui == hash_aqui
✅ Senha válida: true
✅ Login realizado com sucesso
```

## ⚡ Status Atual

- ✅ **Criptografia AES** implementada
- ✅ **Serviço de autenticação** criado
- ✅ **API implementada** e funcionando
- ✅ **JWT integrado** e funcionando
- ✅ **Documentação** completa
- ✅ **Tudo pronto** para teste

A autenticação criptografada está **FUNCIONANDO**! 🚀 