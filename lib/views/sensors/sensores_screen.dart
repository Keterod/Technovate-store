import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensoresScreen extends StatefulWidget {
  const SensoresScreen({super.key});

  @override
  State<SensoresScreen> createState() => _SensoresScreenState();
}

class _SensoresScreenState extends State<SensoresScreen> {
  List<double>? _accelerometerValues;
  List<double>? _gyroscopeValues;
  List<double>? _magnetometerValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  Position? _posicion;
  double? _heading;
  LatLng? _ubicacionTienda;
  String _nombreTienda = '';
  double? _anguloBrujula;
  StreamSubscription<Position>? _gpsSubscription;

  bool _accelerometerTimeout = false;
  bool _gyroscopeTimeout = false;
  bool _magnetometerTimeout = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _iniciarSensores();
    _iniciarGps();
    _cargarUbicacionTienda();
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          if (_accelerometerValues == null) _accelerometerTimeout = true;
          if (_gyroscopeValues == null) _gyroscopeTimeout = true;
          if (_magnetometerValues == null) _magnetometerTimeout = true;
        });
      }
    });
  }

  void _iniciarSensores() {
    _streamSubscriptions.add(
      accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          if (!mounted) return;
          setState(() {
            _accelerometerValues = [event.x, event.y, event.z];
          });
        },
        onError: (e) => debugPrint('Error acelerómetro: $e'),
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          if (!mounted) return;
          setState(() {
            _gyroscopeValues = [event.x, event.y, event.z];
          });
        },
        onError: (e) => debugPrint('Error giroscopio: $e'),
      ),
    );
    _streamSubscriptions.add(
      magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          if (!mounted) return;
          _magnetometerValues = [event.x, event.y, event.z];
          final heading = _calcularHeading(event.x, event.y);
          _anguloBrujula = heading;
          setState(() {});
        },
        onError: (e) => debugPrint('Error magnetómetro: $e'),
      ),
    );
  }

  double _calcularHeading(double x, double y) {
    final angle = math.atan2(y, x) * (180 / math.pi);
    return (angle + 360) % 360;
  }

  Future<void> _iniciarGps() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((position) {
      if (!mounted) return;
      setState(() {
        _posicion = position;
        _heading = position.heading;
      });
    });
  }

  Future<void> _cargarUbicacionTienda() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('tienda')
          .get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      final geo = data['ubicacion'] as GeoPoint?;
      if (geo == null) return;
      setState(() {
        _ubicacionTienda = LatLng(geo.latitude, geo.longitude);
        _nombreTienda = (data['nombre'] ?? 'TECHNOVATE Sancarlos').toString();
      });
    } catch (_) {}
  }

  double? get _rumboATienda {
    if (_posicion == null || _ubicacionTienda == null) return null;
    return _calcularRumbo(
      _posicion!.latitude,
      _posicion!.longitude,
      _ubicacionTienda!.latitude,
      _ubicacionTienda!.longitude,
    );
  }

  double? get _distanciaATienda {
    if (_posicion == null || _ubicacionTienda == null) return null;
    return Geolocator.distanceBetween(
      _posicion!.latitude,
      _posicion!.longitude,
      _ubicacionTienda!.latitude,
      _ubicacionTienda!.longitude,
    );
  }

  double _calcularRumbo(
    double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * (math.pi / 180);
    final y = math.sin(dLon) * math.cos(lat2 * (math.pi / 180));
    final x = math.cos(lat1 * (math.pi / 180)) * math.sin(lat2 * (math.pi / 180))
        - math.sin(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) * math.cos(dLon);
    final angle = math.atan2(y, x) * (180 / math.pi);
    return (angle + 360) % 360;
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _gpsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accelerometer = _accelerometerValues
        ?.map((v) => v.toStringAsFixed(2))
        .toList();
    final gyroscope = _gyroscopeValues
        ?.map((v) => v.toStringAsFixed(2))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensores y Geolocalización'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCompassCard(context),
            const SizedBox(height: 16),
            _buildGpsCard(context),
            const SizedBox(height: 16),
            _SensorCard(
              title: 'Acelerómetro',
              icon: Icons.speed,
              values: accelerometer,
              labels: const ['X', 'Y', 'Z'],
              color: Colors.blue,
              timeout: _accelerometerTimeout,
            ),
            const SizedBox(height: 16),
            _SensorCard(
              title: 'Giroscopio',
              icon: Icons.sync,
              values: gyroscope,
              labels: const ['X', 'Y', 'Z'],
              color: Colors.green,
              timeout: _gyroscopeTimeout,
            ),
            const SizedBox(height: 16),
            _SensorCard(
              title: 'Magnetómetro',
              icon: Icons.explore,
              values: _magnetometerValues
                  ?.map((v) => v.toStringAsFixed(2))
                  .toList(),
              labels: const ['X', 'Y', 'Z'],
              color: Colors.red,
              timeout: _magnetometerTimeout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassCard(BuildContext context) {
    final rumbo = _rumboATienda;
    final brujula = _anguloBrujula ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.explore, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Brújula — Tienda',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_nombreTienda.isNotEmpty)
              Text(
                _nombreTienda,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (rumbo != null)
                    Transform.rotate(
                      angle: ((rumbo - brujula) * math.pi / 180),
                      child: const Icon(Icons.room, size: 48, color: Colors.red),
                    ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              rumbo != null ? '${rumbo.toStringAsFixed(0)}° ${_cardinal(rumbo)}' : '---',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (_distanciaATienda != null)
              Text(
                'Distancia: ${_formatearDistancia(_distanciaATienda!)}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsCard(BuildContext context) {
    final pos = _posicion;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gps_fixed, color: Colors.teal, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'GPS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (pos == null)
              const Center(child: Text('Esperando señal GPS...'))
            else ...[
              _gpsRow('Latitud', pos.latitude.toStringAsFixed(6)),
              _gpsRow('Longitud', pos.longitude.toStringAsFixed(6)),
              _gpsRow('Altitud', '${pos.altitude.toStringAsFixed(1)} m'),
              _gpsRow('Precisión', '±${pos.accuracy.toStringAsFixed(0)} m'),
              _gpsRow('Velocidad',
                  pos.speed >= 0 ? '${(pos.speed * 3.6).toStringAsFixed(1)} km/h' : '---'),
              if (_heading != null && _heading! >= 0)
                _gpsRow('Dirección',
                    '${_heading!.toStringAsFixed(0)}° ${_cardinal(_heading!)}'),
              Row(
                children: [
                  Icon(Icons.satellite, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Satélites usados: ${_posicion?.isMocked == true ? "Mock" : "---"}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gpsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 15, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  String _cardinal(double degrees) {
    const cardinals = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    return cardinals[(degrees / 45).round() % 8];
  }

  String _formatearDistancia(double metros) {
    if (metros < 1000) return '${metros.toStringAsFixed(0)} m';
    return '${(metros / 1000).toStringAsFixed(2)} km';
  }
}

class _SensorCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String>? values;
  final List<String> labels;
  final Color color;
  final bool timeout;

  const _SensorCard({
    required this.title,
    required this.icon,
    required this.values,
    required this.labels,
    required this.color,
    required this.timeout,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (values == null)
              Center(
                child: timeout
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Sensor no detectado o no disponible',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      )
                    : const CircularProgressIndicator(),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(values!.length, (index) {
                  return Column(
                    children: [
                      Text(
                        labels[index],
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        values![index],
                        style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
                      ),
                    ],
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
