import '../../relatorio_cirurgia/models/relatorio_cirurgia_model.dart';

enum RegistroHoraSituacaoFilter {
  todos,
  pendente,
  emAndamento,
  concluido,
}

extension RegistroHoraSituacaoFilterLabels on RegistroHoraSituacaoFilter {
  String get label {
    switch (this) {
      case RegistroHoraSituacaoFilter.todos:
        return 'Todos';
      case RegistroHoraSituacaoFilter.pendente:
        return 'Pendente';
      case RegistroHoraSituacaoFilter.emAndamento:
        return 'Em andamento';
      case RegistroHoraSituacaoFilter.concluido:
        return 'Concluído';
    }
  }
}

extension RegistroHoraSituacaoFilterMatch on RegistroHoraSituacaoFilter {
  bool matches(RelatorioCirurgia item) {
    switch (this) {
      case RegistroHoraSituacaoFilter.todos:
        return true;
      case RegistroHoraSituacaoFilter.pendente:
        return item.registroHoraStatus == RegistroHoraStatus.pendente;
      case RegistroHoraSituacaoFilter.emAndamento:
        return item.registroHoraStatus == RegistroHoraStatus.emAndamento;
      case RegistroHoraSituacaoFilter.concluido:
        return item.registroHoraStatus == RegistroHoraStatus.concluida;
    }
  }
}
