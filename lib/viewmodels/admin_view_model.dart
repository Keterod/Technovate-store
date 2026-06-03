import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class AdminViewModel extends ChangeNotifier {
  AdminViewModel({ProductService? productService})
      : _productService = productService ?? ProductService();

  final ProductService _productService;
  bool _isSaving = false;

  bool get isSaving => _isSaving;

  Stream<List<ProductModel>> watchAllProducts() {
    return _productService.watchProducts();
  }

  Future<void> guardarProducto({
    required String? id,
    required String titulo,
    required String detalle,
    required String fabricante,
    required double costo,
    required int inventario,
    required String categoria,
    required bool disponible,
    required String garantia,
    required double puntuacion,
    required String imagen,
    required Map<String, dynamic> especificaciones,
    required List<String> tags,
    required List<String> usoRecomendado,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final product = ProductModel(
        id: id ?? '',
        titulo: titulo,
        detalle: detalle,
        fabricante: fabricante,
        categoria: categoria,
        costo: costo,
        inventario: inventario,
        garantia: garantia.isEmpty ? 'Sin garantía' : garantia,
        puntuacion: puntuacion,
        imagen: imagen,
        disponible: disponible,
        especificaciones: especificaciones,
        tags: tags,
        usoRecomendado: usoRecomendado,
      );

      await _productService.saveProduct(product);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> eliminarProducto(String id) async {
    await _productService.deleteProduct(id);
    notifyListeners();
  }

  Future<void> bajarStock(String id, int inventarioActual) async {
    if (inventarioActual <= 0) return;
    await _productService.decreaseStock(id, inventarioActual);
    notifyListeners();
  }
}
