import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'carrito_state.dart';
import 'digizone_utils.dart';

class CarritoScreen extends StatefulWidget {
  final CarritoState carritoState;

  const CarritoScreen({
    super.key,
    required this.carritoState,
  });

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  bool _procesando = false;

  CarritoState get _carrito => widget.carritoState;

  @override
  void initState() {
    super.initState();
    _carrito.addListener(_refrescar);
  }

  @override
  void dispose() {
    _carrito.removeListener(_refrescar);
    super.dispose();
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  void _eliminarItem(int index) {
    _carrito.eliminarEn(index);
  }

  Future<void> _finalizarCompra() async {
    if (_carrito.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío')),
      );
      return;
    }

    setState(() => _procesando = true);

    try {
      for (final item in List.of(_carrito.items)) {
        final doc = await FirebaseFirestore.instance
            .collection(digizoneColeccion)
            .doc(item.idProducto)
            .get();

        if (!doc.exists) {
          throw Exception('El producto "${item.titulo}" ya no existe');
        }

        final data = doc.data() ?? {};
        final stock = ((data['inventario'] ?? 0) as num).toInt();
        if (stock < item.cantidad) {
          throw Exception(
            'Stock insuficiente para "${item.titulo}" (disponible: $stock)',
          );
        }

        await doc.reference.update({
          'inventario': stock - item.cantidad,
          if (stock - item.cantidad == 0) 'disponible': false,
        });
      }

      _carrito.limpiar();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra realizada con éxito')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al finalizar compra: $e')),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _carrito.items;

    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Carrito'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Tu carrito está vacío',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        child: ListTile(
                          leading: SizedBox(
                            width: 56,
                            height: 56,
                            child: imagenProducto(
                              item.imagen,
                              height: 56,
                              width: 56,
                            ),
                          ),
                          title: Text(item.titulo),
                          subtitle: Text(
                            '${item.detalle}\n'
                            'Cantidad: ${item.cantidad} | '
                            'S/. ${item.costo.toStringAsFixed(2)} c/u',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarItem(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Total: S/. ${_carrito.totalPrecio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _procesando ? null : _finalizarCompra,
                        icon: _procesando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.payment),
                        label: Text(
                          _procesando
                              ? 'Procesando...'
                              : 'Finalizar compra',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
