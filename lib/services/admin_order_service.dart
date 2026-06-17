import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_order_item.dart';
import '../models/order_model.dart';

class AdminOrderService {
  final FirebaseFirestore _firestore;

  AdminOrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<AdminOrderItem>> watchAllOrders() {
    return _firestore
        .collectionGroup('Pedidos')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final parts = doc.reference.path.split('/');
              final uid = parts[1];
              return AdminOrderItem(
                uid: uid,
                orderId: doc.id,
                order: OrderModel.fromFirestore(doc),
              );
            }).toList());
  }

  Future<void> actualizarEstado(String uid, String orderId, String nuevoEstado) async {
    await _firestore
        .collection('Usuarios')
        .doc(uid)
        .collection('Pedidos')
        .doc(orderId)
        .update({'estado': nuevoEstado});
  }
}
