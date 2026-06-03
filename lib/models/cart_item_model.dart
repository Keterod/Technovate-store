import 'product_model.dart';

class CartItemModel {
  final String idProducto;
  final String titulo;
  final String detalle;
  final double costo;
  final String imagen;
  int cantidad;
  final int inventario;

  CartItemModel({
    required this.idProducto,
    required this.titulo,
    required this.detalle,
    required this.costo,
    required this.imagen,
    required this.cantidad,
    required this.inventario,
  });

  factory CartItemModel.fromProduct(ProductModel product) {
    return CartItemModel(
      idProducto: product.id,
      titulo: product.titulo,
      detalle: product.detalle,
      costo: product.costo,
      imagen: product.imagen,
      cantidad: 1,
      inventario: product.inventario,
    );
  }

  double get subtotal => costo * cantidad;
}
