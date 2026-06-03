import 'package:flutter/material.dart';

import '../../models/order_model.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final fecha =
        '${order.fechaCreacion.day}/${order.fechaCreacion.month}/${order.fechaCreacion.year} '
        '${order.fechaCreacion.hour.toString().padLeft(2, '0')}:'
        '${order.fechaCreacion.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido confirmado'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              '¡Pedido confirmado!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gracias por tu compra. Te enviaremos un correo con los detalles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow(context, 'N° de pedido', order.numeroOrden),
                    const Divider(height: 20),
                    _infoRow(context, 'Fecha', fecha),
                    const Divider(height: 20),
                    _infoRow(context, 'Estado', order.estado),
                    const Divider(height: 20),
                    _infoRow(
                      context, 'Total',
                      'S/. ${order.total.toStringAsFixed(2)}',
                      destacado: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dirección de envío',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(order.direccion['nombre'] ?? ''),
                    Text(order.direccion['direccion'] ?? ''),
                    Text(
                        '${order.direccion['ciudad'] ?? ''} - ${order.direccion['telefono'] ?? ''}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Productos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item['titulo']} x${item['cantidad']}',
                              ),
                            ),
                            Text(
                              'S/. ${((item['costo'] as num) * (item['cantidad'] as num)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Volver al inicio'),
                style: ElevatedButton.styleFrom(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, {bool destacado = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
            fontSize: destacado ? 18 : 15,
            color: destacado ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
