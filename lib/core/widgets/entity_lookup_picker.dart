import 'package:flutter/material.dart';
import '../../features/convenio/services/convenio_service_paginado.dart';
import '../../features/hospital/services/hospital_service_paginado.dart';
import '../../features/medico/services/medico_service_paginado.dart';
import '../../features/paciente/services/paciente_service.dart';
import '../../features/tipo_cirurgia/services/tipo_cirurgia_service_paginado.dart';
import 'entity_search_dialog.dart';

class EntityLookupSelection {
  final String code;
  final String? name;

  const EntityLookupSelection({
    required this.code,
    this.name,
  });
}

class EntityLookupPicker {
  static Future<EntityLookupSelection?> pickPaciente(BuildContext context) async {
    final PacienteService service = PacienteService();
    final dynamic result = await EntitySearchDialog.show<dynamic>(
      context: context,
      title: 'Buscar Paciente',
      placeholder: 'Digite o nome do paciente',
      searchFunction: service.searchPacientes,
      labelOf: (dynamic item) => '${item['nompac']}',
      subtitleOf: (dynamic item) => 'Código: ${item['codpac']}',
    );
    if (result == null) {
      return null;
    }
    return EntityLookupSelection(
      code: '${result['codpac']}',
      name: result['nompac']?.toString(),
    );
  }

  static Future<EntityLookupSelection?> pickMedico(BuildContext context) async {
    final MedicoServicePaginado service = MedicoServicePaginado();
    final dynamic result = await EntitySearchDialog.show<dynamic>(
      context: context,
      title: 'Buscar Medico',
      placeholder: 'Digite o nome do medico',
      searchFunction: (String query) async {
        final response = await service.fetchMedicosPaginated(
          page: 1,
          searchQuery: query,
        );
        return response.medicos;
      },
      labelOf: (dynamic item) => item.nommed as String,
      subtitleOf: (dynamic item) => 'Código: ${item.codmed}',
    );
    if (result == null) {
      return null;
    }
    return EntityLookupSelection(
      code: '${result.codmed}',
      name: result.nommed as String?,
    );
  }

  static Future<EntityLookupSelection?> pickHospital(BuildContext context) async {
    final HospitalServicePaginado service = HospitalServicePaginado();
    final dynamic result = await EntitySearchDialog.show<dynamic>(
      context: context,
      title: 'Buscar Hospital',
      placeholder: 'Digite o nome do hospital',
      searchFunction: (String query) async {
        final response = await service.fetchHospitaisPaginated(
          page: 1,
          searchQuery: query,
        );
        return response.hospitais;
      },
      labelOf: (dynamic item) => item.nomcli as String,
      subtitleOf: (dynamic item) => 'Código: ${item.codcli}',
    );
    if (result == null) {
      return null;
    }
    return EntityLookupSelection(
      code: '${result.codcli}',
      name: result.nomcli as String?,
    );
  }

  static Future<EntityLookupSelection?> pickConvenio(BuildContext context) async {
    final ConvenioServicePaginado service = ConvenioServicePaginado();
    final dynamic result = await EntitySearchDialog.show<dynamic>(
      context: context,
      title: 'Buscar Convenio',
      placeholder: 'Digite o nome do convenio',
      searchFunction: (String query) async {
        final response = await service.fetchConveniosPaginated(
          page: 1,
          searchQuery: query,
        );
        return response.convenios;
      },
      labelOf: (dynamic item) => item.nomcon as String,
      subtitleOf: (dynamic item) => 'Código: ${item.codcon}',
    );
    if (result == null) {
      return null;
    }
    return EntityLookupSelection(
      code: '${result.codcon}',
      name: result.nomcon as String?,
    );
  }

  static Future<EntityLookupSelection?> pickTipoCirurgia(
    BuildContext context,
  ) async {
    final TipoCirurgiaServicePaginado service = TipoCirurgiaServicePaginado();
    final dynamic result = await EntitySearchDialog.show<dynamic>(
      context: context,
      title: 'Buscar Tipo Cirurgia',
      placeholder: 'Digite o tipo de cirurgia',
      searchFunction: (String query) async {
        final response = await service.fetchTiposCirurgiaPaginated(
          page: 1,
          searchQuery: query,
        );
        return response.tiposCirurgia;
      },
      labelOf: (dynamic item) => item.nomcir as String,
      subtitleOf: (dynamic item) => 'Código: ${item.codcir}',
    );
    if (result == null) {
      return null;
    }
    return EntityLookupSelection(
      code: '${result.codcir}',
      name: result.nomcir as String?,
    );
  }
}
