import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';

class OrderService {
  OrderService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static const Duration _firestoreTimeout = Duration(seconds: 15);

  String get _uid => _auth.currentUser?.uid ?? '';
  bool get _isAuthenticated => _auth.currentUser != null;

  String _generarNumeroOrden() {
    final now = DateTime.now();
    final fecha =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final aleatorio = DateTime.now().microsecondsSinceEpoch
        .toString()
        .substring(8);
    return 'TECH-$fecha-$aleatorio';
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('Usuarios').doc(_uid).collection('Pedidos');

  Future<OrderModel> crearPedido({
    required List<CartItemModel> cartItems,
    required Map<String, String> direccion,
    required String metodoPago,
    required double total,
  }) async {
    if (!_isAuthenticated) throw Exception('Debes iniciar sesión');
    if (cartItems.isEmpty) throw Exception('El carrito esta vacio');

    final stopwatch = Stopwatch()..start();
    final uid = _uid;
    debugPrint('DEBUG ORDER: create start');
    debugPrint('DEBUG ORDER: userId=$uid items=${cartItems.length}');

    final itemsData = cartItems
        .map(
          (item) => {
            'idProducto': item.idProducto,
            'titulo': item.titulo,
            'costo': item.costo,
            'cantidad': item.cantidad,
            'imagen': item.imagen,
          },
        )
        .toList();

    final numeroOrden = _generarNumeroOrden();
    final fechaLocal = DateTime.now();
    final orderRef = _firestore
        .collection('Usuarios')
        .doc(uid)
        .collection('Pedidos')
        .doc();

    final orderData = {
      'items': itemsData,
      'total': total,
      'direccion': direccion,
      'metodoPago': metodoPago,
      'estado': 'pendiente',
      'fechaCreacion': FieldValue.serverTimestamp(),
      'numeroOrden': numeroOrden,
    };

    debugPrint('DEBUG ORDER: order path=${orderRef.path}');
    debugPrint('DEBUG ORDER: order payload keys=${orderData.keys.toList()}');
    for (final item in cartItems) {
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
            final productRefs = cartItems
                .map(
                  (item) => _firestore
                      .collection(digizoneColeccion)
                      .doc(item.idProducto),
                )
                .toList();

            final productDocs = <DocumentSnapshot<Map<String, dynamic>>>[];
            for (final ref in productRefs) {
              productDocs.add(await transaction.get(ref));
            }

            debugPrint('DEBUG CHECKOUT: stock update start');
            for (var i = 0; i < cartItems.length; i++) {
              final item = cartItems[i];
              final doc = productDocs[i];
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
            debugPrint('DEBUG CHECKOUT: stock update done');

            debugPrint('DEBUG ORDER: write order start');
            transaction.set(orderRef, orderData);
            debugPrint('DEBUG ORDER: write order done');
          })
          .timeout(_firestoreTimeout);

      debugPrint(
        'DEBUG ORDER: create done ms=${stopwatch.elapsedMilliseconds}',
      );
      return OrderModel(
        id: orderRef.id,
        items: itemsData,
        total: total,
        direccion: direccion,
        metodoPago: metodoPago,
        estado: 'pendiente',
        fechaCreacion: fechaLocal,
        numeroOrden: numeroOrden,
      );
    } on TimeoutException catch (e, stackTrace) {
      debugPrint('DEBUG ORDER: create timeout error=$e');
      debugPrint('DEBUG ORDER: create stack=$stackTrace');
      throw Exception('No se pudo confirmar el pedido. Intenta nuevamente.');
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        'DEBUG ORDER: create firebase error code=${e.code} message=${e.message}',
      );
      debugPrint('DEBUG ORDER: create stack=$stackTrace');
      throw Exception('No se pudo confirmar el pedido. Intenta nuevamente.');
    } catch (e, stackTrace) {
      debugPrint('DEBUG ORDER: create error=$e');
      debugPrint('DEBUG ORDER: create stack=$stackTrace');
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  Stream<List<OrderModel>> watchOrders() {
    if (!_isAuthenticated) return Stream.value([]);
    return _collection
        .orderBy('fechaCreacion', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(OrderModel.fromFirestore).toList(),
        );
  }

  Future<List<OrderModel>> getOrders() async {
    if (!_isAuthenticated) return [];
    debugPrint('DEBUG ORDER: fetch history start');
    final snapshot = await _collection
        .orderBy('fechaCreacion', descending: true)
        .limit(20)
        .get()
        .timeout(_firestoreTimeout);
    debugPrint('DEBUG ORDER: fetch history rows=${snapshot.docs.length}');
    return snapshot.docs.map(OrderModel.fromFirestore).toList();
  }
}
