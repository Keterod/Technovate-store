import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item_model.dart';
import '../models/order_model.dart';

class OrderService {
  OrderService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser?.uid ?? '';
  bool get _isAuthenticated => _auth.currentUser != null;

  String _generarNumeroOrden() {
    final now = DateTime.now();
    final fecha = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final aleatorio = DateTime.now().microsecondsSinceEpoch.toString().substring(8);
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

    final itemsData = cartItems
        .map((item) => {
              'idProducto': item.idProducto,
              'titulo': item.titulo,
              'costo': item.costo,
              'cantidad': item.cantidad,
              'imagen': item.imagen,
            })
        .toList();

    final numeroOrden = _generarNumeroOrden();

    final docRef = await _collection.add({
      'items': itemsData,
      'total': total,
      'direccion': direccion,
      'metodoPago': metodoPago,
      'estado': 'pendiente',
      'fechaCreacion': FieldValue.serverTimestamp(),
      'numeroOrden': numeroOrden,
    });

    final doc = await docRef.get();
    return OrderModel.fromFirestore(doc);
  }

  Stream<List<OrderModel>> watchOrders() {
    if (!_isAuthenticated) return Stream.value([]);
    return _collection
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(OrderModel.fromFirestore).toList());
  }

  Future<List<OrderModel>> getOrders() async {
    if (!_isAuthenticated) return [];
    final snapshot =
        await _collection.orderBy('fechaCreacion', descending: true).get();
    return snapshot.docs.map(OrderModel.fromFirestore).toList();
  }
}
