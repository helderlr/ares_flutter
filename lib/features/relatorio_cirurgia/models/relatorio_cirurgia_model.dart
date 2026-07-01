class RelatorioCirurgia {
  final int nummov;
  final String? historico;
  final int? numreq;
  final String? hrini;
  final String? hrfin;
  final DateTime? datmov;
  final DateTime? datcir;
  final int? nagecir;
  final String? lado;
  final String? priRev;
  final String? sexo;
  final int? idade;
  final int? codpac;
  final int? codins;
  final String? inshos;
  final String? sistemaAplicado;
  final String? problema;
  final String? obsEstoque;
  final String? obsGerencia;
  final int? codusu;
  final int? codcir;
  final String? nomcir;
  final int? codusuEst;
  final int? codusuGerencia;
  final int? codcli;
  final String? nprontuario;
  final String? cirhos;
  final int? codmed;
  final int? codconv;
  final String? grau;
  final String? status;
  final int? codlev;
  final int? codtro;
  final String? sistema;
  final String? tipo;
  final String? relProb;
  final String? relConta;
  final int? circod;
  final int? numrel;
  final String? urgencia;
  final String? geraut;
  final DateTime? datmod;
  final int? usulan;
  final String? obsRt;
  final String? medidaTomadaEstoque;
  final int? codusuRt;
  final String? problemaRetornoMat;
  final String? problemaImp;
  final String? satisfacaoMatHospital;
  final String? satisfacaoInstHospital;
  final String? satisfacaoMatCirurg;
  final String? satisfacaoInstCirurg;
  final String? pacNome;
  final String? medNome;
  final String? cliNome;
  final String? convNome;
  final String? tipoCirNome;
  final String? enderecoInicio;
  final String? enderecoFim;
  final String? deviceId;

  const RelatorioCirurgia({
    required this.nummov,
    this.historico,
    this.numreq,
    this.hrini,
    this.hrfin,
    this.datmov,
    this.datcir,
    this.nagecir,
    this.lado,
    this.priRev,
    this.sexo,
    this.idade,
    this.codpac,
    this.codins,
    this.inshos,
    this.sistemaAplicado,
    this.problema,
    this.obsEstoque,
    this.obsGerencia,
    this.codusu,
    this.codcir,
    this.nomcir,
    this.codusuEst,
    this.codusuGerencia,
    this.codcli,
    this.nprontuario,
    this.cirhos,
    this.codmed,
    this.codconv,
    this.grau,
    this.status,
    this.codlev,
    this.codtro,
    this.sistema,
    this.tipo,
    this.relProb,
    this.relConta,
    this.circod,
    this.numrel,
    this.urgencia,
    this.geraut,
    this.datmod,
    this.usulan,
    this.obsRt,
    this.medidaTomadaEstoque,
    this.codusuRt,
    this.problemaRetornoMat,
    this.problemaImp,
    this.satisfacaoMatHospital,
    this.satisfacaoInstHospital,
    this.satisfacaoMatCirurg,
    this.satisfacaoInstCirurg,
    this.pacNome,
    this.medNome,
    this.cliNome,
    this.convNome,
    this.tipoCirNome,
    this.enderecoInicio,
    this.enderecoFim,
    this.deviceId,
  });

  int get id => nummov;
  String get pacienteName => pacNome ?? 'Paciente não informado';
  String get medicoName => medNome ?? 'Médico não informado';
  String get hospitalName => cliNome ?? 'Hospital não informado';
  String get convenioName => convNome ?? 'Convênio não informado';
  String get dataCirurgiaDisplay => _formatDate(datcir);
  String get dataEmissaoDisplay => _formatDate(datmov);

  static String _formatDate(DateTime? value) {
    if (value == null) {
      return '—';
    }
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    final String text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    final DateTime? iso = DateTime.tryParse(text);
    if (iso != null) {
      return iso;
    }
    final RegExp br = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})');
    final Match? m = br.firstMatch(text);
    if (m != null) {
      return DateTime(
        int.parse(m.group(3)!),
        int.parse(m.group(2)!),
        int.parse(m.group(1)!),
      );
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static String? _parseString(dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  factory RelatorioCirurgia.fromJson(Map<String, dynamic> json) {
    return RelatorioCirurgia(
      nummov: _parseInt(json['nummov']) ?? 0,
      historico: _parseString(json['historico']),
      numreq: _parseInt(json['numreq']),
      hrini: _parseString(json['hrini']),
      hrfin: _parseString(json['hrfin']),
      datmov: _parseDate(json['datmov']),
      datcir: _parseDate(json['datcir']),
      nagecir: _parseInt(json['nagecir']),
      lado: _parseString(json['lado']),
      priRev: _parseString(json['pri_rev']),
      sexo: _parseString(json['sexo']),
      idade: _parseInt(json['idade']),
      codpac: _parseInt(json['codpac']),
      codins: _parseInt(json['codins']),
      inshos: _parseString(json['inshos']),
      sistemaAplicado: _parseString(json['sistema_aplicado']),
      problema: _parseString(json['problema']),
      obsEstoque: _parseString(json['obs_estoque']),
      obsGerencia: _parseString(json['obs_gerencia']),
      codusu: _parseInt(json['codusu']),
      codcir: _parseInt(json['codcir']),
      nomcir: _parseString(json['nomcir']),
      codusuEst: _parseInt(json['codusu_est']),
      codusuGerencia: _parseInt(json['codusu_gerencia']),
      codcli: _parseInt(json['codcli']),
      nprontuario: _parseString(json['nprontuario']),
      cirhos: _parseString(json['cirhos']),
      codmed: _parseInt(json['codmed']),
      codconv: _parseInt(json['codconv']),
      grau: _parseString(json['grau']),
      status: _parseString(json['status']),
      codlev: _parseInt(json['codlev']),
      codtro: _parseInt(json['codtro']),
      sistema: _parseString(json['sistema']),
      tipo: _parseString(json['tipo']),
      relProb: _parseString(json['rel_prob']),
      relConta: _parseString(json['rel_conta']),
      circod: _parseInt(json['circod']),
      numrel: _parseInt(json['numrel']),
      urgencia: _parseString(json['urgencia']),
      geraut: _parseString(json['geraut']),
      datmod: _parseDate(json['datmod']),
      usulan: _parseInt(json['usulan']),
      obsRt: _parseString(json['obs_rt']),
      medidaTomadaEstoque: _parseString(json['medida_tomada_estoque']),
      codusuRt: _parseInt(json['codusu_rt']),
      problemaRetornoMat: _parseString(json['problema_retorno_mat']),
      problemaImp: _parseString(json['problema_imp']),
      satisfacaoMatHospital: _parseString(json['satisfacao_mat_hospital']),
      satisfacaoInstHospital: _parseString(json['satisfacao_inst_hospital']),
      satisfacaoMatCirurg: _parseString(json['satisfacao_mat_cirurg']),
      satisfacaoInstCirurg: _parseString(json['satisfacao_inst_cirurg']),
      pacNome: _parseString(json['pac_nome']),
      medNome: _parseString(json['med_nome']),
      cliNome: _parseString(json['cli_nome']),
      convNome: _parseString(json['conv_nome']),
      tipoCirNome: _parseString(json['tipo_cir_nome']),
      enderecoInicio: _parseString(json['endereco_inicio']),
      enderecoFim: _parseString(json['endereco_fim']),
      deviceId: _parseString(json['device_id']),
    );
  }

  Map<String, dynamic> toWriteJson() {
    return <String, dynamic>{
      if (historico != null) 'historico': historico,
      if (numreq != null) 'numreq': numreq,
      if (hrini != null) 'hrini': hrini,
      if (hrfin != null) 'hrfin': hrfin,
      if (datmov != null) 'datmov': _toApiDate(datmov!),
      if (datcir != null) 'datcir': _toApiDate(datcir!),
      if (nagecir != null) 'nagecir': nagecir,
      if (lado != null) 'lado': lado,
      if (priRev != null) 'pri_rev': priRev,
      if (sexo != null) 'sexo': sexo,
      if (idade != null) 'idade': idade,
      if (codpac != null) 'codpac': codpac,
      if (codins != null) 'codins': codins,
      if (inshos != null) 'inshos': inshos,
      if (sistemaAplicado != null) 'sistema_aplicado': sistemaAplicado,
      if (problema != null) 'problema': problema,
      if (obsEstoque != null) 'obs_estoque': obsEstoque,
      if (obsGerencia != null) 'obs_gerencia': obsGerencia,
      if (codusu != null) 'codusu': codusu,
      if (codcir != null) 'codcir': codcir,
      if (nomcir != null) 'nomcir': nomcir,
      if (codcli != null) 'codcli': codcli,
      if (nprontuario != null) 'nprontuario': nprontuario,
      if (cirhos != null) 'cirhos': cirhos,
      if (codmed != null) 'codmed': codmed,
      if (codconv != null) 'codconv': codconv,
      if (grau != null) 'grau': grau,
      if (status != null) 'status': status,
      if (codlev != null) 'codlev': codlev,
      if (codtro != null) 'codtro': codtro,
      if (sistema != null) 'sistema': sistema,
      if (tipo != null) 'tipo': tipo,
      if (relProb != null) 'rel_prob': relProb,
      if (relConta != null) 'rel_conta': relConta,
      if (circod != null) 'circod': circod,
      if (numrel != null) 'numrel': numrel,
      if (urgencia != null) 'urgencia': urgencia,
      if (geraut != null) 'geraut': geraut,
      if (usulan != null) 'usulan': usulan,
      if (obsRt != null) 'obs_rt': obsRt,
      if (medidaTomadaEstoque != null) 'medida_tomada_estoque': medidaTomadaEstoque,
      if (problemaRetornoMat != null) 'problema_retorno_mat': problemaRetornoMat,
      if (problemaImp != null) 'problema_imp': problemaImp,
      if (satisfacaoMatHospital != null) 'satisfacao_mat_hospital': satisfacaoMatHospital,
      if (satisfacaoInstHospital != null) 'satisfacao_inst_hospital': satisfacaoInstHospital,
      if (satisfacaoMatCirurg != null) 'satisfacao_mat_cirurg': satisfacaoMatCirurg,
      if (satisfacaoInstCirurg != null) 'satisfacao_inst_cirurg': satisfacaoInstCirurg,
      if (enderecoInicio != null) 'endereco_inicio': enderecoInicio,
      if (enderecoFim != null) 'endereco_fim': enderecoFim,
      if (deviceId != null) 'device_id': deviceId,
    };
  }

  static String _toApiDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class RelatorioCirurgiaPaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const RelatorioCirurgiaPaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory RelatorioCirurgiaPaginationInfo.fromJson(Map<String, dynamic> json) {
    final int currentPage = json['currentPage'] ?? json['pageNumber'] ?? 1;
    final int pageSize = json['pageSize'] ?? 50;
    final int totalRecords = json['totalCount'] ?? json['totalRecords'] ?? 0;
    final int totalPages = (totalRecords / pageSize).ceil();
    return RelatorioCirurgiaPaginationInfo(
      currentPage: currentPage,
      pageSize: pageSize,
      totalRecords: totalRecords,
      totalPages: totalPages,
      hasNextPage: currentPage < totalPages,
      hasPreviousPage: currentPage > 1,
    );
  }
}

class RelatorioCirurgiaPaginatedResponse {
  final List<RelatorioCirurgia> itens;
  final RelatorioCirurgiaPaginationInfo pagination;

  const RelatorioCirurgiaPaginatedResponse({
    required this.itens,
    required this.pagination,
  });
}

const List<MapEntry<String, String>> kSatisfacaoOptions = <MapEntry<String, String>>[
  MapEntry<String, String>('1', '1 - Muito insatisfeito'),
  MapEntry<String, String>('2', '2 - Insatisfeito'),
  MapEntry<String, String>('3', '3 - Indiferente'),
  MapEntry<String, String>('4', '4 - Satisfeito'),
  MapEntry<String, String>('5', '5 - Muito satisfeito'),
];
