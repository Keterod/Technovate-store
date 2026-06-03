import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final List<Map<String, dynamic>> items;
  final double total;
  final Map<String, String> direccion;
  final String metodoPago;
  final String estado;
  final DateTime fechaCreacion;
  final String numeroOrden;

  const OrderModel({
    required this.id,
    required this.items,
    required this.total,
    required this.direccion,
    required this.metodoPago,
    required this.estado,
    required this.fechaCreacion,
    required this.numeroOrden,
  });

  int get totalItems =>
      items.fold(0, (total, item) => total + (item['cantidad'] as int));

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return OrderModel(
      id: doc.id,
      items: List<Map<String, dynamic>>.from(data['items'] as List? ?? []),
      total: ((data['total'] ?? 0) as num).toDouble(),
      direccion: Map<String, String>.from(data['direccion'] as Map? ?? {}),
      metodoPago: (data['metodoPago'] ?? '').toString(),
      estado: (data['estado'] ?? 'pendiente').toString(),
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      numeroOrden: (data['numeroOrden'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'items': items,
      'total': total,
      'direccion': direccion,
      'metodoPago': metodoPago,
      'estado': estado,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'numeroOrden': numeroOrden,
    };
  }
}
