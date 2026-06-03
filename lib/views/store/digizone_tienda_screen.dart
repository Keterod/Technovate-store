import 'package:flutter/material.dart';

import '../../core/widgets/technovate_widgets.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../viewmodels/cart_view_model.dart';

class DigizoneTiendaScreen extends StatefulWidget {
  final CartViewModel cartViewModel;
  final VoidCallback onProductAdded;
  final VoidCallback onViewCart;

  const DigizoneTiendaScreen({
    super.key,
    required this.cartViewModel,
    required this.onProductAdded,
    required this.onViewCart,
  });

  @override
  State<DigizoneTiendaScreen> createState() => _DigizoneTiendaScreenState();
}

class _DigizoneTiendaScreenState extends State<DigizoneTiendaScreen>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  late final AnimationController _buttonAnimationController;
  late final Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _buttonScale = Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _addToCart(ProductModel product) {
    final error = widget.cartViewModel.addProduct(product);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    widget.onProductAdded();
    _buttonAnimationController.forward(from: 0).then((_) {
      if (mounted) _buttonAnimationController.reverse();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Producto agregado al carrito')),
          ],
        ),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.amber,
          onPressed: widget.onViewCart,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Tienda'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _productService.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!
              .where((product) => product.disponible)
              .toList();
          if (products.isEmpty) {
            return const Center(child: Text('No hay productos disponibles'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final sinStock = product.inventario <= 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      child: imagenProducto(
                        product.imagen,
                        height: 160,
                        width: double.infinity,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.titulo,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(product.detalle),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Chip(label: Text(product.categoria)),
                              if (product.fabricante.isNotEmpty)
                                Chip(label: Text(product.fabricante)),
                              Chip(
                                avatar: const Icon(Icons.star, size: 16),
                                label: Text(
                                  product.puntuacion.toStringAsFixed(1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'S/. ${product.costo.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                          Text(
                            sinStock
                                ? 'Sin stock'
                                : 'Stock disponible: ${product.inventario}',
                            style: TextStyle(
                              color: sinStock ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ScaleTransition(
                            scale: _buttonScale,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    sinStock ? null : () => _addToCart(product),
                                icon: const Icon(Icons.add_shopping_cart),
                                label: const Text('Agregar al carrito'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
