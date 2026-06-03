import 'package:flutter/material.dart';

import '../../core/widgets/technovate_widgets.dart';
import '../../models/product_model.dart';
import '../../services/memory_service.dart';
import '../../services/product_service.dart';
import '../../viewmodels/cart_view_model.dart';
import '../store/product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final CartViewModel cartViewModel;

  const FavoritesScreen({super.key, required this.cartViewModel});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final MemoryService _memory = MemoryService();
  final ProductService _productService = ProductService();
  List<ProductModel> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    setState(() => _loading = true);
    try {
      final ids = await _memory.getFavoriteIds();
      final todos = await _productService.getAvailableProducts();
      _favorites = todos.where((p) => ids.contains(p.id)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No tienes favoritos aún',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca el corazón en los productos\npara agregarlos',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarFavoritos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final product = _favorites[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: SizedBox(
                            width: 56,
                            height: 56,
                            child: imagenProducto(
                              product.imagen,
                              height: 56,
                              width: 56,
                            ),
                          ),
                          title: Text(product.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              'S/. ${product.costo.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.favorite,
                                color: Colors.red),
                            onPressed: () async {
                              await _memory.toggleFavorite(product.id);
                              _cargarFavoritos();
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  product: product,
                                  cartViewModel: widget.cartViewModel,
                                  onProductAdded: () {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Producto agregado al carrito'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
