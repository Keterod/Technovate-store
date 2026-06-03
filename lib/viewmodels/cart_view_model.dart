import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/cart_persistence_service.dart';
import '../services/checkout_service.dart';

class CartViewModel extends ChangeNotifier {
  final CartPersistenceService _persistence;
  final CheckoutService _checkoutService;
  final List<CartItemModel> _items = [];
  bool _isCheckingOut = false;
  bool _initialized = false;

  CartViewModel({
    CheckoutService? checkoutService,
    CartPersistenceService? persistence,
  })  : _checkoutService = checkoutService ?? CheckoutService(),
        _persistence = persistence ?? CartPersistenceService() {
    _loadPersistedCart();
  }

  List<CartItemModel> get items => List.unmodifiable(_items);
  bool get isCheckingOut => _isCheckingOut;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.cantidad);

  double get totalPrecio => _items.fold(0, (sum, item) => sum + item.subtotal);

  int cantidadDe(String idProducto) {
    final index = _items.indexWhere((item) => item.idProducto == idProducto);
    if (index == -1) return 0;
    return _items[index].cantidad;
  }

  Future<void> _loadPersistedCart() async {
    try {
      final data = await _persistence.loadCart();
      for (final item in data) {
        _items.add(CartItemModel(
          idProducto: (item['idProducto'] ?? '').toString(),
          titulo: (item['titulo'] ?? '').toString(),
          detalle: (item['detalle'] ?? '').toString(),
          costo: ((item['costo'] ?? 0) as num).toDouble(),
          imagen: (item['imagen'] ?? '').toString(),
          cantidad: ((item['cantidad'] ?? 1) as num).toInt(),
          inventario: ((item['inventario'] ?? 0) as num).toInt(),
        ));
      }
    } catch (_) {}
    _initialized = true;
    notifyListeners();
  }

  Future<void> _persistCart() async {
    if (!_initialized) return;
    try {
      await _persistence.saveCart(
        _items
            .map((item) => {
                  'idProducto': item.idProducto,
                  'titulo': item.titulo,
                  'detalle': item.detalle,
                  'costo': item.costo,
                  'imagen': item.imagen,
                  'cantidad': item.cantidad,
                  'inventario': item.inventario,
                })
            .toList(),
      );
    } catch (_) {}
  }

  String? addProduct(ProductModel product) {
    return agregar(
      idProducto: product.id,
      titulo: product.titulo,
      detalle: product.detalle,
      costo: product.costo,
      imagen: product.imagen,
      inventario: product.inventario,
      disponible: product.disponible,
    );
  }

  String? agregar({
    required String idProducto,
    required String titulo,
    required String detalle,
    required double costo,
    required String imagen,
    required int inventario,
    required bool disponible,
  }) {
    if (!disponible || inventario <= 0) {
      return 'Producto sin stock disponible';
    }

    final enCarrito = cantidadDe(idProducto);
    if (enCarrito >= inventario) {
      return 'No hay mas stock disponible';
    }

    final index = _items.indexWhere((item) => item.idProducto == idProducto);
    if (index != -1) {
      _items[index].cantidad++;
    } else {
      _items.add(
        CartItemModel(
          idProducto: idProducto,
          titulo: titulo,
          detalle: detalle,
          costo: costo,
          imagen: imagen,
          cantidad: 1,
          inventario: inventario,
        ),
      );
    }
    notifyListeners();
    _persistCart();
    return null;
  }

  void eliminarEn(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
    _persistCart();
  }

  void limpiar() {
    _items.clear();
    notifyListeners();
    _persistence.clearCart();
  }

  Future<void> finalizarCompra() async {
    if (_items.isEmpty) {
      throw Exception('El carrito esta vacio');
    }

    _isCheckingOut = true;
    notifyListeners();
    try {
      await _checkoutService.finishPurchase(_items);
      limpiar();
    } finally {
      _isCheckingOut = false;
      notifyListeners();
    }
  }
}
