import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'carrito_state.dart';
import 'digizone_utils.dart';
import 'core/widgets/confirm_dialog.dart';

class CarritoScreen extends StatefulWidget {
  final CarritoState carritoState;
  const CarritoScreen({super.key, required this.carritoState});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  bool _procesando = false;
  CarritoState get _carrito => widget.carritoState;

  @override
  void initState() { super.initState(); _carrito.addListener(_refrescar); }

  @override
  void dispose() { _carrito.removeListener(_refrescar); super.dispose(); }

  void _refrescar() { if (mounted) setState(() {}); }

  Future<void> _eliminarItem(int index) async {
    final item = _carrito.items[index];
    final confirmado = await mostrarConfirmacion(
      context,
      titulo: 'Eliminar producto',
      mensaje: '¿Quitar "${item.titulo}" del carrito?',
      confirmar: 'Eliminar',
      icono: Icons.delete_rounded,
    );
    if (confirmado) _carrito.eliminarEn(index);
  }

  Future<void> _finalizarCompra() async {
    if (_carrito.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El carrito está vacío')));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para comprar')));
      return;
    }

    final confirmado = await mostrarConfirmacion(
      context,
      titulo: 'Confirmar compra',
      mensaje: '¿Estás seguro de realizar esta compra por ${formatoPrecio(_carrito.totalPrecio)}?',
      confirmar: 'Pagar',
      icono: Icons.payment,
      colorConfirmar: Colors.indigo,
    );
    if (!confirmado) return;

    setState(() => _procesando = true);
    try {
      final items = List.of(_carrito.items);
      final batch = FirebaseFirestore.instance.batch();
      for (final item in items) {
        final docRef = FirebaseFirestore.instance.collection(digizoneColeccion).doc(item.idProducto);
        final doc = await docRef.get();
        if (!doc.exists) throw Exception('"${item.titulo}" ya no existe');
        final stock = ((doc.data()?['inventario'] ?? 0) as num).toInt();
        if (stock < item.cantidad) throw Exception('Stock insuficiente para "${item.titulo}" (disponible: $stock)');
        final nuevoStock = stock - item.cantidad;
        batch.update(docRef, {'inventario': nuevoStock, if (nuevoStock == 0) 'disponible': false});
      }
      final pedidoRef = FirebaseFirestore.instance.collection('Usuarios').doc(user.uid).collection('Pedidos').doc();
      batch.set(pedidoRef, {
        'fecha': FieldValue.serverTimestamp(),
        'total': _carrito.totalPrecio,
        'estado': 'Completado',
        'productos': items.map((item) => {
          'idProducto': item.idProducto,
          'titulo': item.titulo,
          'detalle': item.detalle,
          'precio': item.costo,
          'cantidad': item.cantidad,
          'subtotal': item.subtotal,
          'imagen': item.imagen,
        }).toList(),
      });
      await batch.commit();
      _carrito.limpiar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Compra realizada con éxito')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _carrito.items;
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: items.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tu carrito está vacío', style: TextStyle(fontSize: 16)),
            ]))
          : Column(children: [
              if (user == null)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(12),
                  color: Colors.orange.shade100,
                  child: const Text('Inicia sesión para finalizar tu compra', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        leading: SizedBox(width: 56, height: 56, child: imagenProducto(item.imagen, height: 56, width: 56)),
                        title: Text(item.titulo),
                        subtitle: Text('Cantidad: ${item.cantidad} | ${formatoPrecio(item.costo)} c/u'),
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(formatoPrecio(_carrito.totalPrecio), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _procesando ? null : _finalizarCompra,
                    icon: _procesando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.payment),
                    label: Text(_procesando ? 'Procesando...' : 'Finalizar compra'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ]),
              ),
            ]),
    );
  }
}
