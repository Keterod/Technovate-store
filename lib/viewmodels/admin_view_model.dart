import 'package:flutter/foundation.dart';
import '../models/admin_order_item.dart';
import '../models/product_model.dart';
import '../services/admin_order_service.dart';
import '../services/product_service.dart';

class AdminViewModel extends ChangeNotifier {
  AdminViewModel({
    ProductService? productService,
    AdminOrderService? adminOrderService,
  })  : _productService = productService ?? ProductService(),
        _adminOrderService = adminOrderService ?? AdminOrderService();

  final ProductService _productService;
  final AdminOrderService _adminOrderService;
  bool _isSaving = false;
  String? _error;

  bool get isSaving => _isSaving;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

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
    _error = null;
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
    } catch (e) {
      _error = 'Error al guardar: $e';
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> eliminarProducto(String id) async {
    _error = null;
    notifyListeners();

    try {
      await _productService.deleteProduct(id);
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> bajarStock(String id, int inventarioActual) async {
    if (inventarioActual <= 0) return;
    try {
      await _productService.decreaseStock(id, inventarioActual);
      notifyListeners();
    } catch (e) {
      _error = 'Error al actualizar stock: $e';
      notifyListeners();
    }
  }

  Stream<List<AdminOrderItem>> watchAllOrders() {
    return _adminOrderService.watchAllOrders();
  }

  Future<void> actualizarEstadoPedido(
      String uid, String orderId, String nuevoEstado) async {
    try {
      await _adminOrderService.actualizarEstado(uid, orderId, nuevoEstado);
    } catch (e) {
      _error = 'Error al actualizar estado: $e';
      notifyListeners();
    }
  }
}
