import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../digizone_utils.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: user == null
          ? const Center(child: Text('Inicia sesión para ver tus favoritos'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Usuarios')
                  .doc(user.uid)
                  .collection('Favoritos')
                  .orderBy('agregadoEn', descending: true)
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Sin favoritos aún',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Toca el ♡ en un producto para guardarlo',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: imagenProducto(
                            data['imagen']?.toString(),
                            height: 56,
                            width: 56,
                          ),
                        ),
                        title: Text(data['titulo']?.toString() ?? ''),
                        subtitle: Text(formatoPrecio(data['costo'] ?? 0)),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => doc.reference.delete(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
