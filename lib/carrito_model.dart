class CarritoItem {
  final String idProducto;
  final String titulo;
  final String detalle;
  final double costo;
  final String imagen;
  int cantidad;
  final int inventario;

  CarritoItem({
    required this.idProducto,
    required this.titulo,
    required this.detalle,
    required this.costo,
    required this.imagen,
    required this.cantidad,
    required this.inventario,
  });

  double get subtotal => costo * cantidad;
}
