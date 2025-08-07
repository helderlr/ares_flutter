# 🔐 Configuração JWT na API ASP.NET Core

## 📋 Pré-requisitos

Para habilitar a autenticação JWT na API, você precisa implementar os seguintes endpoints:

### 1. **GET /api/Usuario/buscar_por_login/{login}**
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

### 2. **POST /api/Usuario/gerar_token**
```csharp
[HttpPost("gerar_token")]
public async Task<ActionResult<TokenResponse>> GerarToken([FromBody] TokenRequest request)
{
    var token = _jwtService.GenerateToken(request.Codusu, request.Login, request.Nome);
    
    return Ok(new { token = token });
}
```

## 🔧 Configuração no Startup.cs

### 1. **Adicionar JWT Authentication**
```csharp
public void ConfigureServices(IServiceCollection services)
{
    // JWT Configuration
    services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = "AlgumIssuer",
                ValidAudience = "AlgumaAudience",
                IssuerSigningKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes("SuaChaveSecretaAqui12345678901234567890")
                )
            };
        });

    services.AddAuthorization();
}
```

### 2. **Configurar Middleware**
```csharp
public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    // ... outros middlewares
    
    app.UseAuthentication();
    app.UseAuthorization();
    
    // ... resto da configuração
}
```

## 🛡️ Proteger Controllers

### 1. **Adicionar [Authorize] nos Controllers**
```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize] // Adicionar esta linha
public class PacienteController : ControllerBase
{
    // ... métodos do controller
}
```

### 2. **Exemplo de Controller Protegido**
```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PacienteController : ControllerBase
{
    [HttpGet("paginated")]
    public async Task<ActionResult<IEnumerable<Paciente>>> GetPaginated(
        [FromQuery] string? NOMPAC,
        [FromQuery] int PageNumber = 1,
        [FromQuery] int PageSize = 50,
        [FromQuery] string? OrderBy = "nompac asc")
    {
        // Sua lógica de paginação aqui
        // O JWT já foi validado automaticamente
    }
}
```

## 🔑 Configuração do JWT Service

### 1. **Criar IJwtService**
```csharp
public interface IJwtService
{
    string GenerateToken(int codusu, string login, string nome);
    bool ValidateToken(string token);
}
```

### 2. **Implementar JwtService**
```csharp
public class JwtService : IJwtService
{
    private readonly IConfiguration _configuration;

    public JwtService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string GenerateToken(int codusu, string login, string nome)
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, codusu.ToString()),
            new Claim(ClaimTypes.Name, login),
            new Claim("nome", nome),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        };

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes("SuaChaveSecretaAqui12345678901234567890")
        );
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: "AlgumIssuer",
            audience: "AlgumaAudience",
            claims: claims,
            expires: DateTime.Now.AddHours(24),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public bool ValidateToken(string token)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.UTF8.GetBytes("SuaChaveSecretaAqui12345678901234567890");
        
        try
        {
            tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = "AlgumIssuer",
                ValidateAudience = true,
                ValidAudience = "AlgumaAudience",
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            }, out SecurityToken validatedToken);

            return true;
        }
        catch
        {
            return false;
        }
    }
}
```

### 3. **Registrar o Serviço**
```csharp
public void ConfigureServices(IServiceCollection services)
{
    // ... outras configurações
    
    services.AddScoped<IJwtService, JwtService>();
}
```

## 📦 Pacotes NuGet Necessários

```xml
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="6.0.0" />
<PackageReference Include="System.IdentityModel.Tokens.Jwt" Version="6.0.0" />
```

## 🔄 Fluxo de Autenticação

1. **Cliente faz login** → `/api/Usuario/login` (sem JWT)
2. **API retorna token** → JWT válido
3. **Cliente usa token** → `Authorization: Bearer {token}`
4. **API valida token** → Automaticamente pelo middleware
5. **Acesso permitido** → Se token válido

## ⚠️ Importante

- **Chave secreta**: Use uma chave forte e mantenha segura
- **Issuer/Audience**: Configure valores únicos para sua aplicação
- **Expiração**: Configure tempo de expiração adequado
- **HTTPS**: Sempre use HTTPS em produção

## 🧪 Teste

Após implementar, teste com:

```bash
# 1. Login para obter token
curl -X POST "https://sua-api.com/api/Usuario/login" \
  -H "Content-Type: application/json" \
  -d '{"login":"Administrador","senha":"adm$10"}'

# 2. Usar token para acessar endpoint protegido
curl -X GET "https://sua-api.com/api/Paciente/paginated" \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
``` 