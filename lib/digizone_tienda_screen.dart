import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'carrito_state.dart';
import 'digizone_utils.dart';
import 'core/widgets/shimmer_loading.dart';

class DigizoneTiendaScreen extends StatefulWidget {
  final CarritoState carritoState;
  final VoidCallback onProductoAgregado;
  final VoidCallback onVerCarrito;
  final ValueNotifier<SearchFilters> filtrosBusqueda;

  const DigizoneTiendaScreen({
    super.key,
    required this.carritoState,
    required this.onProductoAgregado,
    required this.onVerCarrito,
    required this.filtrosBusqueda,
  });

  @override
  State<DigizoneTiendaScreen> createState() => _DigizoneTiendaScreenState();
}

class _DigizoneTiendaScreenState extends State<DigizoneTiendaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _botonAnimController;
  late final Animation<double> _botonScale;
  final Set<String> _favoritos = {};
  StreamSubscription<QuerySnapshot>? _favSubscription;

  @override
  void initState() {
    super.initState();
    _botonAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _botonScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _botonAnimController, curve: Curves.easeInOut),
    );
    widget.filtrosBusqueda.addListener(_onFiltrosChanged);
    _cargarFavoritos();
  }

  void _cargarFavoritos() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _favSubscription = FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(user.uid)
        .collection('Favoritos')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _favoritos.clear();
          _favoritos.addAll(snapshot.docs.map((doc) => doc.id));
        });
      }
    });
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
    widget.filtrosBusqueda.removeListener(_onFiltrosChanged);
    _botonAnimController.dispose();
    super.dispose();
  }

  void _onFiltrosChanged() { if (mounted) setState(() {}); }

  void _toggleFavorito(String id, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(user.uid)
        .collection('Favoritos')
        .doc(id);
    if (_favoritos.contains(id)) {
      await docRef.delete();
    } else {
      await docRef.set({
        'titulo': data['titulo'] ?? '',
        'costo': data['costo'] ?? 0,
        'imagen': data['imagen'] ?? '',
        'agregadoEn': FieldValue.serverTimestamp(),
      });
    }
  }

  void _agregarAlCarrito(String id, Map<String, dynamic> data) {
    final inventario = ((data['inventario'] ?? 0) as num).toInt();
    final error = widget.carritoState.agregar(
      idProducto: id,
      titulo: (data['titulo'] ?? '').toString(),
      detalle: (data['detalle'] ?? '').toString(),
      costo: ((data['costo'] ?? 0) as num).toDouble(),
      imagen: (data['imagen'] ?? '').toString(),
      inventario: inventario,
      disponible: data['disponible'] != false,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    widget.onProductoAgregado();
    _botonAnimController.forward(from: 0).then((_) { if (mounted) _botonAnimController.reverse(); });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Expanded(child: Text('Producto agregado'))]),
        action: SnackBarAction(label: 'Ver', textColor: Colors.amber, onPressed: widget.onVerCarrito),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtros = widget.filtrosBusqueda.value;
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(digizoneColeccion).orderBy('titulo').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) {
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 6,
              itemBuilder: (_, _) => const ShimmerProductCard(),
            );
          }
          var docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['disponible'] == false) return false;
            if (filtros.query.isNotEmpty) {
              final q = filtros.query.toLowerCase();
              final t = (data['titulo'] ?? '').toString().toLowerCase();
              final d = (data['detalle'] ?? '').toString().toLowerCase();
              final c = (data['categoria'] ?? '').toString().toLowerCase();
              if (!t.contains(q) && !d.contains(q) && !c.contains(q)) return false;
            }
            final costo = ((data['costo'] ?? 0) as num).toDouble();
            if (filtros.precioMin != null && costo < filtros.precioMin!) return false;
            if (filtros.precioMax != null && costo > filtros.precioMax!) return false;
            return true;
          }).toList();

          return Column(
            children: [
              if (filtros.tieneFiltros)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.indigo.shade50,
                  child: Row(
                    children: [
                      Expanded(child: Text(filtros.descripcion, style: const TextStyle(fontWeight: FontWeight.w500))),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => widget.filtrosBusqueda.value = const SearchFilters(),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('No se encontraron productos'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final item = docs[index];
                          final data = item.data() as Map<String, dynamic>;
                          final inventario = ((data['inventario'] ?? 0) as num).toInt();
                          final sinStock = inventario <= 0;
                          final costo = ((data['costo'] ?? 0) as num).toDouble();
                          final esFavorito = _favoritos.contains(item.id);

                          return Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Stack(
                                  children: [
                                    imagenProducto(data['imagen']?.toString(), height: 160, width: double.infinity),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        icon: Icon(
                                          esFavorito ? Icons.favorite : Icons.favorite_border,
                                          color: esFavorito ? Colors.red : Colors.white,
                                          shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                                        ),
                                        onPressed: () => _toggleFavorito(item.id, data),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text((data['titulo'] ?? '').toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text((data['detalle'] ?? '').toString()),
                                      const SizedBox(height: 8),
                                      Text(formatoPrecio(costo), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
                                      Text(
                                        sinStock ? 'Sin stock' : 'Stock: $inventario',
                                        style: TextStyle(color: sinStock ? Colors.red : Colors.green, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 8),
                                      ScaleTransition(
                                        scale: _botonScale,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: sinStock ? null : () => _agregarAlCarrito(item.id, data),
                                            icon: const Icon(Icons.add_shopping_cart),
                                            label: const Text('Agregar'),
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
