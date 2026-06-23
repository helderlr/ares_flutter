import 'dart:convert';
import 'dart:io';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_request_helper.dart';
import '../../login/services/auth_service.dart';

class AgendamentoService {
  Future<void> cancelarAgendamento(
    int nummov,
    String motivo,
    DateTime dataCancelamento,
  ) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final String horaCancelamento =
        '${dataCancelamento.hour.toString().padLeft(2, '0')}:'
        '${dataCancelamento.minute.toString().padLeft(2, '0')}:'
        '${dataCancelamento.second.toString().padLeft(2, '0')}';
    final Uri uri =
        Uri.parse('${ApiConfig.apiUrl}/menu/agenda-cirurgia/$nummov').replace(
      queryParameters: <String, String>{'empresaId': empresaId},
    );
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'empresaId': empresaId,
      'agenda_cancelada': 'S',
      'data_cancelamento': _formatDateToApi(dataCancelamento),
      'hora_cancelamento': horaCancelamento,
      'motivo_cancelamento': motivo.trim(),
    };
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.patchUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(requestBody));
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      await HttpRequestHelper.throwIfUnauthorized(httpResponse.statusCode);
      if (httpResponse.statusCode == 200) {
        return;
      }
      if (httpResponse.statusCode == 404) {
        throw Exception('Agendamento não encontrado.');
      }
      throw Exception(
        'Erro ao cancelar agendamento: ${httpResponse.statusCode} - $responseBody',
      );
    } finally {
      httpClient.close();
    }
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
    int? codven,
    int? codcir,
    int? numageOrigem,
  }) async {
    final String empresaId = await AuthService.requireEmpresaId();
    final int? codusu = await AuthService.getCurrentCodusu();
    final Uri uri = Uri.parse('${ApiConfig.apiUrl}/menu/agenda-cirurgia').replace(
      queryParameters: <String, String>{'empresaId': empresaId},
    );
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'empresaId': empresaId,
      'codpac': codpac,
      'codcli': codcli,
      'codmed': codmed,
      'codconv': codconv,
      'nomcir': nomcir.toUpperCase(),
      'datcir': _formatDateToApi(datcir),
      'horcir': horcir,
      if (situac != null && situac.isNotEmpty) 'situac': situac,
      if (obsage != null && obsage.isNotEmpty) 'obsage': obsage,
      if (numaut != null && numaut.isNotEmpty) 'numaut': numaut,
      if (lado != null && lado.isNotEmpty) 'lado': lado,
      if (primrev != null && primrev.isNotEmpty) 'primaria_revisao': primrev,
      if (agendaCancelada != null && agendaCancelada.isNotEmpty)
        'agenda_cancelada': agendaCancelada,
      if (solicitou != null && solicitou.isNotEmpty) 'solicitou': solicitou,
      if (matcir != null && matcir.isNotEmpty) 'matcir': matcir,
      if (codven != null && codven > 0) 'codven': codven,
      if (codcir != null && codcir > 0) 'codcir': codcir,
      if (codusu != null && codusu > 0) 'codusu': codusu,
      if (numageOrigem != null && numageOrigem > 0) 'numage_origem': numageOrigem,
      'tipmar': 'A',
      'datlan': _formatDateToApi(DateTime.now()),
    };
    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.postUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(requestBody));
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      await HttpRequestHelper.throwIfUnauthorized(httpResponse.statusCode);
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        try {
          final dynamic data = json.decode(responseBody);
          if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
            return data['data'] as Map<String, dynamic>;
          }
          if (data is Map<String, dynamic>) {
            return data;
          }
          return <String, dynamic>{'success': true};
        } catch (_) {
          return <String, dynamic>{'success': true};
        }
      }
      if (httpResponse.statusCode == 400) {
        throw Exception('Dados inválidos: $responseBody');
      }
      throw Exception(
        'Erro ao criar agendamento: ${httpResponse.statusCode} - $responseBody',
      );
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

    final String empresaId = await AuthService.requireEmpresaId();
    final Uri uri =
        Uri.parse('${ApiConfig.apiUrl}/menu/agenda-cirurgia/$nummov').replace(
      queryParameters: <String, String>{'empresaId': empresaId},
    );
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'empresaId': empresaId,
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
      requestBody['primaria_revisao'] = primrev;
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

    final HttpClient httpClient = HttpRequestHelper.createClient();
    try {
      final HttpClientRequest request = await httpClient.patchUrl(uri);
      await HttpRequestHelper.applyJsonHeaders(request);
      request.write(jsonEncode(requestBody));
      final HttpClientResponse httpResponse = await request.close();
      final String responseBody =
          await httpResponse.transform(utf8.decoder).join();
      await HttpRequestHelper.throwIfUnauthorized(httpResponse.statusCode);
      if (httpResponse.statusCode == 200) {
        return;
      }
      if (httpResponse.statusCode == 404) {
        throw Exception('Agendamento não encontrado.');
      }
      if (httpResponse.statusCode == 400) {
        throw Exception('Dados inválidos: $responseBody');
      }
      throw Exception(
        'Erro ao atualizar agendamento: ${httpResponse.statusCode} - $responseBody',
      );
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
