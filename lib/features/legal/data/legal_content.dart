class LegalSection {
  final String title;
  final String body;
  final List<String> bullets;

  const LegalSection({
    required this.title,
    required this.body,
    this.bullets = const [],
  });
}

class LegalContent {
  static const String termsUpdatedAt = 'janeiro de 2026';
  static const String privacyUpdatedAt = 'janeiro de 2026';

  static const List<LegalSection> termsSections = [
    LegalSection(
      title: '1. Aceitação dos Termos',
      body:
          'Ao acessar e usar o Aresia (plataforma DOMINA TECNOLOGIA), você concorda em cumprir e estar vinculado a estes Termos de Uso. Se você não concordar com qualquer parte destes termos, não deve usar nossos serviços.',
    ),
    LegalSection(
      title: '2. Descrição do Serviço',
      body:
          'O Aresia é uma plataforma de gestão que permite aos usuários, entre outras funções:',
      bullets: [
        'Gerenciar múltiplas empresas em um único ambiente',
        'Cadastrar e manter dados cadastrais e operacionais',
        'Controlar usuários e permissões de acesso',
        'Utilizar módulos de operação e relatórios disponibilizados pelo sistema',
        'Configurar parâmetros e preferências da solução',
      ],
    ),
    LegalSection(
      title: '3. Conta do Usuário',
      body:
          'Para usar o sistema, você deve utilizar credenciais válidas e informações precisas. Você é responsável por manter a confidencialidade da senha e por todas as atividades realizadas com sua conta.',
    ),
    LegalSection(
      title: '4. Proteção de Dados',
      body:
          'Os dados tratados na plataforma seguem as práticas descritas na Política de Privacidade. Não compartilhamos informações com terceiros sem base legal ou consentimento quando exigido, salvo obrigação legal.',
    ),
    LegalSection(
      title: '5. Uso Aceitável',
      body: 'Você concorda em não:',
      bullets: [
        'Usar o serviço para atividades ilegais',
        'Tentar acessar contas ou dados de outros usuários sem autorização',
        'Interferir no funcionamento do sistema',
        'Realizar engenharia reversa ou tentar contornar medidas de segurança',
        'Compartilhar credenciais com terceiros não autorizados',
      ],
    ),
    LegalSection(
      title: '6. Limitação de Responsabilidade',
      body:
          'O serviço é fornecido no estado em que se encontra. Não garantimos disponibilidade ininterrupta ou ausência de falhas. Não nos responsabilizamos por perdas diretas ou indiretas decorrentes do uso ou da impossibilidade de uso da plataforma, inclusive decisões tomadas com base em informações exibidas no sistema.',
    ),
    LegalSection(
      title: '7. Modificações',
      body:
          'Reservamo-nos o direito de modificar estes termos. Alterações relevantes poderão ser comunicadas por meios adequados (por exemplo, na própria plataforma ou por e-mail).',
    ),
    LegalSection(
      title: '8. Contato',
      body:
          'Empresa: DOMINA TECNOLOGIA EM SISTEMAS LTDA\n'
          'CNPJ: 33.850.175/0001-47\n'
          'Endereço: Rua Betel, 1475, Itaperi, Fortaleza/CE, CEP: 60714-230\n'
          'Telefone: (85) 99803-7573\n'
          'E-mail: contato@dominati.com.br',
    ),
    LegalSection(
      title: '9. Foro e Lei Aplicável',
      body:
          'Este acordo é regido pela legislação brasileira. Fica eleito o foro da comarca de Fortaleza/CE para dirimir questões oriundas deste instrumento.',
    ),
  ];

