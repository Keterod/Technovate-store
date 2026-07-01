import 'package:flutter/material.dart';

import '../../core/widgets/technovate_widgets.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../viewmodels/cart_view_model.dart';
import '../store/product_detail_screen.dart';

class HomeLandingScreen extends StatelessWidget {
  final void Function(String? categoria) onNavigateTienda;
  final VoidCallback onNavigateAsistente;
  final VoidCallback onNavigateCarrito;
  final VoidCallback onNavigateUbicacion;
  final CartViewModel cartViewModel;

  const HomeLandingScreen({
    super.key,
    required this.onNavigateTienda,
    required this.onNavigateAsistente,
    required this.onNavigateCarrito,
    required this.onNavigateUbicacion,
    required this.cartViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroBanner(
              onNavigateTienda: () => onNavigateTienda(null),
              onNavigateAsistente: onNavigateAsistente,
            ),
            _CategoriasGrid(onNavigateTienda: onNavigateTienda),
            _VisitOurStore(onNavigateUbicacion: onNavigateUbicacion),
            _ProductosDestacados(
              cartViewModel: cartViewModel,
              onNavigateCarrito: onNavigateCarrito,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _VisitOurStore extends StatelessWidget {
  final VoidCallback onNavigateUbicacion;

  const _VisitOurStore({required this.onNavigateUbicacion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visita nuestra tienda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Encuéntranos y conoce nuestros productos en persona.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onNavigateUbicacion,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Cómo llegar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.store_mall_directory,
              size: 64,
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final void Function() onNavigateTienda;
  final VoidCallback onNavigateAsistente;

  const _HeroBanner({
    required this.onNavigateTienda,
    required this.onNavigateAsistente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.memory, size: 56, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'TECHNOVATE',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tecnología y gaming para todos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onNavigateTienda,
                    icon: const Icon(Icons.store),
                    label: const Text('Ver productos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onNavigateAsistente,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Asistente AI'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoriasGrid extends StatelessWidget {
  final void Function(String? categoria) onNavigateTienda;

  const _CategoriasGrid({required this.onNavigateTienda});

  final List<_CategoriaItem> _categorias = const [
    _CategoriaItem('Laptop', Icons.laptop, 'laptop'),
    _CategoriaItem('Smartphone', Icons.smartphone, 'smartphone'),
    _CategoriaItem('Tablet', Icons.tablet, 'tablet'),
    _CategoriaItem('Monitor', Icons.monitor, 'monitor'),
    _CategoriaItem('Periféricos', Icons.keyboard, 'periférico'),
    _CategoriaItem('Componentes', Icons.memory, 'hardware'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorías',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _categorias.length,
            itemBuilder: (context, index) {
              final cat = _categorias[index];
              return InkWell(
                onTap: () => onNavigateTienda(cat.filtro),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat.icon, size: 32, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        cat.nombre,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoriaItem {
  final String nombre;
  final IconData icon;
  final String filtro;

  const _CategoriaItem(this.nombre, this.icon, this.filtro);
}

class _ProductosDestacados extends StatelessWidget {
  final CartViewModel cartViewModel;
  final VoidCallback onNavigateCarrito;

  const _ProductosDestacados({
    required this.cartViewModel,
    required this.onNavigateCarrito,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos destacados',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: StreamBuilder<List<ProductModel>>(
              stream: ProductService().watchProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Cargando...'));
                }
                final products = snapshot.data!
                    .where((p) => p.disponible)
                    .toList()
                  ..sort((a, b) => b.puntuacion.compareTo(a.puntuacion));
                final destacados = products.take(6).toList();
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: destacados.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = destacados[index];
                    return SizedBox(
                      width: 160,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  product: product,
                                  cartViewModel: cartViewModel,
                                  onProductAdded: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Producto agregado al carrito'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: imagenProducto(
                                  product.imagen,
                                  height: double.infinity,
                                  width: double.infinity,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.titulo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'S/. ${product.costo.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.star,
                                            size: 14, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          product.puntuacion.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
}
