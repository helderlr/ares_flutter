import 'dart:convert';
import 'dart:io';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../../core/services/unauthorized_exception.dart';
import '../../login/services/auth_service.dart';
import '../../login/services/auth_service.dart';

class AgendamentoService {
  Future<void> cancelarAgendamento(
      int id, String motivo, DateTime dataCancelamento) async {
    await Future.delayed(const Duration(seconds: 2));
  }


  Future<Map<String, dynamic>> createAgendamento({
    required int codpac,
    required String nompac,
    required int codcli,
    required String nomcli,
    required int codmed,
    required String nommed,
    required int codconv,
    required String nomconv,
    required String nomcir,
    required DateTime datcir,
    required String horcir,
    String? situac,
    String? obsage,
    String? numaut,
    String? lado,
    String? primrev,
    String? agendaCancelada,
    String? solicitou,
    String? cirurgiaUrgencia,
    String? matcir,
  }) async {
    final url = '${ApiConfig.apiUrl}/menu/agenda-cirurgia/add_agenda_cirurgia';

    final requestBody = {
      'codpac': codpac,
      'nompac': nompac.toUpperCase(),
      'codcli': codcli,
      'nomcli': nomcli.toUpperCase(),
      'codmed': codmed,
      'nommed': nommed.toUpperCase(),
      'codconv': codconv,
      'nomconv': nomconv.toUpperCase(),
      'nomcir': nomcir.toUpperCase(),
      'datcir': _formatDateToApi(datcir),
      'horcir': horcir,
      if (situac != null && situac.isNotEmpty) 'situac': situac,
      if (obsage != null && obsage.isNotEmpty) 'obsage': obsage,
      if (numaut != null && numaut.isNotEmpty) 'numaut': numaut,
      if (lado != null && lado.isNotEmpty) 'lado': lado,
      if (primrev != null && primrev.isNotEmpty) 'primrev': primrev,
      if (agendaCancelada != null && agendaCancelada.isNotEmpty)
        'agenda_cancelada': agendaCancelada,
      if (solicitou != null && solicitou.isNotEmpty) 'solicitou': solicitou,
      if (cirurgiaUrgencia != null && cirurgiaUrgencia.isNotEmpty)
        'cirurgia_urgencia': cirurgiaUrgencia,
      if (matcir != null && matcir.isNotEmpty) 'matcir': matcir,
      'datlan': _formatDateToApi(DateTime.now()),
    };

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.postUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(requestBody));

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      if (httpResponse.statusCode == 201) {
        print('✅ Agendamento criado com sucesso na API!');
        try {
          final data = json.decode(responseBody);
          return data;
        } catch (e) {
          return {'success': true, 'message': 'Agendamento criado com sucesso'};
        }
      } else if (httpResponse.statusCode == 400) {
        throw Exception('Dados inválidos: $responseBody');
      } else if (httpResponse.statusCode == 500) {
        throw Exception('Erro interno do servidor: $responseBody');
      } else {
        throw Exception(
            'Erro ao criar agendamento: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  Future<void> updateAgendamento({
    required int nummov,
    required String nomcir,
    required DateTime datcir,
    required String horcir,
    String? situac,
    String? obsage,
    String? numaut,
    String? lado,
    String? primrev,
    String? agendaCancelada,
    String? solicitou,
    String? cirurgiaUrgencia,
    String? matcir,
  }) async {
    print('🔄 Atualizando agendamento:');
    print('   Nummov: $nummov');
    print('   Nome cirurgia: $nomcir');
    print('   Data cirurgia: $datcir');
    print('   Hora cirurgia: $horcir');

    final requestBody = <String, dynamic>{
      'nummov': nummov,
      'nomcir': nomcir.toUpperCase(),
      'datcir': _formatDateToApi(datcir),
      'horcir': horcir,
      'datlan': _formatDateToApi(DateTime.now()),
    };

    if (situac != null && situac.isNotEmpty) {
      requestBody['situac'] = situac;
    }
    if (obsage != null && obsage.isNotEmpty) {
      requestBody['obsage'] = obsage;
    }
    if (numaut != null && numaut.isNotEmpty) {
      requestBody['numaut'] = numaut;
    }
    if (lado != null && lado.isNotEmpty) {
      requestBody['lado'] = lado;
    }
    if (primrev != null && primrev.isNotEmpty) {
      requestBody['primrev'] = primrev;
    }
    if (agendaCancelada != null && agendaCancelada.isNotEmpty) {
      requestBody['agenda_cancelada'] = agendaCancelada;
    }
    if (solicitou != null && solicitou.isNotEmpty) {
      requestBody['solicitou'] = solicitou;
    }
    if (cirurgiaUrgencia != null && cirurgiaUrgencia.isNotEmpty) {
      requestBody['cirurgia_urgencia'] = cirurgiaUrgencia;
    }
    if (matcir != null && matcir.isNotEmpty) {
      requestBody['matcir'] = matcir;
    }

    print('   Request body: $requestBody');

    final url =
        '${ApiConfig.apiUrl}/menu/agenda-cirurgia/$nummov';

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.putUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);

      print('   Headers configurados');
      print('   Enviando requisição...');

      request.write(jsonEncode(requestBody));

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('   Response body: $responseBody');
      print('   Status code: ${httpResponse.statusCode}');

      if (httpResponse.statusCode == 204) {
        print('✅ Agendamento atualizado com sucesso!');
      } else if (httpResponse.statusCode == 404) {
        throw Exception('Agendamento não encontrado.');
      } else if (httpResponse.statusCode == 400) {
        throw Exception('Dados inválidos: $responseBody');
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else {
        throw Exception(
            'Erro ao atualizar agendamento: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  Future<Map<String, dynamic>?> getAgendamentoById(int id) async {
    print('🔍 Buscando agendamento por ID: $id');

    final url = '${ApiConfig.apiUrl}/menu/agenda-cirurgia/$id';

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      if (httpResponse.statusCode == 200) {
        try {
          final data = json.decode(responseBody);
          return data;
        } catch (e) {
          throw Exception('Resposta inválida da API: $e');
        }
      } else if (httpResponse.statusCode == 404) {
        return null;
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else {
        throw Exception(
            'Erro ao buscar agendamento: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  Future<bool> deleteAgendamento(int id) async {
    print('🗑️ Iniciando exclusão do agendamento ID: $id');

    final url = '${ApiConfig.apiUrl}/menu/agenda-cirurgia/delete_agenda_cirurgia/$id';
    print('🔗 URL: $url');

    final HttpClient httpClient = HttpRequestHelper.createClient();

    try {
      final request = await httpClient.deleteUrl(Uri.parse(url));
      await HttpRequestHelper.applyJsonHeaders(request);

      print('📤 Enviando requisição DELETE...');

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      print('📥 Resposta recebida:');
      print('   Status: ${httpResponse.statusCode}');
      print('   Body: $responseBody');

      if (httpResponse.statusCode == 204) {
        print('✅ Agendamento excluído com sucesso!');
        return true;
      } else if (httpResponse.statusCode == 404) {
        throw Exception('Agendamento não encontrado.');
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else {
        throw Exception(
            'Erro ao excluir agendamento: ${httpResponse.statusCode} - $responseBody');
      }
    } finally {
      httpClient.close();
    }
  }

  String _formatDateToApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00';
  }

  DateTime? _parseApiDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
      return DateTime.parse(dateString);
    } catch (e) {
      print('Erro ao converter data: $dateString - $e');
      return null;
    }
  }

  String _formatDateToDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
