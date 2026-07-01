import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> adminOrderStatuses = [
  'pendiente',
  'confirmado',
  'enviado',
  'entregado',
  'cancelado',
];

String normalizeOrderStatus(String? value) {
  final raw = (value ?? '').trim().toLowerCase();

  switch (raw) {
    case 'pendiente':
      return 'pendiente';
    case 'confirmado':
    case 'procesando':
    case 'en proceso':
      return 'confirmado';
    case 'enviado':
      return 'enviado';
    case 'entregado':
    case 'completado':
      return 'entregado';
    case 'cancelado':
      return 'cancelado';
    default:
      return 'pendiente';
  }
}

String orderStatusLabel(String value) {
  final normalized = normalizeOrderStatus(value);
  return normalized[0].toUpperCase() + normalized.substring(1);
}

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
      estado: normalizeOrderStatus(data['estado']?.toString()),
      fechaCreacion:
          (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      numeroOrden: (data['numeroOrden'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'items': items,
      'total': total,
      'direccion': direccion,
      'metodoPago': metodoPago,
      'estado': normalizeOrderStatus(estado),
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'numeroOrden': numeroOrden,
    };
  }
}
