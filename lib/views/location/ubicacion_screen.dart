import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/technovate_widgets.dart';
import '../../viewmodels/location_view_model.dart';

class UbicacionScreen extends StatefulWidget {
  const UbicacionScreen({super.key});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  late final LocationViewModel _viewModel;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    _viewModel = LocationViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.cargarDatos();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    mapController?.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    setState(() {});
    if (_viewModel.ubicacionUsuario != null && _viewModel.ubicacionTienda != null) {
      _ajustarCamara();
    }
  }

  Future<void> _ajustarCamara() async {
    if (_viewModel.ubicacionUsuario == null || _viewModel.ubicacionTienda == null) return;

    final controller = mapController;
    if (!mounted || controller == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _viewModel.ubicacionUsuario!.latitude < _viewModel.ubicacionTienda!.latitude
            ? _viewModel.ubicacionUsuario!.latitude
            : _viewModel.ubicacionTienda!.latitude,
        _viewModel.ubicacionUsuario!.longitude < _viewModel.ubicacionTienda!.longitude
            ? _viewModel.ubicacionUsuario!.longitude
            : _viewModel.ubicacionTienda!.longitude,
      ),
      northeast: LatLng(
        _viewModel.ubicacionUsuario!.latitude > _viewModel.ubicacionTienda!.latitude
            ? _viewModel.ubicacionUsuario!.latitude
            : _viewModel.ubicacionTienda!.latitude,
        _viewModel.ubicacionUsuario!.longitude > _viewModel.ubicacionTienda!.longitude
            ? _viewModel.ubicacionUsuario!.longitude
            : _viewModel.ubicacionTienda!.longitude,
      ),
    );

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    } catch (_) {
    }
  }

  Future<void> _abrirGoogleMaps() async {
    if (_viewModel.ubicacionTienda == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación de la tienda no disponible')),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${_viewModel.ubicacionTienda!.latitude},${_viewModel.ubicacionTienda!.longitude}',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps')),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_viewModel.ubicacionUsuario != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('usuario'),
          position: _viewModel.ubicacionUsuario!,
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    if (_viewModel.ubicacionTienda != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('tienda'),
          position: _viewModel.ubicacionTienda!,
          infoWindow: InfoWindow(title: _viewModel.nombreTienda),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Ubicación'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => _viewModel.recargar(),
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_viewModel.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _viewModel.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _viewModel.recargar(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewModel.ubicacionUsuario == null || _viewModel.ubicacionTienda == null) {
      return const Center(
        child: Text('No se pudo obtener la ubicación necesaria'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _viewModel.ubicacionUsuario!,
              zoom: 14,
            ),
            markers: _buildMarkers(),
            onMapCreated: (controller) {
              if (!mounted) {
                controller.dispose();
                return;
              }
              mapController = controller;
              _ajustarCamara();
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),
        ),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _viewModel.nombreTienda,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (_viewModel.direccionTienda.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.store, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _viewModel.direccionTienda,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_viewModel.direccionUsuario.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.home, size: 18, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _viewModel.direccionUsuario,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.straighten, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        _viewModel.distancia.isEmpty
                            ? 'Distancia: —'
                            : 'Distancia: ${_viewModel.distancia}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        _viewModel.duracion.isEmpty
                            ? 'Tiempo estimado: —'
                            : 'Tiempo estimado: ${_viewModel.duracion}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _abrirGoogleMaps,
                    icon: const Icon(Icons.map),
                    label: const Text('Abrir en Google Maps'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
