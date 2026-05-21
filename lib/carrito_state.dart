import 'package:flutter/foundation.dart';
import 'carrito_model.dart';

/// Estado del carrito en memoria (una sola lista compartida).
class CarritoState extends ChangeNotifier {
  final List<CarritoItem> items = [];

  int get totalItems => items.fold(0, (suma, item) => suma + item.cantidad);

  double get totalPrecio =>
      items.fold(0, (suma, item) => suma + item.subtotal);

  int cantidadDe(String idProducto) {
    final encontrado = items.where((i) => i.idProducto == idProducto);
    if (encontrado.isEmpty) return 0;
    return encontrado.first.cantidad;
  }

  /// Retorna null si se agregó correctamente, o un mensaje de error.
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
      return 'No hay más stock disponible';
    }

    final existente = items.where((i) => i.idProducto == idProducto);
    if (existente.isNotEmpty) {
      existente.first.cantidad++;
    } else {
      items.add(
        CarritoItem(
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
    return null;
  }

  void eliminarEn(int index) {
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    notifyListeners();
  }

  void limpiar() {
    items.clear();
    notifyListeners();
  }
}
