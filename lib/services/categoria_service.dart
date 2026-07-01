import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria_model.dart';

class CategoriaService {
  final FirebaseFirestore _firestore;
  static const String _collection = 'categorias';

  CategoriaService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<CategoriaModel>> watchCategorias() {
    return _firestore
        .collection(_collection)
        .where('activo', isEqualTo: true)
        .orderBy('orden')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => CategoriaModel.fromFirestore(doc)).toList());
  }

  Future<List<CategoriaModel>> getCategorias() async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('activo', isEqualTo: true)
          .orderBy('orden')
          .get();
      return snap.docs
          .map((doc) => CategoriaModel.fromFirestore(doc))
          .toList();
    } catch (_) {
      final snap = await _firestore
          .collection(_collection)
          .orderBy('orden')
          .get();
      return snap.docs
          .map((doc) => CategoriaModel.fromFirestore(doc))
          .toList();
    }
  }

  Future<CategoriaModel?> getCategoria(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return CategoriaModel.fromFirestore(doc);
  }

  Future<void> saveCategoria(CategoriaModel categoria) async {
    await _firestore
        .collection(_collection)
        .doc(categoria.id)
        .set(categoria.toFirestore());
  }

  Future<void> deleteCategoria(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
