import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_order_item.dart';
import '../models/order_model.dart';

class AdminOrderService {
  final FirebaseFirestore _firestore;

  AdminOrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<AdminOrderItem>> watchAllOrders() {
    debugPrint('DEBUG ADMIN ORDERS: unordered collectionGroup stream start');
    return _firestore.collectionGroup('Pedidos').limit(50).snapshots().map((
      snap,
    ) {
      final rows = _mapSnapshot(snap);
      rows.sort(
        (a, b) => b.order.fechaCreacion.compareTo(a.order.fechaCreacion),
      );
      return rows;
    });
  }

  List<AdminOrderItem> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final rows = snap.docs.map((doc) {
      final data = doc.data();
      final rawStatus = data['estado']?.toString();
      final normalizedStatus = normalizeOrderStatus(rawStatus);
      debugPrint(
        'DEBUG ADMIN ORDERS: raw status=$rawStatus normalized=$normalizedStatus',
      );
      final parts = doc.reference.path.split('/');
      final uid = parts.length > 1 ? parts[1] : '';
      return AdminOrderItem(
        uid: uid,
        orderId: doc.id,
        order: OrderModel.fromFirestore(doc),
      );
    }).toList();
    debugPrint('DEBUG ADMIN ORDERS: rows=${rows.length}');
    return rows;
  }

  Future<void> actualizarEstado(
    String uid,
    String orderId,
    String nuevoEstado,
  ) async {
    final normalizedStatus = normalizeOrderStatus(nuevoEstado);
    debugPrint(
      'DEBUG ADMIN ORDERS: update status orderId=$orderId status=$normalizedStatus',
    );
    await _firestore
        .collection('Usuarios')
        .doc(uid)
        .collection('Pedidos')
        .doc(orderId)
        .update({'estado': normalizedStatus});
  }
}
