import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/widgets/technovate_widgets.dart';
import '../../services/location_service.dart';

class MapaPickerResult {
  final LatLng posicion;
  final String direccion;
  final String ciudad;

  MapaPickerResult({
    required this.posicion,
    required this.direccion,
    required this.ciudad,
  });
}

class MapaPickerScreen extends StatefulWidget {
  const MapaPickerScreen({super.key});

  @override
  State<MapaPickerScreen> createState() => _MapaPickerScreenState();
}

class _MapaPickerScreenState extends State<MapaPickerScreen> {
  final LocationService _locationService = LocationService();
  LatLng? _posicionActual;
  late LatLng _pinPosicion;
  bool _cargandoInicial = true;
  bool _buscandoDireccion = false;
  String _direccion = '';
  String _ciudad = '';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await _locationService.obtenerUbicacionUsuario();
      _posicionActual = pos;
      _pinPosicion = pos;
      await _reverseGeocode(pos);
    } catch (e) {
      _pinPosicion = const LatLng(-12.062106, -77.036528);
    }
    if (mounted) setState(() => _cargandoInicial = false);
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _buscandoDireccion = true);
    try {
      final result = await _locationService.reverseGeocode(pos);
      _direccion = result['direccion'] ?? '';
      _ciudad = result['ciudad'] ?? '';
    } catch (_) {
      _direccion = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      _ciudad = '';
    }
    if (mounted) setState(() => _buscandoDireccion = false);
  }

  void _onCameraMove(CameraPosition pos) {
    _pinPosicion = pos.target;
  }

  Future<void> _onCameraIdle() async {
    await _reverseGeocode(_pinPosicion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Seleccionar ubicación'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _buscandoDireccion || _cargandoInicial
                ? null
                : () => Navigator.pop(
                      context,
                      MapaPickerResult(
                        posicion: _pinPosicion,
                        direccion: _direccion,
                        ciudad: _ciudad,
                      ),
                    ),
            child: const Text('Elegir'),
          ),
        ],
      ),
      body: _cargandoInicial
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pinPosicion,
                    zoom: 16,
                  ),
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 48, color: Colors.red.shade700),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_cargandoInicial)
                  const Center(child: CircularProgressIndicator()),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          if (_buscandoDireccion)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(Icons.location_on_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _direccion.isEmpty ? 'Arrastra el mapa para elegir' : _direccion,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
