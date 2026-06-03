import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

class LocationViewModel extends ChangeNotifier {
  LocationViewModel({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  final LocationService _locationService;

  LatLng? _ubicacionUsuario;
  LatLng? _ubicacionTienda;
  String _nombreTienda = 'TECHNOVATE Sancarlos';
  String _distancia = '';
  String _duracion = '';
  bool _cargando = true;
  String? _error;

  LatLng? get ubicacionUsuario => _ubicacionUsuario;
  LatLng? get ubicacionTienda => _ubicacionTienda;
  String get nombreTienda => _nombreTienda;
  String get distancia => _distancia;
  String get duracion => _duracion;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> recargar() async {
    _cargando = true;
    _error = null;
    _distancia = '';
    _duracion = '';
    _ubicacionUsuario = null;
    _ubicacionTienda = null;
    notifyListeners();

    await cargarDatos();
  }

  Future<void> cargarDatos() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Obtener ubicación de la tienda
      final tiendaInfo = await _locationService.obtenerUbicacionTienda();
      _nombreTienda = tiendaInfo['nombre'] as String;
      _ubicacionTienda = tiendaInfo['posicion'] as LatLng;

      // 2. Obtener ubicación del usuario
      _ubicacionUsuario = await _locationService.obtenerUbicacionUsuario();

      // 3. Obtener ruta si ambos están listos
      if (_ubicacionUsuario != null && _ubicacionTienda != null) {
        final ruta = await _locationService.obtenerDistanciaYDuracion(
          _ubicacionUsuario!,
          _ubicacionTienda!,
        );
        _distancia = ruta['distancia'] ?? '';
        _duracion = ruta['duracion'] ?? '';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
