import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class SucursalInfo {
  final String nombre;
  final String direccion;
  final LatLng posicion;

  SucursalInfo({
    required this.nombre,
    required this.direccion,
    required this.posicion,
  });
}

class LocationService {
  LocationService({FirebaseFirestore? firestore, http.Client? httpClient})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _client = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final http.Client _client;
  static const String _googleMapsApiKey =
      'AIzaSyBIZrptkE0IGakPhzMzMpq4PaW_gw_D1vk';
  static const Duration _timeout = Duration(seconds: 10);

  Future<LatLng> obtenerUbicacionUsuario() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
      _timeout,
    );
    if (!serviceEnabled) {
      throw Exception('El servicio de ubicación está desactivado');
    }

    var permission = await Geolocator.checkPermission().timeout(_timeout);
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission().timeout(_timeout);
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permiso de ubicación denegado permanentemente. Actívalo en la configuración.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(_timeout);

    return LatLng(position.latitude, position.longitude);
  }

  Future<Map<String, dynamic>> obtenerUbicacionTienda() async {
    final doc = await _firestore
        .collection('configuracion')
        .doc('tienda')
        .get()
        .timeout(_timeout);

    if (!doc.exists) {
      throw Exception('No se encontró la configuración de la tienda');
    }

    final data = doc.data() ?? {};
    final geo = data['ubicacion'] as GeoPoint?;
    if (geo == null) {
      throw Exception('La tienda no tiene ubicación configurada');
    }

    return {
      'nombre': (data['nombre'] ?? 'TECHNOVATE Sancarlos').toString(),
      'direccion': (data['direccion'] ?? '').toString(),
      'posicion': LatLng(geo.latitude, geo.longitude),
    };
  }

  Future<List<SucursalInfo>> obtenerSucursales() async {
    final snap = await _firestore
        .collection('sucursales')
        .get()
        .timeout(_timeout);
    final list = <SucursalInfo>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final geo = data['ubicacion'] as GeoPoint?;
      if (geo == null) continue;
      list.add(
        SucursalInfo(
          nombre: (data['nombre'] ?? '').toString(),
          direccion: (data['direccion'] ?? '').toString(),
          posicion: LatLng(geo.latitude, geo.longitude),
        ),
      );
    }
    return list;
  }

  Future<Map<String, String>> obtenerDistanciaYDuracion(
    LatLng origin,
    LatLng destination,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&key=$_googleMapsApiKey'
      '&mode=driving',
    );

    final response = await _client.get(url).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Error al conectar con el servidor de mapas (${response.statusCode})');
      throw Exception(
        'Error al consultar Directions API (${response.statusCode})',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status']?.toString() ?? '';
    if (status != 'OK') {
      String mensajeError = 'Error de conexión con el servicio de mapas.';
      final apiMsg = data['error_message']?.toString() ?? '';
      
      if (status == 'REQUEST_DENIED') {
        mensajeError = 'La API de Directions no está habilitada o autorizada en la consola de Google Cloud para este proyecto. Por favor, actívala en tu consola de Google Cloud para permitir el trazado de rutas.';
      } else if (status == 'ZERO_RESULTS') {
        mensajeError = 'No se encontró ninguna ruta de conducción disponible entre tu ubicación y la tienda.';
      } else if (status == 'OVER_QUERY_LIMIT') {
        mensajeError = 'Se ha excedido el límite de consultas para el mapa. Inténtalo más tarde.';
      } else if (apiMsg.isNotEmpty) {
        mensajeError = 'Error de mapas: $apiMsg';
      }
      throw Exception(mensajeError);
    }

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw Exception('No se encontró ruta entre tu ubicación y la tienda');
    }

    final legs = routes[0]['legs'] as List<dynamic>?;
    if (legs == null || legs.isEmpty) {
      throw Exception('No se encontraron datos de distancia');
    }

    final leg = legs[0] as Map<String, dynamic>;
    return {
      'distancia': (leg['distance']?['text'] ?? '').toString(),
      'duracion': (leg['duration']?['text'] ?? '').toString(),
    };
  }

  Future<Map<String, String>> reverseGeocode(LatLng pos) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=${pos.latitude},${pos.longitude}'
      '&key=$_googleMapsApiKey'
      '&language=es',
    );
    final response = await _client.get(url).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception(
        'Error al consultar Geocoding API (${response.statusCode})',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status']?.toString() ?? '';
    if (status != 'OK') {
      throw Exception('Geocoding API: ${data['error_message'] ?? status}');
    }
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      throw Exception('No se encontró dirección para esta ubicación');
    }

    final first = results[0] as Map<String, dynamic>;
    final formattedAddress = (first['formatted_address'] ?? '').toString();

    String city = '';
    final components = first['address_components'] as List<dynamic>?;
    if (components != null) {
      for (final c in components) {
        final comp = c as Map<String, dynamic>;
        final types =
            (comp['types'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toSet() ??
            {};
        if (types.contains('locality') && city.isEmpty) {
          city = (comp['long_name'] ?? '').toString();
        }
        if (types.contains('administrative_area_level_1') && city.isEmpty) {
          city = (comp['long_name'] ?? '').toString();
        }
      }
    }

    return {'direccion': formattedAddress, 'ciudad': city};
  }
}