  static const List<LegalSection> privacySections = [
    LegalSection(
      title: '1. Informações que coletamos',
      body: 'Coletamos informações quando você utiliza o Aresia, incluindo:',
      bullets: [
        'Dados de cadastro e acesso: nome, e-mail, senha (armazenada de forma protegida), empresa selecionada e vínculos de permissão',
        'Dados inseridos na plataforma: dados cadastrais e operacionais das empresas e módulos utilizados',
        'Dados de uso: interações com a interface, para fins de suporte e melhoria do serviço',
        'Dados técnicos: endereço IP, tipo de navegador e informações de dispositivo quando necessários à segurança',
      ],
    ),
    LegalSection(
      title: '2. Como usamos suas informações',
      body: 'Utilizamos os dados para:',
      bullets: [
        'Autenticar usuários e prestar o serviço contratado',
        'Manter cadastros, permissões e funcionalidades do sistema',
        'Garantir segurança, prevenção a fraudes e continuidade da operação',
        'Cumprir obrigações legais e responder a solicitações de autoridades',
        'Comunicar avisos operacionais relevantes à utilização da plataforma',
      ],
    ),
    LegalSection(
      title: '3. Base legal (LGPD)',
      body: 'Tratamos dados pessoais com fundamento nas hipóteses da Lei 13.709/2018, como:',
      bullets: [
        'Execução de contrato ou procedimentos preliminares: para disponibilizar o acesso ao sistema',
        'Legítimo interesse: segurança, melhoria do serviço e prevenção de abuso, observado o equilíbrio com seus direitos',
        'Obrigação legal ou regulatória, quando aplicável',
        'Consentimento, quando exigido para finalidades específicas',
      ],
    ),
    LegalSection(
      title: '4. Compartilhamento de dados',
      body: 'Não vendemos seus dados pessoais. Podemos compartilhar informações:',
      bullets: [
        'Com seu consentimento, quando necessário',
        'Com prestadores e subcontratados que atuam em nosso nome, sob obrigações de confidencialidade e segurança',
        'Por determinação legal, ordem judicial ou requisição de autoridade competente',
        'Em operações societárias, mediante observância à legislação aplicável',
      ],
    ),
    LegalSection(
      title: '4.1. Transferência internacional',
      body:
          'Caso serviços de infraestrutura ou hospedagem envolvam localização de dados no exterior, adotamos medidas compatíveis com a LGPD e cláusulas contratuais adequadas.',
    ),
    LegalSection(
      title: '5. Segurança',
      body:
          'Empregamos medidas técnicas e organizacionais razoáveis para proteger dados, incluindo controles de acesso e autenticação, proteção em trânsito (HTTPS) e boas práticas de armazenamento e backups.',
    ),
    LegalSection(
      title: '6. Seus direitos (LGPD)',
      body: 'Você pode solicitar, conforme a lei:',
      bullets: [
        'Confirmação de tratamento e acesso aos dados',
        'Correção de dados incompletos ou desatualizados',
        'Anonimização, bloqueio ou eliminação de dados desnecessários ou excessivos',
        'Portabilidade dos dados a outro fornecedor, quando aplicável',
        'Informação sobre compartilhamentos e possíveis consequências da negativa de consentimento',
        'Revogação do consentimento, quando o tratamento depender dele',
      ],
    ),
    LegalSection(
      title: '7. Retenção',
      body:
          'Mantemos dados pelo tempo necessário para cumprir as finalidades descritas, respeitando prazos legais e a resolução de litígios.',
    ),
    LegalSection(
      title: '8. Cookies e tecnologias similares',
      body:
          'Podemos utilizar cookies ou armazenamento local estritamente necessários ao funcionamento da sessão e da autenticação.',
    ),
    LegalSection(
      title: '9. Alterações nesta política',
      body:
          'Podemos atualizar esta Política de Privacidade. Em caso de mudanças relevantes, divulgaremos pela plataforma ou por outros meios adequados.',
    ),
    LegalSection(
      title: '10. Contato — encarregado de dados',
      body:
          'Encarregado: Helder Luis Rocha Andrade\n'
          'E-mail: contato@dominati.com.br (assunto: LGPD — exercício de direitos)\n'
          'Telefone: (85) 98732-9913\n\n'
          'Empresa: DOMINA TECNOLOGIA EM SISTEMAS LTDA\n'
          'CNPJ: 33.850.175/0001-47\n'
          'Endereço: Rua Betel, 1475, Itaperi, Fortaleza/CE, CEP: 60714-230\n'
          'Telefone geral: (85) 99803-7573',
    ),
    LegalSection(
      title: '11. Autoridade Nacional de Proteção de Dados (ANPD)',
      body: 'Você também pode recorrer à ANPD: www.gov.br/anpd',
    ),
    LegalSection(
      title: '12. Foro e lei aplicável',
      body:
          'Esta Política é regida pela legislação brasileira, em especial a LGPD. Fica eleito o foro da comarca de Fortaleza/CE para controvérsias sobre proteção de dados.',
    ),
  ];
}
