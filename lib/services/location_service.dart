import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationService {
  LocationService({
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _client = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final http.Client _client;
  static const String _googleMapsApiKey = 'AIzaSyBIZrptkE0IGakPhzMzMpq4PaW_gw_D1vk';

  Future<LatLng> obtenerUbicacionUsuario() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El servicio de ubicación está desactivado');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LatLng(position.latitude, position.longitude);
  }

  Future<Map<String, dynamic>> obtenerUbicacionTienda() async {
    final doc = await _firestore.collection('configuracion').doc('tienda').get();

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

    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Error al consultar Directions API (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status']?.toString() ?? '';
    if (status != 'OK') {
      throw Exception('Directions API: ${data['error_message'] ?? status}');
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
}
