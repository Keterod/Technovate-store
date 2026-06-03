import 'package:flutter/material.dart';

import '../../core/theme/technovate_theme.dart';
import '../../core/widgets/shimmer_widget.dart';
import '../../core/widgets/technovate_widgets.dart';
import '../../models/product_model.dart';
import '../../services/analytics_service.dart';
import '../../services/memory_service.dart';
import '../../services/product_service.dart';
import '../../viewmodels/cart_view_model.dart';
import '../profile/profile_screen.dart';
import '../favorites/favorites_screen.dart';
import 'product_detail_screen.dart';

class DigizoneTiendaScreen extends StatefulWidget {
  final CartViewModel cartViewModel;
  final VoidCallback onProductAdded;
  final VoidCallback onViewCart;
  final String? categoriaInicial;

  const DigizoneTiendaScreen({
    super.key,
    required this.cartViewModel,
    required this.onProductAdded,
    required this.onViewCart,
    this.categoriaInicial,
  });

  @override
  State<DigizoneTiendaScreen> createState() => _DigizoneTiendaScreenState();
}

class _DigizoneTiendaScreenState extends State<DigizoneTiendaScreen> {
  final ProductService _productService = ProductService();
  final MemoryService _memory = MemoryService();
  final Set<String> _trackedViews = {};
  final TextEditingController _searchController = TextEditingController();
  Set<String> _favoriteIds = {};

  String _busqueda = '';
  String? _categoriaFiltro;
  double? _precioMin;
  double? _precioMax;
  bool _mostrarFiltros = false;

  static const Map<String, String> categoriasMap = {
    'Laptop': 'Laptop',
    'Smartphone': 'Smartphone',
    'Tablet': 'Tablet',
    'Monitor': 'Monitor',
    'Periféricos': 'periférico',
    'Componentes': 'hardware',
    'Equipos': 'equipo',
    'Software': 'software',
  };
  List<String> get _categorias => categoriasMap.keys.toList();

  @override
  void initState() {
    super.initState();
    _categoriaFiltro = widget.categoriaInicial;
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    final ids = await _memory.getFavoriteIds();
    if (mounted) setState(() => _favoriteIds = ids);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _abrirDetalle(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          cartViewModel: widget.cartViewModel,
          onProductAdded: widget.onProductAdded,
        ),
      ),
    );
  }

  List<ProductModel> _filtrarProductos(List<ProductModel> productos) {
    var resultado = productos;
    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      resultado = resultado.where((p) {
        return p.titulo.toLowerCase().contains(q) ||
            p.detalle.toLowerCase().contains(q) ||
            p.fabricante.toLowerCase().contains(q) ||
            p.categoria.toLowerCase().contains(q);
      }).toList();
    }
    if (_categoriaFiltro != null) {
      resultado = resultado
          .where((p) => p.categoria.toLowerCase() == _categoriaFiltro!.toLowerCase())
          .toList();
    }
    if (_precioMin != null) {
      resultado = resultado.where((p) => p.costo >= _precioMin!).toList();
    }
    if (_precioMax != null) {
      resultado = resultado.where((p) => p.costo <= _precioMax!).toList();
    }
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Tienda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favoritos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoritesScreen(
                    cartViewModel: widget.cartViewModel,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _mostrarFiltros ? Icons.filter_list_off : Icons.filter_list,
            ),
            tooltip: 'Filtros',
            onPressed: () => setState(() => _mostrarFiltros = !_mostrarFiltros),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Mi Perfil',
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: Icon(context.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Modo oscuro',
            onPressed: context.toggleDarkMode,
          ),

        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() => _busqueda = v.trim());
                if (v.trim().length >= 3) {
                  AnalyticsService().logSearch(v.trim());
                }
              },
            ),
          ),
          if (_mostrarFiltros)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChipTodas(),
                        ..._categorias.map((cat) => _filterChip(cat)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Precio mín',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (v) => setState(
                              () => _precioMin = double.tryParse(v)),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('-'),
                      ),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Precio máx',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (v) => setState(
                              () => _precioMax = double.tryParse(v)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _productService.watchProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.63,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 6,
                    itemBuilder: (_, __) => const ProductCardShimmer(),
                  );
                }
                var products = snapshot.data!
                    .where((product) => product.disponible)
                    .toList();
                products = _filtrarProductos(products);
                if (products.isNotEmpty) {
                  for (final p in products) {
                    if (_trackedViews.add(p.id)) {
                      _memory.trackProductView(
                        productoId: p.id,
                        titulo: p.titulo,
                        costo: p.costo,
                        imagen: p.imagen,
                      );
                    }
                  }
                }
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          _busqueda.isNotEmpty || _categoriaFiltro != null
                              ? 'No se encontraron productos'
                              : 'No hay productos disponibles',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.63,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final sinStock = product.inventario <= 0;

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _abrirDetalle(product),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Hero(
                              tag: 'product_img_${product.id}',
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                                child: imagenProducto(
                                  product.imagen,
                                  height: 120,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product.titulo,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            await _memory.toggleFavorite(product.id);
                                            _cargarFavoritos();
                                          },
                                          child: Icon(
                                            _favoriteIds.contains(product.id)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: _favoriteIds.contains(product.id)
                                                ? Colors.red
                                                : Colors.grey,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        product.categoria,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'S/. ${product.costo.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 28,
                                      child: ElevatedButton.icon(
                                        onPressed: sinStock
                                            ? null
                                            : () => _addToCart(product),
                                        icon: const Icon(
                                            Icons.add_shopping_cart, size: 14),
                                        label: const Text('Agregar',
                                            style: TextStyle(fontSize: 11)),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipTodas() {
    final seleccionado = _categoriaFiltro == null;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: const Text('Todas'),
        selected: seleccionado,
        onSelected: (_) => setState(() => _categoriaFiltro = null),
      ),
    );
  }

  Widget _filterChip(String label) {
    final valor = categoriasMap[label]!;
    final seleccionado = _categoriaFiltro == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: seleccionado,
        onSelected: (_) {
          setState(() {
            _categoriaFiltro = seleccionado ? null : valor;
          });
        },
      ),
    );
  }

  void _addToCart(ProductModel product) {
    final error = widget.cartViewModel.addProduct(product);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    AnalyticsService().logAddToCart(
      productId: product.id,
      productName: product.titulo,
      price: product.costo,
      quantity: 1,
    );
    widget.onProductAdded();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Producto agregado al carrito'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
