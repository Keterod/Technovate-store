import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'digizone_utils.dart';

const String googleMapsApiKey = 'AIzaSyBIZrptkE0IGakPhzMzMpq4PaW_gw_D1vk';

class UbicacionScreen extends StatefulWidget {
  const UbicacionScreen({super.key});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  LatLng? ubicacionUsuario;
  LatLng? ubicacionTienda;
  String nombreTienda = 'TECHNOVATE Sancarlos';
  String distancia = '';
  String duracion = '';
  bool cargando = true;
  String? error;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    mapController?.dispose();
    mapController = null;
    super.dispose();
  }

  Future<void> _recargar() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
      distancia = '';
      duracion = '';
      ubicacionUsuario = null;
      ubicacionTienda = null;
      mapController = null;
    });

    await _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      cargando = true;
      error = null;
      distancia = '';
      duracion = '';
    });

    try {
      await Future.wait([
        _obtenerUbicacionTienda(),
        _obtenerUbicacionUsuario(),
      ]);

      if (ubicacionUsuario != null && ubicacionTienda != null) {
        await _obtenerDistanciaYDuracion();
        await _ajustarCamara();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  Future<void> _obtenerUbicacionUsuario() async {
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
        'Permiso de ubicación denegado permanentemente. '
        'Actívalo en la configuración del dispositivo.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    ubicacionUsuario = LatLng(position.latitude, position.longitude);
  }

  Future<void> _obtenerUbicacionTienda() async {
    final doc = await FirebaseFirestore.instance
        .collection('configuracion')
        .doc('tienda')
        .get();

    if (!doc.exists) {
      throw Exception('No se encontró la configuración de la tienda');
    }

    final data = doc.data();
    final geo = data?['ubicacion'] as GeoPoint?;
    if (geo == null) {
      throw Exception('La tienda no tiene ubicación configurada');
    }

    nombreTienda = (data?['nombre'] ?? 'TECHNOVATE Sancarlos').toString();
    ubicacionTienda = LatLng(geo.latitude, geo.longitude);
  }

  Future<void> _obtenerDistanciaYDuracion() async {
    if (ubicacionUsuario == null || ubicacionTienda == null) return;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${ubicacionUsuario!.latitude},${ubicacionUsuario!.longitude}'
      '&destination=${ubicacionTienda!.latitude},${ubicacionTienda!.longitude}'
      '&key=$googleMapsApiKey'
      '&mode=driving',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Error al consultar Directions API (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status']?.toString() ?? '';
    if (status != 'OK') {
      throw Exception(
        'Directions API: ${data['error_message'] ?? status}',
      );
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
    distancia = (leg['distance']?['text'] ?? '').toString();
    duracion = (leg['duration']?['text'] ?? '').toString();
  }

  Future<void> _ajustarCamara() async {
    if (ubicacionUsuario == null || ubicacionTienda == null) return;

    final controller = mapController;
    if (!mounted || controller == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        ubicacionUsuario!.latitude < ubicacionTienda!.latitude
            ? ubicacionUsuario!.latitude
            : ubicacionTienda!.latitude,
        ubicacionUsuario!.longitude < ubicacionTienda!.longitude
            ? ubicacionUsuario!.longitude
            : ubicacionTienda!.longitude,
      ),
      northeast: LatLng(
        ubicacionUsuario!.latitude > ubicacionTienda!.latitude
            ? ubicacionUsuario!.latitude
            : ubicacionTienda!.latitude,
        ubicacionUsuario!.longitude > ubicacionTienda!.longitude
            ? ubicacionUsuario!.longitude
            : ubicacionTienda!.longitude,
      ),
    );

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    } catch (_) {
      // Ignorar si el mapa ya fue destruido
    }
  }

  Future<void> _abrirGoogleMaps() async {
    if (ubicacionTienda == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación de tienda no disponible')),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${ubicacionTienda!.latitude},${ubicacionTienda!.longitude}',
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
    if (ubicacionUsuario != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('usuario'),
          position: ubicacionUsuario!,
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    if (ubicacionTienda != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('tienda'),
          position: ubicacionTienda!,
          infoWindow: InfoWindow(title: nombreTienda),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Ubicación'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _recargar,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _recargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (ubicacionUsuario == null || ubicacionTienda == null) {
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
              target: ubicacionUsuario!,
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                nombreTienda,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.straighten, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    distancia.isEmpty ? 'Distancia: —' : 'Distancia: $distancia',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    duracion.isEmpty
                        ? 'Tiempo estimado: —'
                        : 'Tiempo estimado: $duracion',
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
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
