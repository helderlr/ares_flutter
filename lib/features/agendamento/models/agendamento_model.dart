enum AgendaVisualStatus {
  cancelada,
  materialSaiu,
  remarcada,
  retornou,
  emAberto,
}

class AgendaCirurgia {
  final int nummov;
  final int? codcli;
  final String? nomcli;
  final int? codmed;
  final String? nommed;
  final int? codconv;
  final String? nomconv;
  final String? nomcir;
  final DateTime? datlan;
  final DateTime? datcir;
  final String? horcir;
  final int? codven;
  final String? nomven;
  final String? situac;
  final String? obsage;
  final String? procir;
  final String? matcir;
  final DateTime? datsai;
  final String? solicitou;
  final String? recebeu;
  final int? numreq;
  final int? codcir;
  final String? nomcirTipo;
  final String? matneg;
  final String? numaut;
  final int? codpac;
  final String? nompac;
  final String? lado;
  final String? horsai;
  final int? codusu;
  final String? primrev; // Primária/Revisão: P=Primária, R=Revisão
  final String? agendaCancelada; // Agenda cancelada: S=Sim, N=Não
  final DateTime? datcirOriginal; // Data cirurgia original
  final String? cirurgiaUrgencia; // Cirurgia urgência: S=Sim, N=Não
  final int? codinstru1; // Código instrumentador 1
  final String? nominstru1; // Nome instrumentador 1
  final DateTime? dataCancelamento; // Data do cancelamento
  final String? horaCancelamento; // Hora do cancelamento
  final String? motivoCancelamento; // Motivo do cancelamento
  final String? numeroPedido; // Número do pedido

  const AgendaCirurgia({
    required this.nummov,
    this.codcli,
    this.nomcli,
    this.codmed,
    this.nommed,
    this.codconv,
    this.nomconv,
    this.nomcir,
    this.datlan,
    this.datcir,
    this.horcir,
    this.codven,
    this.nomven,
    this.situac,
    this.obsage,
    this.procir,
    this.matcir,
    this.datsai,
    this.solicitou,
    this.recebeu,
    this.numreq,
    this.codcir,
    this.nomcirTipo,
    this.matneg,
    this.numaut,
    this.codpac,
    this.nompac,
    this.lado,
    this.horsai,
    this.codusu,
    this.primrev,
    this.agendaCancelada,
    this.datcirOriginal,
    this.cirurgiaUrgencia,
    this.codinstru1,
    this.nominstru1,
    this.dataCancelamento,
    this.horaCancelamento,
    this.motivoCancelamento,
    this.numeroPedido,
  });

  int get id => nummov;
  String get pacienteName => nompac ?? 'Paciente não informado';
  String get medicoName => nommed ?? 'Médico não informado';
  String get hospitalName => nomcli ?? 'Hospital não informado';
  String get cirurgiaName => nomcir ?? 'Cirurgia não informada';
  String get convenioName => nomconv ?? 'Convênio não informado';
  String get status => situac ?? 'N/A';
  String get dataCirurgia => datcir != null
      ? '${datcir!.day.toString().padLeft(2, '0')}/${datcir!.month.toString().padLeft(2, '0')}/${datcir!.year}'
      : 'Data não definida';
  String get horaCirurgia => horcir ?? 'Horário não definido';
  String get dataEmissao => datlan != null
      ? '${datlan!.day.toString().padLeft(2, '0')}/${datlan!.month.toString().padLeft(2, '0')}/${datlan!.year}'
      : 'Data não definida';
  String get horaEmissao => datlan != null
      ? '${datlan!.hour.toString().padLeft(2, '0')}:${datlan!.minute.toString().padLeft(2, '0')}:${datlan!.second.toString().padLeft(2, '0')}'
      : 'Hora não definida';
  String get vendedorName => nomven ?? 'Vendedor não informado';
  String get solicitanteName => solicitou ?? 'Solicitante não informado';
  String get materialCirurgia => matcir ?? 'Material não informado';
  String get dataSaidaMaterial => datsai != null
      ? '${datsai!.day.toString().padLeft(2, '0')}/${datsai!.month.toString().padLeft(2, '0')}/${datsai!.year}'
      : 'Data não definida';
  String get horaSaidaMaterial => horsai ?? 'Hora não definida';
  String get numeroRequisicao => numreq?.toString() ?? 'Não informado';
  String get dataCirurgiaOriginal => datcirOriginal != null
      ? '${datcirOriginal!.day.toString().padLeft(2, '0')}/${datcirOriginal!.month.toString().padLeft(2, '0')}/${datcirOriginal!.year}'
      : 'Data não definida';
  String get instrumentadorName => nominstru1 ?? 'Instrumentador não informado';
  String get dataCancelamentoFormatada => dataCancelamento != null
      ? '${dataCancelamento!.day.toString().padLeft(2, '0')}/${dataCancelamento!.month.toString().padLeft(2, '0')}/${dataCancelamento!.year}'
      : 'Data não definida';
  String get horaCancelamentoFormatada =>
      horaCancelamento ?? 'Hora não definida';
  String get motivoCancelamentoTexto =>
      motivoCancelamento ?? 'Motivo não informado';
  String get numeroPedidoTexto => numeroPedido ?? 'Número não informado';

