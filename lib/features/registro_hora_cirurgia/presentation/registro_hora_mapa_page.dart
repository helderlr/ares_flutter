import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/address_text_helper.dart';
import '../../atendimento/utils/map_marker_colors.dart';
import '../../relatorio_cirurgia/models/relatorio_cirurgia_model.dart';
import '../../relatorio_cirurgia/services/relatorio_tipo_cirurgia_enrichment_service.dart';

class RegistroHoraMapaPage extends StatefulWidget {
  final RelatorioCirurgia relatorio;

  const RegistroHoraMapaPage({
    super.key,
    required this.relatorio,
  });

  @override
  State<RegistroHoraMapaPage> createState() => _RegistroHoraMapaPageState();
}

class _RegistroHoraMapaPageState extends State<RegistroHoraMapaPage> {
  final RelatorioTipoCirurgiaEnrichmentService _enrichmentService =
      RelatorioTipoCirurgiaEnrichmentService();
  GoogleMapController? _mapController;
  LatLng _cameraTarget = const LatLng(-3.7504, -38.5017);
  RelatorioCirurgia? _enrichedItem;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnriched();
  }

  Future<void> _loadEnriched() async {
    final RelatorioCirurgia enriched =
        await _enrichmentService.enrichItem(widget.relatorio);
    if (!mounted) {
      return;
    }
    setState(() {
      _enrichedItem = enriched;
      _isLoading = false;
    });
  }

  RelatorioCirurgia get _item => _enrichedItem ?? widget.relatorio;

  LatLng? get _inicioLocation {
    if (!_item.hasLocalizacaoInicio) {
      return null;
    }
    return LatLng(_item.latitudeInicio!, _item.longitudeInicio!);
  }

  LatLng? get _fimLocation {
    if (!_item.hasLocalizacaoFim) {
      return null;
    }
    return LatLng(_item.latitudeFim!, _item.longitudeFim!);
  }

  @override
  Widget build(BuildContext context) {
    final LatLng? inicio = _inicioLocation;
    final LatLng? fim = _fimLocation;
    final Set<Marker> markers = _buildMarkers(inicio, fim);
    final Set<Polyline> polylines = _buildPolylines(inicio, fim);
    if (inicio != null) {
      _cameraTarget = inicio;
    } else if (fim != null) {
      _cameraTarget = fim;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes - ${_item.pacienteName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.42,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _cameraTarget,
                      zoom: 14,
                    ),
                    markers: markers,
                    polylines: polylines,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      _fitBounds(inicio, fim);
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      Text(
                        _item.pacienteName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cirurgia: ${_item.tipoCirurgiaDisplay}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Data: ${_item.dataCirurgiaDisplay}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 16),
                      _buildLocationTile(
                        label: 'Início',
                        time: _item.horaInicioDisplay,
                        address: _item.enderecoInicio,
                        color: Colors.green,
                        hasLocation: inicio != null,
                      ),
                      const SizedBox(height: 12),
                      _buildLocationTile(
                        label: 'Fim',
                        time: _item.horaFimDisplay,
                        address: _item.enderecoFim,
                        color: Colors.red,
                        hasLocation: fim != null,
                      ),
                      const SizedBox(height: 20),
                      if (inicio != null && fim != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openGoogleMapsRoute,
                            icon: const Icon(Icons.map),
                            label: const Text('Ver rota no Google Maps'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lightBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Set<Marker> _buildMarkers(LatLng? inicio, LatLng? fim) {
    final Set<Marker> markers = <Marker>{};
    if (inicio != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('inicio'),
          position: inicio,
          icon: MapMarkerColors.iconForIndex(0),
          infoWindow: InfoWindow(
            title: 'Início',
            snippet: _item.horaInicioDisplay,
          ),
        ),
      );
    }
    if (fim != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('fim'),
          position: fim,
          icon: MapMarkerColors.iconForIndex(1),
          infoWindow: InfoWindow(
            title: 'Fim',
            snippet: _item.horaFimDisplay,
          ),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolylines(LatLng? inicio, LatLng? fim) {
    if (inicio == null || fim == null) {
      return <Polyline>{};
    }
    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('rota'),
        points: <LatLng>[inicio, fim],
        color: AppColors.lightBlue,
        width: 4,
      ),
    };
  }

  Widget _buildLocationTile({
    required String label,
    required String time,
    required String? address,
    required Color color,
    required bool hasLocation,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$label • $time',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasLocation
                      ? (address?.trim().isNotEmpty == true
                          ? AddressTextHelper.normalize(address!.trim())
                          : 'Localização registrada')
                      : 'Localização não registrada',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fitBounds(LatLng? inicio, LatLng? fim) async {
    if (_mapController == null) {
      return;
    }
    if (inicio != null && fim != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              inicio.latitude < fim.latitude ? inicio.latitude : fim.latitude,
              inicio.longitude < fim.longitude
                  ? inicio.longitude
                  : fim.longitude,
            ),
            northeast: LatLng(
              inicio.latitude > fim.latitude ? inicio.latitude : fim.latitude,
              inicio.longitude > fim.longitude
                  ? inicio.longitude
                  : fim.longitude,
            ),
          ),
          72,
        ),
      );
      return;
    }
    final LatLng? single = inicio ?? fim;
    if (single != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(single, 15),
      );
    }
  }

  Future<void> _openGoogleMapsRoute() async {
    final LatLng? inicio = _inicioLocation;
    final LatLng? fim = _fimLocation;
    if (inicio == null || fim == null) {
      return;
    }
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${inicio.latitude},${inicio.longitude}'
      '&destination=${fim.latitude},${fim.longitude}'
      '&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o Google Maps.')),
      );
    }
  }
}
