import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hospital_model.dart';

class HospitalMapPage extends StatefulWidget {
  final Hospital hospital;

  const HospitalMapPage({
    Key? key,
    required this.hospital,
  }) : super(key: key);

  @override
  State<HospitalMapPage> createState() => _HospitalMapPageState();
}

class _HospitalMapPageState extends State<HospitalMapPage> {
  GoogleMapController? _mapController;
  LatLng _hospitalLocation = const LatLng(-3.7504, -38.5017);
  bool _isLoading = false;
  String _errorMessage = '';
  Set<Marker> _markers = {};

  void _updateLocation(Location location) {
    final novaLocalizacao = LatLng(location.latitude, location.longitude);
    print(
        '✅ Atualizando localização para: ${novaLocalizacao.latitude}, ${novaLocalizacao.longitude}');

    setState(() {
      _hospitalLocation = novaLocalizacao;
      _isLoading = false;
      _markers = {
        Marker(
          markerId: const MarkerId('hospital'),
          position: novaLocalizacao,
          infoWindow: InfoWindow(
            title: widget.hospital.name,
            snippet:
                '${widget.hospital.address}, ${widget.hospital.bairroFormatado}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });

    // Atualiza a câmera do mapa
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: novaLocalizacao,
            zoom: 15,
          ),
        ),
      );
      print('🎯 Câmera do mapa atualizada');
    }
  }

  // Estilo personalizado para o mapa
  final String _mapStyle = '''
    [
      {
        "featureType": "all",
        "elementType": "geometry",
        "stylers": [
          {
            "visibility": "on"
          }
        ]
      },
      {
        "featureType": "all",
        "elementType": "labels",
        "stylers": [
          {
            "visibility": "on"
          }
        ]
      }
    ]
  ''';

  @override
  void initState() {
    super.initState();
    print('🚀 Iniciando HospitalMapPage...');
    print('🏥 Hospital: ${widget.hospital.name}');
    print('📍 Endereço: ${widget.hospital.address}');
    print('🏙️ Cidade: ${widget.hospital.cidadeFormatada}');
    print('🗺️ Estado: ${widget.hospital.estadoFormatado}');
    print(
        '🔄 Coordenadas iniciais: ${_hospitalLocation.latitude}, ${_hospitalLocation.longitude}');

    // Pequeno delay para garantir que o widget está montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
        _getHospitalLocation();
      }
    });
  }

  Future<void> _getHospitalLocation() async {
    try {
      print('🔍 Buscando localização do hospital...');

      // Primeiro tenta com cidade e estado
      final cidadeEstado =
          '${widget.hospital.cidadeFormatada}, ${widget.hospital.estadoFormatado}, Brasil'
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
      print('🌆 Tentando com cidade e estado: $cidadeEstado');

      try {
        final locations = await locationFromAddress(cidadeEstado);
        if (locations.isNotEmpty) {
          print('✅ Localização encontrada com cidade e estado!');
          _updateLocation(locations.first);
          return;
        }
      } catch (e) {
        print('⚠️ Erro ao buscar por cidade e estado: $e');
      }

      // Se não encontrou, tenta com endereço completo
      final List<String> partes = [];

      if (widget.hospital.address.isNotEmpty) {
        final endereco =
            widget.hospital.address.replaceAll(RegExp(r'\s+'), ' ').trim();
        partes.add(endereco);
      }

      if (widget.hospital.numeroFormatado.isNotEmpty) {
        partes.add(widget.hospital.numeroFormatado);
      }

      if (widget.hospital.bairroFormatado.isNotEmpty) {
        partes.add(widget.hospital.bairroFormatado);
      }

      partes.add(widget.hospital.cidadeFormatada);
      partes.add(widget.hospital.estadoFormatado);
      partes.add('Brasil');

      final endereco = partes.join(', ').replaceAll(RegExp(r'\s+'), ' ').trim();
      print('🔍 Tentando com endereço completo: $endereco');

      if (endereco.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Endereço do hospital não disponível';
        });
        return;
      }

      // Primeiro, tenta com o endereço completo
      List<Location> locations = [];
      try {
        print('🔍 Tentando geocodificar endereço completo...');
        locations = await locationFromAddress(endereco);
        print('✅ Sucesso com endereço completo!');
      } catch (e) {
        print('⚠️ Erro com endereço completo: $e');
        print('🔄 Tentando sem número...');

        try {
          // Remove o número e tenta novamente
          final enderecoSemNumero = partes
              .where((p) => p != widget.hospital.numeroFormatado)
              .join(', ');
          print('📍 Endereço sem número: $enderecoSemNumero');
          locations = await locationFromAddress(enderecoSemNumero);
          print('✅ Sucesso com endereço sem número!');
        } catch (e) {
          print('⚠️ Erro com endereço sem número: $e');
          print('🔄 Tentando apenas com cidade e estado...');

          try {
            // Tenta apenas com cidade e estado
            final cidadeEstado =
                '${widget.hospital.cidadeFormatada}, ${widget.hospital.estadoFormatado}, Brasil';
            print('🌆 Buscando por: $cidadeEstado');
            locations = await locationFromAddress(cidadeEstado);
            print('✅ Sucesso com cidade e estado!');
          } catch (e) {
            print('⚠️ Erro com cidade e estado: $e');
            print('🔄 Última tentativa: usando apenas a cidade...');

            // Última tentativa: apenas a cidade
            final apenasCity = '${widget.hospital.cidadeFormatada}, Brasil';
            print('🏙️ Buscando por: $apenasCity');
            locations = await locationFromAddress(apenasCity);
            print('✅ Sucesso com apenas a cidade!');
          }
        }
      }

      if (locations.isNotEmpty) {
        final novaLocalizacao = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );

        print(
            '✅ Localização encontrada: ${novaLocalizacao.latitude}, ${novaLocalizacao.longitude}');

        setState(() {
          _hospitalLocation = novaLocalizacao;
          _isLoading = false;
        });

        // Atualizar a câmera do mapa quando a localização for obtida
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _hospitalLocation,
                zoom: 15,
              ),
            ),
          );
          print('🎯 Câmera do mapa atualizada para a nova localização');
        }
      } else {
        throw Exception(
            'Nenhuma localização encontrada para o endereço fornecido');
      }
    } catch (e) {
      print('❌ Erro final ao buscar localização: $e');

      // Se ainda não temos uma localização, usar coordenadas da cidade
      if (_hospitalLocation == const LatLng(-3.7504, -38.5017)) {
        // Coordenadas aproximadas das principais cidades
        final Map<String, LatLng> cidadesCoords = {
          'FORTALEZA': const LatLng(-3.7319, -38.5267),
          'SAO PAULO': const LatLng(-23.5505, -46.6333),
          'RIO DE JANEIRO': const LatLng(-22.9068, -43.1729),
          'SALVADOR': const LatLng(-12.9714, -38.5014),
          'RECIFE': const LatLng(-8.0476, -34.8770),
          'BELO HORIZONTE': const LatLng(-19.9167, -43.9345),
          'PORTO ALEGRE': const LatLng(-30.0346, -51.2177),
          'CURITIBA': const LatLng(-25.4290, -49.2671),
          'MANAUS': const LatLng(-3.1190, -60.0217),
          'BRASILIA': const LatLng(-15.7801, -47.9292),
          'NATAL': const LatLng(-5.7793, -35.2009),
          'FLORIANOPOLIS': const LatLng(-27.5954, -48.5480),
          'VITORIA': const LatLng(-20.2976, -40.2958),
          'JOAO PESSOA': const LatLng(-7.1195, -34.8450),
          'MACEIO': const LatLng(-9.6498, -35.7089),
        };

        // Tenta encontrar coordenadas da cidade do hospital
        final cidadeNormalizada =
            widget.hospital.cidadeFormatada.toUpperCase().trim();
        if (cidadesCoords.containsKey(cidadeNormalizada)) {
          setState(() {
            _hospitalLocation = cidadesCoords[cidadeNormalizada]!;
            _isLoading = false;
            _errorMessage =
                'Mostrando localização aproximada da cidade ${widget.hospital.cidadeFormatada}';
          });

          // Atualiza a câmera para a nova localização
          if (_mapController != null && mounted) {
            await _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: _hospitalLocation,
                  zoom: 13, // Zoom mais distante para mostrar mais da cidade
                ),
              ),
            );
          }

          // Mostra mensagem para o usuário
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Usando localização aproximada de ${widget.hospital.cidadeFormatada}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      // Se não conseguiu usar coordenadas da cidade, mostra erro
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Não foi possível encontrar a localização do hospital. Verifique o endereço e tente novamente.';
      });

      // Mostrar mensagem de erro detalhada para o usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Erro ao carregar localização:'),
                const SizedBox(height: 4),
                Text(
                  'Endereço: ${widget.hospital.address}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Cidade: ${widget.hospital.cidadeFormatada}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Tentar Novamente',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _getHospitalLocation();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _openInGoogleMaps() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${_hospitalLocation.latitude},${_hospitalLocation.longitude}';

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao abrir o Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localização do Hospital'),
        backgroundColor: Colors.lightBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInGoogleMaps,
            tooltip: 'Abrir no Google Maps',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Carregando localização...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _getHospitalLocation();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[200],
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _hospitalLocation,
              zoom: 16,
            ),
            mapType: MapType.normal,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) async {
              print('🗺️ Iniciando criação do mapa...');
              try {
                _mapController = controller;
                print('✅ Controlador do mapa inicializado');

                // Aplica o estilo personalizado
                await controller.setMapStyle(_mapStyle);
                print('✨ Estilo do mapa aplicado com sucesso');

                // Atualiza a câmera para a localização atual
                print(
                    '📍 Movendo câmera para: ${_hospitalLocation.latitude}, ${_hospitalLocation.longitude}');
                await controller.moveCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _hospitalLocation,
                      zoom: 16,
                    ),
                  ),
                );
                print('✅ Câmera movida com sucesso');
                print('🗺️ Mapa criado e configurado com sucesso!');
              } catch (e) {
                print('❌ Erro ao configurar o mapa: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao carregar o mapa: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'Tentar Novamente',
                        textColor: Colors.white,
                        onPressed: () {
                          if (_mapController != null) {
                            _mapController!.moveCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: _hospitalLocation,
                                  zoom: 16,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ),
        // Botão flutuante para abrir no Google Maps
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _openInGoogleMaps,
            label: const Text('Abrir no Google Maps'),
            icon: const Icon(Icons.directions),
            backgroundColor: Colors.lightBlue,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
