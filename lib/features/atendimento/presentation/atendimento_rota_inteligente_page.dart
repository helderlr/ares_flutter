import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../agendamento/models/agenda_list_filters.dart';
import '../../agendamento/models/agendamento_model.dart';
import '../../agendamento/services/agendamento_service_paginado.dart';
import '../../agendamento/widgets/agenda_filter_dialog.dart';
import '../../hospital/models/hospital_model.dart';
import '../../hospital/services/hospital_service_paginado.dart';
import '../services/route_optimization_service.dart';
import '../utils/current_location_service.dart';
import '../utils/hospital_location_resolver.dart';
import '../utils/map_marker_colors.dart';

enum _RotaViewMode { lista, rotaOtimizada }

class _HospitalDayStop {
  final int? codcli;
  final String name;
  final String timeLabel;
  final int surgeryCount;

  const _HospitalDayStop({
    required this.codcli,
    required this.name,
    required this.timeLabel,
    required this.surgeryCount,
  });
}

class AtendimentoRotaInteligentePage extends StatefulWidget {
  const AtendimentoRotaInteligentePage({super.key});

  @override
  State<AtendimentoRotaInteligentePage> createState() =>
      _AtendimentoRotaInteligentePageState();
}

class _AtendimentoRotaInteligentePageState
    extends State<AtendimentoRotaInteligentePage> {
  final AgendamentoServicePaginado _agendaService =
      AgendamentoServicePaginado();
  final HospitalServicePaginado _hospitalService = HospitalServicePaginado();
  final RouteOptimizationService _routeService = RouteOptimizationService();
  GoogleMapController? _mapController;
  _RotaViewMode _viewMode = _RotaViewMode.lista;
  bool _isLoading = false;
  bool _isGeneratingRoute = false;
  bool _filtersActive = false;
  String? _errorMessage;
  List<_HospitalDayStop> _stops = const <_HospitalDayStop>[];
  OptimizedRouteResult? _routeResult;
  Set<Marker> _markers = <Marker>{};
  Set<Polyline> _polylines = <Polyline>{};
  LatLng _cameraTarget = HospitalLocationResolver.defaultCenter;
  late AgendaListFilters _filters;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _filters = AgendaListFilters(
      dateFrom: DateTime(now.year, now.month, now.day),
      dateTo: DateTime(now.year, now.month, now.day),
      dateField: AgendaDateFilterField.dataCirurgia,
    );
    _loadSurgeries();
  }

  List<_HospitalDayStop> _buildUniqueStops(List<AgendaCirurgia> surgeries) {
    final Map<int, _HospitalDayStop> byCodcli = <int, _HospitalDayStop>{};
    final Map<int, int> counts = <int, int>{};
    for (final AgendaCirurgia surgery in surgeries) {
      final int key = surgery.codcli ?? surgery.nomcli.hashCode;
      counts[key] = (counts[key] ?? 0) + 1;
      final String time = _formatHour(surgery.horcir);
      final _HospitalDayStop? existing = byCodcli[key];
      if (existing == null || time.compareTo(existing.timeLabel) < 0) {
        byCodcli[key] = _HospitalDayStop(
          codcli: surgery.codcli,
          name: surgery.nomcli ?? 'Hospital',
          timeLabel: time,
          surgeryCount: counts[key] ?? 1,
        );
      } else {
        byCodcli[key] = _HospitalDayStop(
          codcli: existing.codcli,
          name: existing.name,
          timeLabel: existing.timeLabel,
          surgeryCount: counts[key] ?? existing.surgeryCount,
        );
      }
    }
    final List<_HospitalDayStop> stops = byCodcli.values.toList()
      ..sort(
        (_HospitalDayStop a, _HospitalDayStop b) =>
            a.timeLabel.compareTo(b.timeLabel),
      );
    return stops;
  }

  Future<void> _loadSurgeries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _viewMode = _RotaViewMode.lista;
      _routeResult = null;
      _markers = <Marker>{};
      _polylines = <Polyline>{};
    });
    try {
      final List<AgendaCirurgia> items = await _agendaService.fetchAllAgendamentos(
        filters: _filters,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _stops = _buildUniqueStops(items);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openFilters() async {
    final AgendaListFilters? result = await AgendaFilterDialog.show(
      context,
      initial: _filters,
      requireDateRange: true,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _filters = result;
      _filtersActive = result.hasActiveFilters;
    });
    await _loadSurgeries();
  }

  Future<Map<int, Hospital>> _loadHospitalsById() async {
    final HospitalPaginatedResponse response =
        await _hospitalService.fetchHospitaisPaginated(
      page: 1,
      pageSize: 500,
    );
    return <int, Hospital>{
      for (final Hospital hospital in response.hospitais)
        hospital.codcli: hospital,
    };
  }

  Future<void> _generateRoute() async {
    if (_stops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum hospital para gerar rota.')),
      );
      return;
    }
    setState(() => _isGeneratingRoute = true);
    try {
      final Map<int, Hospital> hospitalsById = await _loadHospitalsById();
      final HospitalLocationResolver resolver = HospitalLocationResolver(
        hospitalsById: hospitalsById,
      );
      final List<RouteHospitalInput> inputs = <RouteHospitalInput>[];
      int index = 0;
      for (final _HospitalDayStop stop in _stops) {
        final LatLng location = await resolver.resolve(
          codcli: stop.codcli,
          name: stop.name,
          index: index,
        );
        inputs.add(
          RouteHospitalInput(
            codcli: stop.codcli,
            name: stop.name,
            timeLabel: stop.timeLabel,
            location: location,
          ),
        );
        index++;
      }
      if (inputs.isNotEmpty) {
        resolver.anchor = inputs.first.location;
      }
      final List<LatLng> hospitalPoints =
          inputs.map((RouteHospitalInput item) => item.location).toList();
      final CurrentLocationResult? currentLocation =
          await CurrentLocationService.resolve();
      final LatLng home = currentLocation?.position ??
          resolver.resolveHome(hospitalPoints);
      final String homeSubtitle = currentLocation?.addressLabel ??
          'Localização indisponível';
      final OptimizedRouteResult result = _routeService.optimize(
        homeLocation: home,
        hospitals: inputs,
        chronologicalOrder: inputs,
        homeSubtitle: homeSubtitle,
      );
      final Set<Marker> markers = <Marker>{};
      final List<LatLng> polylinePoints = <LatLng>[];
      int hospitalMarkerIndex = 0;
      for (int stopIndex = 0; stopIndex < result.stops.length; stopIndex++) {
        final RouteStopInfo stop = result.stops[stopIndex];
        polylinePoints.add(stop.location);
        markers.add(
          Marker(
            markerId: MarkerId('stop_$stopIndex'),
            position: stop.location,
            icon: stop.isHome
                ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  )
                : MapMarkerColors.iconForIndex(hospitalMarkerIndex++),
            infoWindow: InfoWindow(
              title: stop.isHome ? 'Local atual' : stop.label,
              snippet: stop.isHome
                  ? homeSubtitle
                  : stop.timeLabel,
            ),
          ),
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _routeResult = result;
        _viewMode = _RotaViewMode.rotaOtimizada;
        _markers = markers;
        _polylines = polylinePoints.length >= 2
            ? <Polyline>{
                Polyline(
                  polylineId: const PolylineId('rota'),
                  points: polylinePoints,
                  color: AppColors.lightBlue,
                  width: 4,
                ),
              }
            : <Polyline>{};
        _cameraTarget = home;
        _isGeneratingRoute = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToRoute(polylinePoints);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isGeneratingRoute = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _fitMapToRoute(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty) {
      return;
    }
    if (points.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 14),
        ),
      );
      return;
    }
    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;
    for (final LatLng point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        72,
      ),
    );
  }

  Future<void> _openGoogleMapsRoute() async {
    final OptimizedRouteResult? route = _routeResult;
    if (route == null || route.stops.length < 2) {
      return;
    }
    final RouteStopInfo origin = route.stops.first;
    final RouteStopInfo destination = route.stops.last;
    final List<RouteStopInfo> waypoints = route.stops.length > 2
        ? route.stops.sublist(1, route.stops.length - 1)
        : const <RouteStopInfo>[];
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${origin.location.latitude},${origin.location.longitude}'
      '&destination=${destination.location.latitude},${destination.location.longitude}'
      '${waypoints.isNotEmpty ? '&waypoints=${waypoints.map((RouteStopInfo s) => '${s.location.latitude},${s.location.longitude}').join('|')}' : ''}'
      '&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o Google Maps.')),
      );
    }
  }

  String _formatHour(String? horcir) {
    final String trimmed = horcir?.trim() ?? '';
    if (trimmed.length >= 5) {
      return trimmed.substring(0, 5);
    }
    return trimmed.isEmpty ? '—' : trimmed;
  }

  String get _dayTitle {
    final DateTime? from = _filters.dateFrom;
    if (from == null) {
      return 'Hoje';
    }
    final DateTime today = DateTime.now();
    final DateTime day = DateTime(from.year, from.month, from.day);
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    if (day == todayOnly) {
      return 'Hoje';
    }
    return '${from.day.toString().padLeft(2, '0')}/'
        '${from.month.toString().padLeft(2, '0')}/'
        '${from.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _viewMode == _RotaViewMode.lista
              ? 'Rota inteligente'
              : 'Rota otimizada',
        ),
        backgroundColor: AppColors.lightBlue,
        foregroundColor: Colors.white,
        leading: _viewMode == _RotaViewMode.rotaOtimizada
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => _viewMode = _RotaViewMode.lista);
                },
              )
            : BackButton(color: Colors.white),
        actions: <Widget>[
          IconButton(
            onPressed: _isLoading || _isGeneratingRoute ? null : _openFilters,
            icon: Badge(
              isLabelVisible: _filtersActive,
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: _isLoading || _isGeneratingRoute
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _viewMode == _RotaViewMode.lista
                  ? _buildListView()
                  : _buildRouteView(),
      floatingActionButton: _buildFloatingAction(),
    );
  }

  Widget? _buildFloatingAction() {
    if (_viewMode == _RotaViewMode.lista) {
      if (_stops.isEmpty) {
        return null;
      }
      return FloatingActionButton.extended(
        onPressed: _isGeneratingRoute ? null : _generateRoute,
        icon: const Icon(Icons.route),
        label: const Text('Gerar rota'),
      );
    }
    if (_routeResult == null || _routeResult!.stops.length < 2) {
      return null;
    }
    return FloatingActionButton.extended(
      onPressed: _openGoogleMapsRoute,
      icon: const Icon(Icons.map_outlined),
      label: const Text('Google Maps'),
    );
  }

  Widget _buildListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            _dayTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: _stops.isEmpty
              ? const Center(child: Text('Nenhuma cirurgia neste dia.'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _stops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final _HospitalDayStop stop = _stops[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 44,
                          child: Text(
                            stop.timeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildMapColorDot(
                          color: MapMarkerColors.colorForIndex(index),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                stop.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (stop.surgeryCount > 1)
                                Text(
                                  '${stop.surgeryCount} cirurgias neste hospital',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRouteView() {
    final OptimizedRouteResult? route = _routeResult;
    if (route == null) {
      return const Center(child: Text('Rota não gerada.'));
    }
    return Column(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.38,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _cameraTarget,
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _fitMapToRoute(
                route.stops.map((RouteStopInfo s) => s.location).toList(),
              );
            },
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              const Text(
                'Rota otimizada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._buildTimelineItems(route),
              const Divider(height: 28),
              Text(
                'Total: ${route.totalDistanceKm.toStringAsFixed(0)} km',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Tempo: ${_formatDuration(route.totalDurationMinutes)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Combustível: R\$ ${route.fuelCostBrl.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTimelineItems(OptimizedRouteResult route) {
    final List<Widget> widgets = <Widget>[];
    for (int index = 0; index < route.stops.length; index++) {
      final RouteStopInfo stop = route.stops[index];
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildMapColorDot(
              color: stop.isHome
                  ? MapMarkerColors.homeMarkerColor
                  : MapMarkerColors.colorForIndex(stop.markerIndex ?? 0),
              size: 12,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${_orderLabel(stop.order)} ${stop.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((stop.subtitle ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        stop.subtitle!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  if ((stop.timeLabel ?? '').isNotEmpty && !stop.isHome)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        stop.timeLabel!,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
      if (index < route.legs.length) {
        final RouteLegInfo leg = route.legs[index];
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6, bottom: 10),
            child: Text(
              '↓ ${leg.durationMinutes} min',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  String _orderLabel(int order) {
    const List<String> labels = <String>[
      '①',
      '②',
      '③',
      '④',
      '⑤',
      '⑥',
      '⑦',
      '⑧',
      '⑨',
    ];
    if (order >= 1 && order <= labels.length) {
      return labels[order - 1];
    }
    return '$order.';
  }

  String _formatDuration(int minutes) {
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    if (hours <= 0) {
      return '${mins}min';
    }
    return '${hours}h${mins.toString().padLeft(2, '0')}';
  }

  Widget _buildMapColorDot({
    required Color color,
    double size = 10,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 1,
          ),
        ],
      ),
    );
  }
}
