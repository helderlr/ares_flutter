# Ares Flutter

Aplicativo Flutter para gerenciamento de agendamentos de cirurgias.

## 📱 Funcionalidades

- Menu lateral (Drawer) moderno e responsivo
- Cadastro de Paciente, Médico, Tipo Cirurgia, Hospital e Convênio
- Agendamento, Remarcação e Cancelamento de cirurgias
- Listagem e filtros de agendamentos
- Gráficos de agendas por período e filtros
- Gerenciamento de agendamentos futuros e passados
- Registro de horário de cirurgia
- Configuração de parâmetros (ex: URL da API)
- Avaliação do aplicativo (notas e comentários)
- Termos e Condições, Política de Privacidade
- Compartilhamento de agenda via WhatsApp
- Suporte a tema claro/escuro
- Autenticação JWT e proteção de rotas
- Armazenamento local de token (SharedPreferences)
- Organização por módulos/features seguindo arquitetura limpa
- Gerenciamento de estado com Riverpod
- Navegação com AutoRoute
- Paginação híbrida com ordenação alfabética

## 🚀 Como rodar o projeto

1. **Clone o repositório:**
   ```sh
   git clone https://github.com/helderlr/ares_flutter.git
   cd ares_flutter
   ```

2. **Instale as dependências:**
   ```sh
   flutter pub get
   ```

3. **Teste a conectividade da API:**
   ```sh
   dart test_login.dart
   ```

4. **Rode o app:**
   ```sh
   flutter run
   ```

## 🔧 Configuração da API

### Credenciais de Login
- **Usuário:** Administrador
- **Senha:** adm$10
- **URL da API:** https://45.162.242.43
- **Endpoint:** POST /api/Usuario/login

### Estrutura da Requisição de Login
```json
{
  "nomusu": "Administrador",
  "login": "Administrador", 
  "senha": "adm$10"
}
```

### Estrutura da Resposta da API
```json
{
  "user": {
    "codusu": 1,
    "nomusu": null,
    "login": "Administrador",
    "senha": "",
    "senhaw": "",
    "admsis": "S",
    "datcad": null
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Problemas Comuns e Soluções

#### 1. Certificado Auto-Assinado
O servidor usa certificado auto-assinado. O app foi configurado para:
- Aceitar certificados auto-assinados
- Usar HttpClient customizado para HTTPS
- Configurar network security no Android

#### 2. API Não Acessível
Se a API não estiver acessível:
1. Verifique se a API .NET está rodando
2. Verifique se o servidor está acessível na rede
3. Teste acessando https://45.162.242.43/api/Usuario/login
4. Verifique firewall e configurações de rede

#### 3. Token Não Encontrado
Se o login funcionar mas o token não for encontrado:
- O app espera a estrutura: `{"user": {...}, "token": "..."}`
- Verifique a estrutura da resposta da API no Swagger

### Testando a API

Execute o teste de conectividade:
```sh
dart test_login.dart
```

Este teste irá:
- Verificar se o Swagger está acessível
- Testar o endpoint POST /api/Usuario/login
- Aceitar certificados auto-assinados
- Verificar se o token está sendo retornado
- Validar a estrutura da resposta

## 🛠️ Estrutura do Projeto

```
lib/
  core/
    constants/
      app_colors.dart
    theme/
      app_theme.dart
  features/
    login/
      models/
        user_model.dart
      services/
        auth_service.dart
        api_test_service.dart
      presentation/
        login_page.dart
    menu/
      model/
        menu_option.dart
      presentation/
        menu_drawer.dart
    paciente/
      presentation/
        paciente_page.dart
    configuracao/
      presentation/
        configuracao_page.dart
  main.dart
```

## 📦 Principais dependências

- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- [auto_route](https://pub.dev/packages/auto_route)
- [http](https://pub.dev/packages/http)
- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [image_picker](https://pub.dev/packages/image_picker)
- [flutter_localizations](https://docs.flutter.dev/accessibility-and-localization/internationalization)

## 🔍 Debugging

### Logs de Login
O app exibe mensagens detalhadas de erro durante o login:
- Erros de conexão
- Status codes da API
- Mensagens de erro da API
- Problemas com token

### Verificação de Estado
- O app verifica automaticamente se o usuário já está logado
- Salva credenciais se "Me lembre" estiver ativo
- Gerencia tokens JWT automaticamente

## 📝 Observações

- Configure a URL da API nas configurações do app se necessário
- Para gerar rotas automáticas, use:
  ```sh
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- O app usa especificamente o endpoint POST /api/Usuario/login
- Implementa tratamento robusto de erros de rede
- Aceita certificados auto-assinados

## 🚨 Troubleshooting

### Login Não Funciona
1. Execute `dart test_login.dart` para diagnosticar
2. Verifique se a API está rodando
3. Confirme as credenciais: Administrador / adm$10
4. Teste no Swagger UI primeiro

### App Não Conecta
1. Verifique conectividade de rede
2. Confirme URL: https://45.162.242.43
3. Teste ping para o servidor
4. Verifique firewall/proxy

### Token Inválido
1. Verifique se o token está sendo salvo
2. Confirme formato da resposta da API
3. Teste logout e login novamente
4. Limpe dados do app se necessário

## 📊 Paginação e Ordenação

### Paginação Híbrida
- Carregamento inicial de todos os registros
- Paginação local com 15 registros por página
- Scroll infinito para carregar mais dados
- Indicador visual de progresso

### Ordenação
- Ordenação alfabética por padrão
- Menu de ordenação com opções:
  - Por Nome (alfabética)
  - Por Código (numérica)
  - Por Data de Nascimento (cronológica)
- Indicador visual do tipo de ordenação atual

### Pesquisa
- Pesquisa em tempo real
- Filtra por nome e número da carteira
- Mantém ordenação durante a pesquisa
- Reset automático da paginação

## 🔄 Controle de Versão

### Branches
- `main`: Branch principal com código estável
- `develop`: Branch de desenvolvimento
- `feature/*`: Branches para novas funcionalidades

### Commits
- Commits semânticos seguindo convenções
- Mensagens em português
- Descrições detalhadas das mudanças

## 📱 Deploy

### Google Play Store
- Build de release otimizado
- Assinatura com keystore
- Configuração de permissões
- Screenshots e descrições

### Apple App Store
- Build para iOS
- Certificados de distribuição
- Configuração de capabilities
- Review process

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
