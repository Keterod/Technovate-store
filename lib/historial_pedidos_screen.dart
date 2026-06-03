import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'digizone_utils.dart';

class HistorialPedidosScreen extends StatelessWidget {
  const HistorialPedidosScreen({super.key});

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return '—';
    if (fecha is Timestamp) {
      final dt = fecha.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    return fecha.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Historial'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Debes iniciar sesión para ver tus pedidos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Usuarios')
                  .doc(user.uid)
                  .collection('Pedidos')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aún no tienes pedidos registrados',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final total = ((data['total'] ?? 0) as num).toDouble();
                    final estado = (data['estado'] ?? '—').toString();
                    final fecha = _formatearFecha(data['fecha']);
                    final productos =
                        (data['productos'] as List<dynamic>? ?? []);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          'S/. ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        subtitle: Text('$fecha · $estado'),
                        children: productos.map((p) {
                          final prod = Map<String, dynamic>.from(p as Map);
                          final titulo = (prod['titulo'] ?? '').toString();
                          final cantidad = ((prod['cantidad'] ?? 0) as num).toInt();
                          final subtotal =
                              ((prod['subtotal'] ?? 0) as num).toDouble();
                          final imagen = (prod['imagen'] ?? '').toString();

                          return ListTile(
                            leading: SizedBox(
                              width: 48,
                              height: 48,
                              child: imagenProducto(
                                imagen,
                                height: 48,
                                width: 48,
                              ),
                            ),
                            title: Text(titulo),
                            subtitle: Text(
                              'Cantidad: $cantidad · '
                              'Subtotal: S/. ${subtotal.toStringAsFixed(2)}',
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