  bool canEditByUser(int? loggedCodusu) {
    if (loggedCodusu == null || codusu == null) {
      return false;
    }
    return codusu == loggedCodusu;
  }

  bool get isAgendaCancelada => agendaCancelada?.toUpperCase() == 'S';

  bool get isRemarcada => datcirOriginal != null;

  String get situacaoCode => (situac ?? 'A').toUpperCase();

  AgendaVisualStatus get visualStatus {
    if (isAgendaCancelada) {
      return AgendaVisualStatus.cancelada;
    }
    if (situacaoCode == 'S') {
      return AgendaVisualStatus.materialSaiu;
    }
    if (isRemarcada) {
      return AgendaVisualStatus.remarcada;
    }
    if (situacaoCode == 'R') {
      return AgendaVisualStatus.retornou;
    }
    return AgendaVisualStatus.emAberto;
  }

  String get visualStatusLabel {
    switch (visualStatus) {
      case AgendaVisualStatus.cancelada:
        return 'Agenda Cancelada';
      case AgendaVisualStatus.materialSaiu:
        return 'Agenda Material Saiu';
      case AgendaVisualStatus.remarcada:
        return 'Agenda Remarcada';
      case AgendaVisualStatus.retornou:
        return 'Agenda Retornou';
      case AgendaVisualStatus.emAberto:
        return 'Agenda Em Aberto';
    }
  }

