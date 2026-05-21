import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'carrito_state.dart';
import 'digizone_utils.dart';

class DigizoneTiendaScreen extends StatefulWidget {
  final CarritoState carritoState;
  final VoidCallback onProductoAgregado;
  final VoidCallback onVerCarrito;

  const DigizoneTiendaScreen({
    super.key,
    required this.carritoState,
    required this.onProductoAgregado,
    required this.onVerCarrito,
  });

  @override
  State<DigizoneTiendaScreen> createState() => _DigizoneTiendaScreenState();
}

class _DigizoneTiendaScreenState extends State<DigizoneTiendaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _botonAnimController;
  late final Animation<double> _botonScale;

  @override
  void initState() {
    super.initState();
    _botonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _botonScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _botonAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _botonAnimController.dispose();
    super.dispose();
  }

  void _agregarAlCarrito(String id, Map<String, dynamic> data) {
    final inventario = ((data['inventario'] ?? 0) as num).toInt();
    final disponible = data['disponible'] != false;

    final error = widget.carritoState.agregar(
      idProducto: id,
      titulo: (data['titulo'] ?? '').toString(),
      detalle: (data['detalle'] ?? '').toString(),
      costo: ((data['costo'] ?? 0) as num).toDouble(),
      imagen: (data['imagen'] ?? '').toString(),
      inventario: inventario,
      disponible: disponible,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() {});
    widget.onProductoAgregado();

    _botonAnimController.forward(from: 0).then((_) {
      if (mounted) _botonAnimController.reverse();
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
          onPressed: widget.onVerCarrito,
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(digizoneColeccion)
            .orderBy('titulo')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['disponible'] != false;
          }).toList();
          if (docs.isEmpty) {
            return const Center(child: Text('No hay productos disponibles'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final item = docs[index];
              final data = item.data() as Map<String, dynamic>;
              final inventario = ((data['inventario'] ?? 0) as num).toInt();
              final sinStock = inventario <= 0;
              final costo = ((data['costo'] ?? 0) as num).toDouble();

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
                        data['imagen']?.toString(),
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
                            (data['titulo'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text((data['detalle'] ?? '').toString()),
                          const SizedBox(height: 8),
                          Text(
                            'S/. ${costo.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                          Text(
                            sinStock
                                ? 'Sin stock'
                                : 'Stock disponible: $inventario',
                            style: TextStyle(
                              color: sinStock ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ScaleTransition(
                            scale: _botonScale,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: sinStock
                                    ? null
                                    : () => _agregarAlCarrito(item.id, data),
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
