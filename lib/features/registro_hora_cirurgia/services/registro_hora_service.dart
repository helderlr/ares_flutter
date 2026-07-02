import 'package:flutter/material.dart';

import '../../../core/services/mobile_device_context.dart';
import '../../relatorio_cirurgia/models/relatorio_cirurgia_model.dart';
import '../../relatorio_cirurgia/services/relatorio_cirurgia_service.dart';
import 'registro_hora_location_service.dart';

enum RegistroHoraCampo { inicio, fim }

class RegistroHoraService {
  static const int duracaoMinimaAvisoMinutos = 30;
  final RelatorioCirurgiaService _relatorioService = RelatorioCirurgiaService();

  bool podeRegistrarCampo(RelatorioCirurgia item, RegistroHoraCampo campo) {
    switch (campo) {
      case RegistroHoraCampo.inicio:
        return item.canRegistrarHoraInicio;
      case RegistroHoraCampo.fim:
        return item.canRegistrarHoraFim;
    }
  }

  String labelCampo(RegistroHoraCampo campo) {
    switch (campo) {
      case RegistroHoraCampo.inicio:
        return 'Hora início';
      case RegistroHoraCampo.fim:
        return 'Hora fim';
    }
  }

  Future<RelatorioCirurgia> salvarHora({
    required RelatorioCirurgia item,
    required RegistroHoraCampo campo,
    required DateTime hora,
    RegistroHoraLocationCapture? localizacao,
  }) async {
    final String horaTexto =
        '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    final MobileDeviceSnapshot device = await MobileDeviceContext.collect();
    final RelatorioCirurgia payload;
    if (campo == RegistroHoraCampo.inicio) {
      payload = RelatorioCirurgia(
        nummov: item.nummov,
        dtHoraInicio: hora,
        hrini: horaTexto,
        latitudeInicio: localizacao?.position.latitude,
        longitudeInicio: localizacao?.position.longitude,
        precisaoInicio: localizacao?.accuracyMeters,
        enderecoInicio: localizacao?.addressLabel,
        deviceId: device.deviceId,
      );
    } else {
      payload = RelatorioCirurgia(
        nummov: item.nummov,
        dtHoraFim: hora,
        hrfin: horaTexto,
        latitudeFim: localizacao?.position.latitude,
        longitudeFim: localizacao?.position.longitude,
        precisaoFim: localizacao?.accuracyMeters,
        enderecoFim: localizacao?.addressLabel,
        deviceId: device.deviceId,
      );
    }
    return _relatorioService.update(item.nummov, payload);
  }

  DateTime buildDataHoraBase(RelatorioCirurgia item, TimeOfDay hora) {
    final DateTime base = item.datcir ?? DateTime.now();
    return DateTime(base.year, base.month, base.day, hora.hour, hora.minute);
  }
}