  factory AgendaCirurgia.fromJson(Map<String, dynamic> json) {
    return AgendaCirurgia(
      nummov: json['nummov'] ?? json['NUMMOV'] ?? 0,
      codcli: json['codcli'] ?? json['CODCLI'],
      nomcli: json['nomcli'] ?? json['NOMCLI'] ?? json['cli_nome'],
      codmed: json['codmed'] ?? json['CODMED'],
      nommed: json['nommed'] ?? json['NOMMED'] ?? json['med_nome'],
      codconv: json['codconv'] ?? json['CODCONV'],
      nomconv: json['nomconv'] ?? json['NOMCONV'],
      nomcir: json['nomcir'] ?? json['NOMCIR'],
      datlan: json['datlan'] != null
          ? DateTime.tryParse(json['datlan']) ??
              (json['DATLAN'] != null
                  ? DateTime.tryParse(json['DATLAN'])
                  : null)
          : null,
      datcir: json['datcir'] != null
          ? DateTime.tryParse(json['datcir']) ??
              (json['DATCIR'] != null
                  ? DateTime.tryParse(json['DATCIR'])
                  : null)
          : null,
      horcir: json['horcir'] ?? json['HORCIR'],
      codven: json['codven'] ?? json['CODVEN'],
      nomven: json['nomven'] ?? json['NOMVEN'],
      situac: json['situac'] ?? json['SITUAC'],
      obsage: json['obsage'] ?? json['OBSAGE'],
      procir: json['procir'] ?? json['PROCIR'],
      matcir: json['matcir'] ?? json['MATCIR'],
      datsai: json['datsai'] != null
          ? DateTime.tryParse(json['datsai']) ??
              (json['DATSAI'] != null
                  ? DateTime.tryParse(json['DATSAI'])
                  : null)
          : null,
      solicitou: json['solicitou'] ?? json['SOLICITOU'],
      recebeu: json['recebeu'] ?? json['RECEBEU'],
      numreq: json['numreq'] ?? json['NUMREQ'],
      codcir: json['codcir'] ?? json['CODCIR'],
      nomcirTipo: json['nomcir_'] ?? json['NOMCIR_'],
      matneg: json['matneg'] ?? json['MATNEG'],
      numaut: json['numaut'] ?? json['NUMAUT'],
      codpac: json['codpac'] ?? json['CODPAC'],
      nompac: json['nompac'] ?? json['NOMPAC'] ?? json['pac_nome'],
      lado: json['lado'] ?? json['LADO'],
      horsai: json['horsai'] ?? json['HORSAI'],
      codusu: json['codusu'] ?? json['CODUSU'],
      primrev: json['primrev'] ?? json['PRIMREV'],
      agendaCancelada: json['agenda_cancelada'] ?? json['AGENDA_CANCELADA'],
      datcirOriginal: json['datcir_original'] != null
          ? DateTime.tryParse(json['datcir_original']) ??
              (json['DATCIR_ORIGINAL'] != null
                  ? DateTime.tryParse(json['DATCIR_ORIGINAL'])
                  : null)
          : null,
      cirurgiaUrgencia: json['cirurgia_urgencia'] ?? json['CIRURGIA_URGENCIA'],
      codinstru1: json['codinstru1'] ?? json['CODINSTRU1'],
      nominstru1: json['nominstru1'] ?? json['NOMINSTRU1'],
      dataCancelamento: json['data_cancelamento'] != null
          ? DateTime.tryParse(json['data_cancelamento']) ??
              (json['DATA_CANCELAMENTO'] != null
                  ? DateTime.tryParse(json['DATA_CANCELAMENTO'])
                  : null)
          : null,
      horaCancelamento: json['hora_cancelamento'] ?? json['HORA_CANCELAMENTO'],
      motivoCancelamento:
          json['motivo_cancelamento'] ?? json['MOTIVO_CANCELAMENTO'],
      numeroPedido: json['numero_pedido'] ?? json['NUMERO_PEDIDO'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nummov': nummov,
      'codcli': codcli,
      'nomcli': nomcli,
      'codmed': codmed,
      'nommed': nommed,
      'codconv': codconv,
      'nomconv': nomconv,
      'nomcir': nomcir,
      'datlan': datlan?.toIso8601String(),
      'datcir': datcir?.toIso8601String(),
      'horcir': horcir,
      'codven': codven,
      'nomven': nomven,
      'situac': situac,
      'obsage': obsage,
      'procir': procir,
      'matcir': matcir,
      'datsai': datsai?.toIso8601String(),
      'solicitou': solicitou,
      'recebeu': recebeu,
      'numreq': numreq,
      'codcir': codcir,
      'nomcir_': nomcirTipo,
      'matneg': matneg,
      'numaut': numaut,
      'codpac': codpac,
      'nompac': nompac,
      'lado': lado,
      'horsai': horsai,
      'codusu': codusu,
      'primrev': primrev,
      'agenda_cancelada': agendaCancelada,
      'datcir_original': datcirOriginal?.toIso8601String(),
      'cirurgia_urgencia': cirurgiaUrgencia,
      'codinstru1': codinstru1,
      'nominstru1': nominstru1,
      'data_cancelamento': dataCancelamento?.toIso8601String(),
      'hora_cancelamento': horaCancelamento,
      'motivo_cancelamento': motivoCancelamento,
      'numero_pedido': numeroPedido,
    };
  }

  AgendaCirurgia copyWith({
    int? nummov,
    int? codcli,
    String? nomcli,
    int? codmed,
    String? nommed,
    int? codconv,
    String? nomconv,
    String? nomcir,
    DateTime? datlan,
    DateTime? datcir,
    String? horcir,
    int? codven,
    String? nomven,
    String? situac,
    String? obsage,
    String? procir,
    String? matcir,
    DateTime? datsai,
    String? solicitou,
    String? recebeu,
    int? numreq,
    int? codcir,
    String? nomcirTipo,
    String? matneg,
    String? numaut,
    int? codpac,
    String? nompac,
    String? lado,
    String? horsai,
    int? codusu,
    String? primrev,
    String? agendaCancelada,
    DateTime? datcirOriginal,
    String? cirurgiaUrgencia,
    int? codinstru1,
    String? nominstru1,
    DateTime? dataCancelamento,
    String? horaCancelamento,
    String? motivoCancelamento,
    String? numeroPedido,
  }) {
    return AgendaCirurgia(
      nummov: nummov ?? this.nummov,
      codcli: codcli ?? this.codcli,
      nomcli: nomcli ?? this.nomcli,
      codmed: codmed ?? this.codmed,
      nommed: nommed ?? this.nommed,
      codconv: codconv ?? this.codconv,
      nomconv: nomconv ?? this.nomconv,
      nomcir: nomcir ?? this.nomcir,
      datlan: datlan ?? this.datlan,
      datcir: datcir ?? this.datcir,
      horcir: horcir ?? this.horcir,
      codven: codven ?? this.codven,
      nomven: nomven ?? this.nomven,
      situac: situac ?? this.situac,
      obsage: obsage ?? this.obsage,
      procir: procir ?? this.procir,
      matcir: matcir ?? this.matcir,
      datsai: datsai ?? this.datsai,
      solicitou: solicitou ?? this.solicitou,
      recebeu: recebeu ?? this.recebeu,
      numreq: numreq ?? this.numreq,
      codcir: codcir ?? this.codcir,
      nomcirTipo: nomcirTipo ?? this.nomcirTipo,
      matneg: matneg ?? this.matneg,
      numaut: numaut ?? this.numaut,
      codpac: codpac ?? this.codpac,
      nompac: nompac ?? this.nompac,
      lado: lado ?? this.lado,
      horsai: horsai ?? this.horsai,
      codusu: codusu ?? this.codusu,
      primrev: primrev ?? this.primrev,
      agendaCancelada: agendaCancelada ?? this.agendaCancelada,
      datcirOriginal: datcirOriginal ?? this.datcirOriginal,
      cirurgiaUrgencia: cirurgiaUrgencia ?? this.cirurgiaUrgencia,
      codinstru1: codinstru1 ?? this.codinstru1,
      nominstru1: nominstru1 ?? this.nominstru1,
      dataCancelamento: dataCancelamento ?? this.dataCancelamento,
      horaCancelamento: horaCancelamento ?? this.horaCancelamento,
      motivoCancelamento: motivoCancelamento ?? this.motivoCancelamento,
      numeroPedido: numeroPedido ?? this.numeroPedido,
    );
  }
}

class AgendaCirurgiaPaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const AgendaCirurgiaPaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory AgendaCirurgiaPaginationInfo.fromJson(Map<String, dynamic> json) {
    final currentPage = json['currentPage'] ?? json['pageNumber'] ?? 1;
    final pageSize = json['pageSize'] ?? 50;
    final totalRecords = json['totalCount'] ?? json['totalRecords'] ?? 0;
    final totalPages = (totalRecords / pageSize).ceil();

