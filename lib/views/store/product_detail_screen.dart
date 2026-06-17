import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/technovate_widgets.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../services/analytics_service.dart';
import '../../services/memory_service.dart';
import '../../services/review_service.dart';
import '../../viewmodels/cart_view_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final CartViewModel cartViewModel;
  final VoidCallback onProductAdded;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.cartViewModel,
    required this.onProductAdded,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final MemoryService _memory = MemoryService();
  final ReviewService _reviewService = ReviewService();
  int _cantidad = 1;
  late final ProductModel _product;
  bool _esFavorito = false;
  List<ReviewModel> _reviews = [];
  double _ratingPromedio = 0;
  int _totalResenas = 0;
  bool _cargandoReviews = true;
  bool _yaResenio = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _verificarFavorito();
    _cargarReviews();
    AnalyticsService().logProductView(
      productId: _product.id,
      productName: _product.titulo,
      price: _product.costo,
      category: _product.categoria,
    );
  }

  Future<void> _cargarReviews() async {
    final stats = await _reviewService.getRatingStats(_product.id);
    final reviews = await _reviewService.getReviews(_product.id);
    final yaResenio = await _reviewService.hasUserReviewed(_product.id);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _ratingPromedio = stats['average'] as double;
        _totalResenas = stats['count'] as int;
        _cargandoReviews = false;
        _yaResenio = yaResenio;
      });
    }
  }

  Future<void> _verificarFavorito() async {
    final fav = await _memory.isFavorite(_product.id);
    if (mounted) setState(() => _esFavorito = fav);
  }

  Future<void> _toggleFav() async {
    await _memory.toggleFavorite(_product.id);
    if (mounted) setState(() => _esFavorito = !_esFavorito);
  }

  void _agregarAlCarrito() {
    for (int i = 0; i < _cantidad; i++) {
      final error = widget.cartViewModel.addProduct(_product);
      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }
    }
    widget.onProductAdded();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_cantidad x ${_product.titulo} agregado(s) al carrito'),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sinStock = !_product.tieneStock;
    final maximo = _product.inventario;
    final specs = _product.especificaciones;

    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Detalle'),
        actions: [
          IconButton(
            icon: Icon(
              _esFavorito ? Icons.favorite : Icons.favorite_border,
              color: _esFavorito ? Colors.red : Colors.white,
            ),
            tooltip: _esFavorito ? 'Quitar de favoritos' : 'Agregar a favoritos',
            onPressed: _toggleFav,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'product_img_${_product.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: imagenProducto(
                  _product.imagen,
                  height: 260,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _product.titulo,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star,
                                size: 18, color: Colors.amber.shade700),
                            const SizedBox(width: 4),
                            Text(
                              _product.puntuacion.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'S/. ${_product.costo.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _product.detalle,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _specChip(Icons.category, _product.categoria),
                      if (_product.fabricante.isNotEmpty)
                        _specChip(Icons.business, _product.fabricante),
                      if (_product.garantia.isNotEmpty)
                        _specChip(Icons.verified, _product.garantia),
                      _stockChip(sinStock, _product.inventario),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Especificaciones Técnicas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (specs.isEmpty)
                    Text(
                      'No se detallaron especificaciones técnicas.',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  else if (specs.length == 1 && specs.containsKey('especificaciones'))
                    Text(
                      specs['especificaciones'].toString(),
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    )
                  else
                    ...specs.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  _labelEspec(e.key),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e.value.toString(),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 24),
                  _buildReviewsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: sinStock
                          ? null
                          : () {
                              if (_cantidad > 1) {
                                setState(() => _cantidad--);
                              }
                            },
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$_cantidad',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: sinStock || _cantidad >= maximo
                          ? null
                          : () {
                              setState(() => _cantidad++);
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: sinStock ? null : _agregarAlCarrito,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      sinStock
                          ? 'Sin stock'
                          : 'Agregar al carrito - S/. ${(_product.costo * _cantidad).toStringAsFixed(2)}',
                    ),
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _specChip(IconData icon, String label) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: theme.colorScheme.primaryContainer,
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _stockChip(bool sinStock, int stock) {
    return Chip(
      avatar: Icon(
        sinStock ? Icons.error : Icons.inventory_2,
        size: 16,
        color: sinStock ? Colors.red : Colors.green,
      ),
      label: Text(
        sinStock ? 'Sin stock' : 'Stock: $stock',
        style: TextStyle(
          fontSize: 12,
          color: sinStock ? Colors.red : Colors.green.shade700,
        ),
      ),
      backgroundColor:
          sinStock ? Colors.red.shade50 : Colors.green.shade50,
      side: BorderSide(
        color: sinStock ? Colors.red.shade200 : Colors.green.shade200,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  String _labelEspec(String key) {
    const labels = {
      'ram': 'RAM',
      'procesador': 'Procesador',
      'gpu': 'GPU',
      'almacenamiento': 'Almacenamiento',
      'socket': 'Socket',
      'tipoRam': 'Tipo RAM',
      'potenciaFuente': 'Fuente (W)',
    };
    return labels[key] ?? key;
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Reseñas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_totalResenas > 0)
              Row(
                children: [
                  ...List.generate(5, (i) {
                    return Icon(
                      i < _ratingPromedio.round() ? Icons.star : Icons.star_border,
                      size: 18,
                      color: Colors.amber,
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    '$_totalResenas',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_cargandoReviews)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ))
        else ...[
          if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Aún no hay reseñas. ¡Sé el primero!',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...List.generate(
              _reviews.length.clamp(0, 3),
              (i) => _reviewCard(_reviews[i]),
            ),
          if (_reviews.length > 3)
            TextButton(
              onPressed: () => _mostrarTodasLasResenas(),
              child: Text('Ver todas las ${_reviews.length} reseñas'),
            ),
          const SizedBox(height: 8),
          if (!_yaResenio)
            ElevatedButton.icon(
              onPressed: _mostrarFormularioResena,
              icon: const Icon(Icons.rate_review, size: 18),
              label: const Text('Escribir reseña'),
            ),
        ],
      ],
    );
  }

  Widget _reviewCard(ReviewModel review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.userName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                ...List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  );
                }),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.comment, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(review.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarTodasLasResenas() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Todas las reseñas ($_totalResenas)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: _reviews.length,
                  itemBuilder: (_, i) => _reviewCard(_reviews[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarFormularioResena() {
    int rating = 5;
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Califica este producto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final estrella = i + 1;
                    return IconButton(
                      icon: Icon(
                        estrella <= rating ? Icons.star : Icons.star_border,
                        size: 36,
                        color: Colors.amber,
                      ),
                      onPressed: () => setSheetState(() => rating = estrella),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Comparte tu experiencia...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _reviewService.addReview(
                      productId: _product.id,
                      rating: rating,
                      comment: commentController.text.trim(),
                    );
                    AnalyticsService().logReview(
                      productId: _product.id,
                      rating: rating,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _cargarReviews();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reseña publicada')),
                    );
                  },
                  child: const Text('Publicar reseña'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
