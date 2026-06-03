import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/product_model.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(digizoneColeccion);

  Stream<List<ProductModel>> watchProducts() {
    return _collection.orderBy('titulo').snapshots().map(
          (snapshot) => snapshot.docs.map(ProductModel.fromFirestore).toList(),
        );
  }

  Future<List<ProductModel>> getAvailableProducts() async {
    final snapshot = await _collection.where('disponible', isNotEqualTo: false).get();
    final products = snapshot.docs
        .map(ProductModel.fromFirestore)
        .where((product) => product.tieneStock)
        .toList();
    products.sort((a, b) {
      final byRating = b.puntuacion.compareTo(a.puntuacion);
      if (byRating != 0) return byRating;
      return a.costo.compareTo(b.costo);
    });
    return products;
  }

  Future<void> saveProduct(ProductModel product) async {
    final data = product.toFirestore();
    if (product.id.isEmpty) {
      await _collection.add(data);
    } else {
      await _collection.doc(product.id).update(data);
    }
  }

  Future<void> deleteProduct(String id) => _collection.doc(id).delete();

  Future<void> decreaseStock(String id, int currentStock) {
    return _collection.doc(id).update({'inventario': currentStock - 1});
  }
}
