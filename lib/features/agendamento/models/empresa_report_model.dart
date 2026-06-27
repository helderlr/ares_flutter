class EmpresaReportData {
  final String nome;
  final String razaoSocial;
  final String nomeFantasia;
  final String? cnpj;
  final String? logomarcaUrl;
  final String endereco;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String cep;
  final String email;
  final String fone;
  final String fax;
  final String site;
  final String ie;
  final String inscricaoMunicipal;
  final String codCnae;
  final String codMunicipio;

  const EmpresaReportData({
    required this.nome,
    this.razaoSocial = '',
    this.nomeFantasia = '',
    this.cnpj,
    this.logomarcaUrl,
    this.endereco = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.uf = '',
    this.cep = '',
    this.email = '',
    this.fone = '',
    this.fax = '',
    this.site = '',
    this.ie = '',
    this.inscricaoMunicipal = '',
    this.codCnae = '',
    this.codMunicipio = '',
  });

  String get displayNome {
    if (nomeFantasia.trim().isNotEmpty) {
      return nomeFantasia.trim();
    }
    if (razaoSocial.trim().isNotEmpty) {
      return razaoSocial.trim();
    }
    return nome.trim();
  }

  String get footerLine1 {
    final String razao = razaoSocial.trim().isNotEmpty
        ? razaoSocial.trim()
        : displayNome;
    if (email.trim().isNotEmpty) {
      return '$razao - ${email.trim()}';
    }
    return razao;
  }

  String get footerLine2 {
    final List<String> parts = <String>[];
    final String enderecoCompleto = _joinNonEmpty(
      <String>[endereco.trim(), numero.trim()],
      ', ',
    );
    if (enderecoCompleto.isNotEmpty) {
      parts.add(enderecoCompleto);
    }
    if (complemento.trim().isNotEmpty) {
      parts.add(complemento.trim());
    }
    if (bairro.trim().isNotEmpty) {
      parts.add(bairro.trim());
    }
    final String cidadeUf = _joinNonEmpty(
      <String>[
        cidade.trim(),
        uf.trim().isNotEmpty ? uf.trim() : '',
      ],
      ' - ',
    );
    if (cidadeUf.isNotEmpty) {
      parts.add(cidadeUf);
    }
    if (cep.trim().isNotEmpty) {
      parts.add('CEP: ${cep.trim()}');
    }
    if (cnpj != null && cnpj!.trim().isNotEmpty) {
      parts.add('CNPJ: ${cnpj!.trim()}');
    }
    if (ie.trim().isNotEmpty) {
      parts.add('IE: ${ie.trim()}');
    }
    if (inscricaoMunicipal.trim().isNotEmpty) {
      parts.add('IM: ${inscricaoMunicipal.trim()}');
    }
    if (fone.trim().isNotEmpty) {
      parts.add('FONE: ${fone.trim()}');
    }
    return parts.join(' - ');
  }

  String _joinNonEmpty(List<String> values, String separator) {
    final List<String> filtered =
        values.where((String value) => value.isNotEmpty).toList();
    return filtered.join(separator);
  }

  factory EmpresaReportData.fromJson(Map<String, dynamic> json) {
    final String fone = json['fone']?.toString() ??
        json['telefone']?.toString() ??
        '';
    final String ie = json['ie']?.toString() ??
        json['inscricaoEstadual']?.toString() ??
        json['inscricao_estadual']?.toString() ??
        '';
    return EmpresaReportData(
      nome: json['nome']?.toString() ?? '',
      razaoSocial: json['razaoSocial']?.toString() ??
          json['razao_social']?.toString() ??
          '',
      nomeFantasia: json['nomeFantasia']?.toString() ??
          json['nome_fantasia']?.toString() ??
          '',
      cnpj: json['cnpj']?.toString(),
      logomarcaUrl: json['logomarcaUrl']?.toString() ??
          json['logomarca']?.toString(),
      endereco: json['endereco']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      complemento: json['complemento']?.toString() ?? '',
      bairro: json['bairro']?.toString() ?? '',
      cidade: json['cidade']?.toString() ?? '',
      uf: json['uf']?.toString() ?? '',
      cep: json['cep']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fone: fone,
      fax: json['fax']?.toString() ?? '',
      site: json['site']?.toString() ?? '',
      ie: ie,
      inscricaoMunicipal: json['inscricaoMunicipal']?.toString() ??
          json['inscricao_municipal']?.toString() ??
          '',
      codCnae: json['codCnae']?.toString() ?? json['cnae']?.toString() ?? '',
      codMunicipio: json['codMunicipio']?.toString() ??
          json['cod_municipio']?.toString() ??
          '',
    );
  }
}