    return AgendaCirurgiaPaginationInfo(
      currentPage: currentPage,
      pageSize: pageSize,
      totalRecords: totalRecords,
      totalPages: totalPages,
      hasNextPage: currentPage < totalPages,
      hasPreviousPage: currentPage > 1,
    );
  }

  factory AgendaCirurgiaPaginationInfo.fromList(List<dynamic> data) {
    return AgendaCirurgiaPaginationInfo(
      currentPage: 1,
      pageSize: data.length,
      totalRecords: data.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }
}

class AgendaCirurgiaPaginatedResponse {
  final List<AgendaCirurgia> agendamentos;
  final AgendaCirurgiaPaginationInfo pagination;

  const AgendaCirurgiaPaginatedResponse({
    required this.agendamentos,
    required this.pagination,
  });

  factory AgendaCirurgiaPaginatedResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] ?? json['items'] ?? [];
    final agendamentos =
        dataList.map((item) => AgendaCirurgia.fromJson(item)).toList();

    final pagination = AgendaCirurgiaPaginationInfo.fromJson(json);

    return AgendaCirurgiaPaginatedResponse(
      agendamentos: agendamentos,
      pagination: pagination,
    );
  }

  factory AgendaCirurgiaPaginatedResponse.fromList(List<dynamic> data) {
    final agendamentos =
        data.map((item) => AgendaCirurgia.fromJson(item)).toList();
    final pagination = AgendaCirurgiaPaginationInfo.fromList(data);

    return AgendaCirurgiaPaginatedResponse(
      agendamentos: agendamentos,
      pagination: pagination,
    );
  }
}
