import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/cart_item_model.dart';

class CheckoutService {
  CheckoutService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> finishPurchase(List<CartItemModel> items) async {
    for (final item in List<CartItemModel>.of(items)) {
      final doc = await _firestore
          .collection(digizoneColeccion)
          .doc(item.idProducto)
          .get();

      if (!doc.exists) {
        throw Exception('El producto "${item.titulo}" ya no existe');
      }

      final data = doc.data() ?? {};
      final stock = ((data['inventario'] ?? 0) as num).toInt();
      if (stock < item.cantidad) {
        throw Exception(
          'Stock insuficiente para "${item.titulo}" (disponible: $stock)',
        );
      }

      await doc.reference.update({
        'inventario': stock - item.cantidad,
        if (stock - item.cantidad == 0) 'disponible': false,
      });
    }
  }
}
