import 'package:flutter/material.dart';

import '../../core/widgets/technovate_widgets.dart';
import '../../viewmodels/cart_view_model.dart';

class CartScreen extends StatefulWidget {
  final CartViewModel cartViewModel;

  const CartScreen({super.key, required this.cartViewModel});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CartViewModel get _cart => widget.cartViewModel;

  @override
  void initState() {
    super.initState();
    _cart.addListener(_refresh);
  }

  @override
  void dispose() {
    _cart.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _finishPurchase() async {
    if (_cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito esta vacio')),
      );
      return;
    }

    try {
      await _cart.finalizarCompra();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra realizada con exito')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al finalizar compra: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;

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
                'Tu carrito esta vacio',
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
                            onPressed: () => _cart.eliminarEn(index),
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
                        'Total: S/. ${_cart.totalPrecio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed:
                            _cart.isCheckingOut ? null : _finishPurchase,
                        icon: _cart.isCheckingOut
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
                          _cart.isCheckingOut
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
