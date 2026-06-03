import 'package:flutter/material.dart';

import '../../core/widgets/technovate_widgets.dart';
import '../../viewmodels/cart_view_model.dart';
import '../../viewmodels/order_view_model.dart';
import '../checkout/checkout_screen.dart';
import '../orders/order_history_screen.dart';

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

  void _irAlCheckout() {
    if (_cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito esta vacio')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cartViewModel: _cart,
          orderViewModel: OrderViewModel(),
        ),
      ),
    );
  }

  void _irHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderHistoryScreen(
          orderViewModel: OrderViewModel(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;

    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Carrito'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Mis pedidos',
            onPressed: _irHistorial,
          ),
        ],
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
                            child: Hero(
                              tag: 'cart_img_${item.idProducto}',
                              child: imagenProducto(
                                item.imagen,
                                height: 56,
                                width: 56,
                              ),
                            ),
                          ),
                          title: Text(item.titulo),
                          subtitle: Text(
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
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
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
                        onPressed: _irAlCheckout,
                        icon: const Icon(Icons.payment),
                        label: const Text('Finalizar compra'),
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
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
