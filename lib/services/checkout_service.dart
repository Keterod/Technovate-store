import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/cart_item_model.dart';

class CheckoutService {
  CheckoutService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _firestoreTimeout = Duration(seconds: 15);

  Future<void> finishPurchase(List<CartItemModel> items) async {
    if (items.isEmpty) return;

    debugPrint('DEBUG CHECKOUT: stock update start');
    for (final item in items) {
      final productPath = _firestore
          .collection(digizoneColeccion)
          .doc(item.idProducto)
          .path;
      debugPrint('DEBUG ORDER: product path=$productPath');
      debugPrint(
        'DEBUG ORDER: product update keys=[inventario, disponible(if stock reaches 0)]',
      );
    }
    try {
      await _firestore
          .runTransaction((transaction) async {
            final refs = items
                .map(
                  (item) => _firestore
                      .collection(digizoneColeccion)
                      .doc(item.idProducto),
                )
                .toList();
            final docs = <DocumentSnapshot<Map<String, dynamic>>>[];
            for (final ref in refs) {
              docs.add(await transaction.get(ref));
            }

            for (var i = 0; i < items.length; i++) {
              final item = items[i];
              final doc = docs[i];
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

              final nuevoStock = stock - item.cantidad;
              final updateData = {
                'inventario': nuevoStock,
                if (nuevoStock == 0) 'disponible': false,
              };
              debugPrint(
                'DEBUG ORDER: product update keys=${updateData.keys.toList()}',
              );
              transaction.update(doc.reference, updateData);
            }
          })
          .timeout(_firestoreTimeout);
      debugPrint('DEBUG CHECKOUT: stock update done');
    } on TimeoutException catch (e, stackTrace) {
      debugPrint('DEBUG CHECKOUT: stock update timeout error=$e');
      debugPrint('DEBUG CHECKOUT: stock update stack=$stackTrace');
      throw Exception('No se pudo confirmar el pedido. Intenta nuevamente.');
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        'DEBUG CHECKOUT: stock update firebase error code=${e.code} message=${e.message}',
      );
      debugPrint('DEBUG CHECKOUT: stock update stack=$stackTrace');
      throw Exception('No se pudo confirmar el pedido. Intenta nuevamente.');
    } catch (e, stackTrace) {
      debugPrint('DEBUG CHECKOUT: stock update error=$e');
      debugPrint('DEBUG CHECKOUT: stock update stack=$stackTrace');
      rethrow;
    }
  }
}
