import '../../tipo_cirurgia/services/tipo_cirurgia_service.dart';
import '../models/relatorio_cirurgia_model.dart';

class RelatorioTipoCirurgiaEnrichmentService {
  final TipoCirurgiaService _tipoCirurgiaService = TipoCirurgiaService();
  final Map<int, String> _nomeByCodcir = <int, String>{};

  Future<List<RelatorioCirurgia>> enrichItens(List<RelatorioCirurgia> itens) async {
    if (itens.isEmpty) {
      return itens;
    }
    final List<RelatorioCirurgia> enriched = <RelatorioCirurgia>[];
    for (final RelatorioCirurgia item in itens) {
      enriched.add(await enrichItem(item));
    }
    return enriched;
  }

  Future<RelatorioCirurgia> enrichItem(RelatorioCirurgia item) async {
    if (item.tipoCirNome?.trim().isNotEmpty == true) {
      return item;
    }
    final int? codcir = item.codcir ?? item.circod;
    if (codcir == null || codcir <= 0) {
      return item;
    }
    final String? nome = await _resolveNome(codcir);
    if (nome == null) {
      return item;
    }
    return _withTipoCirNome(item, nome);
  }

  Future<String?> _resolveNome(int codcir) async {
    if (_nomeByCodcir.containsKey(codcir)) {
      return _nomeByCodcir[codcir];
    }
    try {
      final Map<String, dynamic>? payload =
          await _tipoCirurgiaService.getTipoCirurgiaById(codcir);
      if (payload == null) {
        return null;
      }
      final dynamic data = payload['data'] ?? payload;
      if (data is! Map<String, dynamic>) {
        return null;
      }
      final String? nome = _readNome(data);
      if (nome != null) {
        _nomeByCodcir[codcir] = nome;
      }
      return nome;
    } catch (_) {
      return null;
    }
  }

  String? _readNome(Map<String, dynamic> data) {
    final dynamic nome = data['nomcir'] ?? data['nome'];
    if (nome == null) {
      return null;
    }
    final String text = nome.toString().trim();
    return text.isEmpty ? null : text;
  }

  RelatorioCirurgia _withTipoCirNome(RelatorioCirurgia item, String nome) {
    return RelatorioCirurgia(
      nummov: item.nummov,
      historico: item.historico,
      numreq: item.numreq,
      hrini: item.hrini,
      hrfin: item.hrfin,
      datmov: item.datmov,
      datcir: item.datcir,
      nagecir: item.nagecir,
      lado: item.lado,
      priRev: item.priRev,
      sexo: item.sexo,
      idade: item.idade,
      codpac: item.codpac,
      codins: item.codins,
      inshos: item.inshos,
      sistemaAplicado: item.sistemaAplicado,
      problema: item.problema,
      obsEstoque: item.obsEstoque,
      obsGerencia: item.obsGerencia,
      codusu: item.codusu,
      codcir: item.codcir,
      nomcir: item.nomcir,
      codusuEst: item.codusuEst,
      codusuGerencia: item.codusuGerencia,
      codcli: item.codcli,
      nprontuario: item.nprontuario,
      cirhos: item.cirhos,
      codmed: item.codmed,
      codconv: item.codconv,
      grau: item.grau,
      status: item.status,
      codlev: item.codlev,
      codtro: item.codtro,
      sistema: item.sistema,
      tipo: item.tipo,
      relProb: item.relProb,
      relConta: item.relConta,
      circod: item.circod,
      numrel: item.numrel,
      urgencia: item.urgencia,
      geraut: item.geraut,
      datmod: item.datmod,
      usulan: item.usulan,
      obsRt: item.obsRt,
      medidaTomadaEstoque: item.medidaTomadaEstoque,
      codusuRt: item.codusuRt,
      problemaRetornoMat: item.problemaRetornoMat,
      problemaImp: item.problemaImp,
      satisfacaoMatHospital: item.satisfacaoMatHospital,
      satisfacaoInstHospital: item.satisfacaoInstHospital,
      satisfacaoMatCirurg: item.satisfacaoMatCirurg,
      satisfacaoInstCirurg: item.satisfacaoInstCirurg,
      pacNome: item.pacNome,
      medNome: item.medNome,
      cliNome: item.cliNome,
      convNome: item.convNome,
      tipoCirNome: nome,
      insNome: item.insNome,
      usulanNome: item.usulanNome,
      enderecoInicio: item.enderecoInicio,
      enderecoFim: item.enderecoFim,
      deviceId: item.deviceId,
      dtHoraInicio: item.dtHoraInicio,
      dtHoraFim: item.dtHoraFim,
      latitudeInicio: item.latitudeInicio,
      longitudeInicio: item.longitudeInicio,
      latitudeFim: item.latitudeFim,
      longitudeFim: item.longitudeFim,
      precisaoInicio: item.precisaoInicio,
      precisaoFim: item.precisaoFim,
    );
  }
}
