import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/profile_service.dart';

class LocationViewModel extends ChangeNotifier {
  LocationViewModel({
    LocationService? locationService,
    ProfileService? profileService,
  })  : _locationService = locationService ?? LocationService(),
        _profileService = profileService ?? ProfileService();

  final LocationService _locationService;
  final ProfileService _profileService;

  LatLng? _ubicacionUsuario;
  LatLng? _ubicacionTienda;
  String _nombreTienda = 'TECHNOVATE Sancarlos';
  String _direccionTienda = '';
  String _direccionUsuario = '';
  String _distancia = '';
  String _duracion = '';
  bool _cargando = true;
  String? _error;

  LatLng? get ubicacionUsuario => _ubicacionUsuario;
  LatLng? get ubicacionTienda => _ubicacionTienda;
  String get nombreTienda => _nombreTienda;
  String get direccionTienda => _direccionTienda;
  String get direccionUsuario => _direccionUsuario;
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
      final results = await Future.wait([
        _locationService.obtenerUbicacionTienda(),
        _locationService.obtenerUbicacionUsuario(),
        _profileService.getProfile(),
      ]);

      final tiendaInfo = results[0] as Map<String, dynamic>;
      _nombreTienda = tiendaInfo['nombre'] as String;
      _direccionTienda = tiendaInfo['direccion'] as String;
      _ubicacionTienda = tiendaInfo['posicion'] as LatLng;

      _ubicacionUsuario = results[1] as LatLng;

      final perfil = results[2] as UserProfile;
      if (perfil.direccion.isNotEmpty) {
        _direccionUsuario =
            '${perfil.direccion}${perfil.ciudad.isNotEmpty ? ', ${perfil.ciudad}' : ''}';
      }

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
