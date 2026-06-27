import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_colors.dart';
import '../../../core/services/screen_capture_service.dart';
import '../../../core/widgets/share_format_sheet.dart';
import '../../agendamento/models/agenda_list_filters.dart';
import '../../agendamento/models/agendamento_model.dart';
import '../../agendamento/services/agendamento_service_paginado.dart';
import '../../login/services/auth_service.dart';
import '../models/atendimento_mapa_model.dart';
import '../services/atendimento_analytics_service.dart';

class AtendimentoCirurgiaMapaPage extends StatefulWidget {
  const AtendimentoCirurgiaMapaPage({super.key});

  @override
  State<AtendimentoCirurgiaMapaPage> createState() =>
      _AtendimentoCirurgiaMapaPageState();
}

class _AtendimentoCirurgiaMapaPageState
    extends State<AtendimentoCirurgiaMapaPage> {
  final AtendimentoAnalyticsService _service = AtendimentoAnalyticsService();
  final AgendamentoServicePaginado _agendaService =
      AgendamentoServicePaginado();
  final GlobalKey _shareKey = GlobalKey();
  GoogleMapController? _mapController;
  late DateTime _referenceDate;
  bool _isAdmin = false;
  bool _isLoading = true;
  bool _isGeocoding = false;
  bool _isSharing = false;
  String? _errorMessage;
  List<AtendimentoMapaHospital> _hospitais = const <AtendimentoMapaHospital>[];
  Map<int, List<AgendaCirurgia>> _surgeriesByHospital =
      <int, List<AgendaCirurgia>>{};
  final Map<String, LatLng> _locationByKey = <String, LatLng>{};
  final Map<String, String> _markerIdByKey = <String, String>{};
  Set<Marker> _markers = <Marker>{};
  LatLng _cameraTarget = const LatLng(-3.7504, -38.5017);
  String? _selectedHospitalKey;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _referenceDate = DateTime(now.year, now.month, now.day);
    _loadPermissions();
    _loadMapa();
  }

  String _hospitalKey(AtendimentoMapaHospital hospital) {
    return '${hospital.codcli ?? 0}-${hospital.nome}';
  }

  Future<void> _loadPermissions() async {
    final permissions = await AuthService.getUserPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _isAdmin = permissions.isAdmin;
    });
  }

  Future<void> _loadMapa() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _markers = <Marker>{};
      _locationByKey.clear();
      _markerIdByKey.clear();
      _selectedHospitalKey = null;
      _surgeriesByHospital = <int, List<AgendaCirurgia>>{};
    });
    try {
      final AtendimentoCirurgiaMapaData data =
          await _service.fetchCirurgiaMapa(referenceDay: _referenceDate);
      final AgendaListFilters filters = AgendaListFilters(
        dateFrom: _referenceDate,
        dateTo: _referenceDate,
        dateField: AgendaDateFilterField.dataCirurgia,
      );
      final List<AgendaCirurgia> surgeries =
          await _agendaService.fetchAllAgendamentos(filters: filters);
      final Map<int, List<AgendaCirurgia>> grouped =
          <int, List<AgendaCirurgia>>{};
      for (final AgendaCirurgia item in surgeries) {
        final int? codcli = item.codcli;
        if (codcli == null) {
          continue;
        }
        grouped.putIfAbsent(codcli, () => <AgendaCirurgia>[]).add(item);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _hospitais = data.hospitais;
        _surgeriesByHospital = grouped;
        _isLoading = false;
      });
      await _buildMarkers();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _service.formatUserError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _buildMarkers() async {
    if (_hospitais.isEmpty) {
      return;
    }
    setState(() => _isGeocoding = true);
    final Set<Marker> markers = <Marker>{};
    LatLng? firstLocated;
    int index = 0;
    for (final AtendimentoMapaHospital hospital in _hospitais) {
      final String key = _hospitalKey(hospital);
      final LatLng location = await _resolveLocation(hospital, index: index);
      index++;
      _locationByKey[key] = location;
      firstLocated ??= location;
      final String markerId = 'hospital-$key';
      _markerIdByKey[key] = markerId;
      markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: location,
          infoWindow: InfoWindow(
            title: hospital.nome,
            snippet: '${hospital.total} cirurgia(s)',
          ),
          onTap: () => _openHospitalDetails(hospital),
        ),
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _markers = markers;
      _isGeocoding = false;
      if (firstLocated != null) {
        _cameraTarget = firstLocated;
      }
    });
    await _fitMapToMarkers();
  }

  Future<void> _fitMapToMarkers() async {
    if (_mapController == null || _markers.isEmpty) {
      return;
    }
    if (_markers.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _cameraTarget, zoom: 13),
        ),
      );
      return;
    }
    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;
    for (final Marker marker in _markers) {
      final double lat = marker.position.latitude;
      final double lng = marker.position.longitude;
      if (lat < minLat) {
        minLat = lat;
      }
      if (lat > maxLat) {
        maxLat = lat;
      }
      if (lng < minLng) {
        minLng = lng;
      }
      if (lng > maxLng) {
        maxLng = lng;
      }
    }
    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 48),
    );
  }

  Future<LatLng> _resolveLocation(
    AtendimentoMapaHospital hospital, {
    int index = 0,
  }) async {
    final String address = hospital.fullAddress.trim();
    if (address.isNotEmpty) {
      final List<String> attempts = <String>[
        address,
        '$address, Brasil',
        if (hospital.cep != null && hospital.cep!.isNotEmpty)
          '${hospital.cep}, Brasil',
        '${hospital.cidade ?? ''}, ${hospital.estado ?? ''}, Brasil',
      ];
      for (final String attempt in attempts) {
        final String trimmed = attempt.trim();
        if (trimmed.isEmpty || trimmed == ', Brasil') {
          continue;
        }
        try {
          final List<Location> locations = await locationFromAddress(
            trimmed,
            localeIdentifier: 'pt_BR',
          );
          if (locations.isNotEmpty) {
            return LatLng(
              locations.first.latitude,
              locations.first.longitude,
            );
          }
        } catch (_) {
          continue;
        }
      }
    }
    final LatLng? cityLocation = await _resolveCityFallback(hospital, index);
    if (cityLocation != null) {
      return cityLocation;
    }
    return _hashFallbackLocation(hospital, index);
  }

  Future<LatLng?> _resolveCityFallback(
    AtendimentoMapaHospital hospital,
    int index,
  ) async {
    final String city = hospital.cidade?.trim() ?? '';
    final String state = hospital.estado?.trim() ?? '';
    if (city.isEmpty && state.isEmpty) {
      return null;
    }
    final String query = city.isNotEmpty
        ? '$city${state.isNotEmpty ? ', $state' : ''}, Brasil'
        : '$state, Brasil';
    try {
      final List<Location> locations = await locationFromAddress(
        query,
        localeIdentifier: 'pt_BR',
      );
      if (locations.isEmpty) {
        return null;
      }
      final Location base = locations.first;
      final double offset = index * 0.004;
      return LatLng(base.latitude + offset, base.longitude + offset);
    } catch (_) {
      return null;
    }
  }

  LatLng _hashFallbackLocation(AtendimentoMapaHospital hospital, int index) {
    final int seed = (hospital.codcli ?? index) * 9973 + index * 37;
    final double latOffset = (seed % 1000) / 100000;
    final double lngOffset = ((seed ~/ 1000) % 1000) / 100000;
    return LatLng(
      _cameraTarget.latitude + latOffset,
      _cameraTarget.longitude + lngOffset,
    );
  }

  List<AgendaCirurgia> _surgeriesFor(AtendimentoMapaHospital hospital) {
    final int? codcli = hospital.codcli;
    if (codcli == null) {
      return const <AgendaCirurgia>[];
    }
    final List<AgendaCirurgia> items =
        List<AgendaCirurgia>.from(_surgeriesByHospital[codcli] ?? const []);
    items.sort((AgendaCirurgia a, AgendaCirurgia b) {
      return (a.horcir ?? '').compareTo(b.horcir ?? '');
    });
    return items;
  }

  List<MapEntry<String, List<String>>> _groupNamesByTime(
    List<AgendaCirurgia> surgeries,
  ) {
    final Map<String, List<String>> grouped = <String, List<String>>{};
    for (final AgendaCirurgia item in surgeries) {
      final String time = _formatHour(item.horcir ?? '');
      final List<String> names = grouped.putIfAbsent(time, () => <String>[]);
      if ((item.nommed ?? '').isNotEmpty && !names.contains(item.nommed!)) {
        names.add(item.nommed!);
      }
      if ((item.nominstru1 ?? '').isNotEmpty &&
          !names.contains(item.nominstru1!)) {
        names.add(item.nominstru1!);
      }
      if (names.isEmpty && (item.nompac ?? '').isNotEmpty) {
        names.add(item.nompac!);
      }
    }
    final List<MapEntry<String, List<String>>> entries =
        grouped.entries.toList()
          ..sort(
            (MapEntry<String, List<String>> a, MapEntry<String, List<String>> b) =>
                a.key.compareTo(b.key),
          );
    return entries;
  }

  Future<void> _openHospitalDetails(AtendimentoMapaHospital hospital) async {
    final String key = _hospitalKey(hospital);
    final LatLng? location = _locationByKey[key];
    if (location != null) {
      setState(() => _selectedHospitalKey = key);
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 14),
        ),
      );
    }
    if (!mounted) {
      return;
    }
    final List<AgendaCirurgia> surgeries = _surgeriesFor(hospital);
    final List<MapEntry<String, List<String>>> timeGroups =
        _groupNamesByTime(surgeries);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          builder: (BuildContext context, ScrollController controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hospital.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${hospital.total} Cirurgia${hospital.total == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: timeGroups.isEmpty
                        ? const Center(child: Text('Sem detalhes de horários.'))
                        : ListView.builder(
                            controller: controller,
                            itemCount: timeGroups.length,
                            itemBuilder: (BuildContext context, int index) {
                              final MapEntry<String, List<String>> group =
                                  timeGroups[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      group.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    ...group.value.map(
                                      (String name) => Text(name),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatHour(String horcir) {
    final String trimmed = horcir.trim();
    if (trimmed.length >= 5) {
      return trimmed.substring(0, 5);
    }
    return trimmed;
  }

  Future<void> _shareMapa() async {
    final ShareFormat? format = await ShareFormatSheet.show(context);
    if (format == null || !mounted) {
      return;
    }
    setState(() => _isSharing = true);
    try {
      if (format == ShareFormat.image) {
        final Uint8List? bytes =
            await ScreenCaptureService.capturePng(_shareKey);
        if (bytes == null) {
          throw Exception('Não foi possível capturar a imagem.');
        }
        await ScreenCaptureService.sharePngBytes(
          bytes: bytes,
          fileName: 'cirurgia_mapa_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        final pw.Document document = pw.Document();
        document.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return <pw.Widget>[
                pw.Text(
                  'Cirurgia mapa — $_dateLabel',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                ..._hospitais.map(
                  (AtendimentoMapaHospital hospital) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(
                        '${hospital.nome} (${hospital.total})',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(hospital.fullAddress),
                      pw.SizedBox(height: 6),
                    ],
                  ),
                ),
              ];
            },
          ),
        );
        await ScreenCaptureService.sharePdfFile(
          bytes: await document.save(),
          fileName: 'cirurgia_mapa_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime firstDate = _isAdmin
        ? DateTime(2010, 1, 1)
        : DateTime.now().subtract(const Duration(days: 365));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _referenceDate,
      firstDate: firstDate,
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.day,
      helpText: 'Selecione o dia',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _referenceDate = DateTime(picked.year, picked.month, picked.day);
    });
    await _loadMapa();
  }

  String get _dateLabel {
    final String day = _referenceDate.day.toString().padLeft(2, '0');
    final String month = _referenceDate.month.toString().padLeft(2, '0');
    return '$day/$month/${_referenceDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cirurgia mapa'),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _errorMessage == null)
            IconButton(
              onPressed: _isSharing ? null : _shareMapa,
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share),
              tooltip: 'Compartilhar',
            ),
          IconButton(
            onPressed: _isLoading ? null : _pickDate,
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Selecionar data',
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _shareKey,
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Text(
                  'Dia: $_dateLabel • ${_hospitais.length} hospital(is) • ${_markers.length} no mapa',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 5,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_errorMessage!),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _loadMapa,
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _cameraTarget,
                                  zoom: 11,
                                ),
                                markers: _markers,
                                myLocationButtonEnabled: false,
                                onMapCreated:
                                    (GoogleMapController controller) async {
                                  _mapController = controller;
                                  await _fitMapToMarkers();
                                },
                              ),
                              if (_isGeocoding)
                                const Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Card(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Text('Localizando hospitais...'),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
              ),
              if (!_isLoading && _errorMessage == null)
                Expanded(
                  flex: 1,
                  child: _hospitais.isEmpty
                      ? const Center(
                          child: Text('Nenhuma cirurgia neste dia.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _hospitais.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final AtendimentoMapaHospital hospital =
                                _hospitais[index];
                            final String key = _hospitalKey(hospital);
                            final bool isSelected =
                                _selectedHospitalKey == key;
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              selectedTileColor:
                                  AppColors.lightBlue.withOpacity(0.08),
                              onTap: () => _openHospitalDetails(hospital),
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.lightBlue,
                                child: Text(
                                  '${hospital.total}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                hospital.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                hospital.fullAddress.isEmpty
                                    ? 'Endereço não informado'
                                    : hospital.fullAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing:
                                  const Icon(Icons.place_outlined, size: 20),
                            );
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
