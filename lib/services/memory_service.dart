import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MemoryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MemoryService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  static const Duration _timeout = Duration(seconds: 5);

  Future<void> trackProductView({
    required String productoId,
    required String titulo,
    required double costo,
    required String imagen,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    debugPrint('DEBUG MEMORY: track view start productId=$productoId');
    try {
      await _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('HistorialVistas')
          .add({
            'productoId': productoId,
            'titulo': titulo,
            'costo': costo,
            'imagen': imagen,
            'vistoEn': FieldValue.serverTimestamp(),
          })
          .timeout(_timeout);
      debugPrint('DEBUG MEMORY: track view done productId=$productoId');
    } on TimeoutException catch (e) {
      debugPrint(
        'DEBUG MEMORY: track view error productId=$productoId error=$e',
      );
    } catch (e) {
      debugPrint(
        'DEBUG MEMORY: track view error productId=$productoId error=$e',
      );
    }
  }

  Future<void> trackSearch(String query) async {
    final uid = _uid;
    if (uid == null || query.trim().isEmpty) return;
    try {
      await _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('HistorialBusquedas')
          .add({
            'query': query.trim().toLowerCase(),
            'buscadoEn': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('DEBUG MEMORY: track search error=$e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentViews({int limit = 10}) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final snapshot = await _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('HistorialVistas')
          .orderBy('vistoEn', descending: true)
          .limit(limit)
          .get()
          .timeout(_timeout);
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('DEBUG MEMORY: recent views error=$e');
      return [];
    }
  }

  Future<List<String>> getRecentSearches({int limit = 5}) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final snapshot = await _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('HistorialBusquedas')
          .orderBy('buscadoEn', descending: true)
          .limit(limit)
          .get()
          .timeout(_timeout);
      return snapshot.docs
          .map((doc) => (doc.data()['query'] ?? '').toString())
          .where((q) => q.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('DEBUG MEMORY: recent searches error=$e');
      return [];
    }
  }

  Future<void> toggleFavorite(String productoId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final doc = _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('Favoritos')
          .doc(productoId);
      final snapshot = await doc.get().timeout(_timeout);
      if (snapshot.exists) {
        await doc.delete().timeout(_timeout);
      } else {
        await doc
            .set({
              'agregadoEn': FieldValue.serverTimestamp(),
              'estabaAgotado': false,
            })
            .timeout(_timeout);
      }
    } catch (e) {
      debugPrint(
        'DEBUG MEMORY: toggle favorite error productId=$productoId error=$e',
      );
    }
  }

  Future<bool> isFavorite(String productoId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final doc = await _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('Favoritos')
          .doc(productoId)
          .get()
          .timeout(_timeout);
      return doc.exists;
    } catch (e) {
      debugPrint(
        'DEBUG MEMORY: favorite check error productId=$productoId error=$e',
      );
      return false;
    }
  }

  Future<Set<String>> getFavoriteIds() async {
    final uid = _uid;
    if (uid == null) return {};
    try {
      final snapshot = await _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('Favoritos')
          .get()
          .timeout(_timeout);
      return snapshot.docs.map((d) => d.id).toSet();
    } catch (e) {
      debugPrint('DEBUG MEMORY: favorite ids error=$e');
      return {};
    }
  }

  Future<List<String>> getWatchedProductIds() async {
    final uid = _uid;
    if (uid == null) return [];
    final ids = <String>{};
    try {
      final views = await _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('HistorialVistas')
          .orderBy('vistoEn', descending: true)
          .limit(10)
          .get()
          .timeout(_timeout);
      for (final doc in views.docs) {
        final pid = doc.data()['productoId']?.toString();
        if (pid != null) ids.add(pid);
      }
    } catch (e) {
      debugPrint('DEBUG MEMORY: watched views error=$e');
    }
    try {
      final favs = await _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('Favoritos')
          .get()
          .timeout(_timeout);
      for (final doc in favs.docs) {
        ids.add(doc.id);
      }
    } catch (e) {
      debugPrint('DEBUG MEMORY: watched favorites error=$e');
    }
    return ids.toList();
  }

  Future<List<Map<String, dynamic>>> checkPriceDrops() async {
    debugPrint('DEBUG MEMORY: check price drops skipped on detail');
    final uid = _uid;
    if (uid == null) return [];
    final drops = <Map<String, dynamic>>[];
    try {
      final views = await _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('HistorialVistas')
          .orderBy('vistoEn', descending: true)
          .limit(20)
          .get()
          .timeout(_timeout);
      final productosSnapshot = await _firestore
          .collection('digizone_productos')
          .limit(50)
          .get()
          .timeout(_timeout);
      final productos = <String, Map<String, dynamic>>{};
      for (final doc in productosSnapshot.docs) {
        productos[doc.id] = doc.data();
      }
      final visitados = <String, double>{};
      for (final doc in views.docs) {
        final data = doc.data();
        final pid = data['productoId']?.toString();
        final precioVisto = (data['costo'] as num?)?.toDouble();
        if (pid != null && precioVisto != null && !visitados.containsKey(pid)) {
          visitados[pid] = precioVisto;
        }
      }
      for (final entry in visitados.entries) {
        final actual = productos[entry.key];
        if (actual == null) continue;
        final precioActual = (actual['costo'] as num?)?.toDouble();
        if (precioActual == null) continue;
        if (precioActual < entry.value) {
          drops.add({
            'productoId': entry.key,
            'titulo': actual['titulo'] ?? '',
            'imagen': actual['imagen'] ?? '',
            'precioAnterior': entry.value,
            'precioActual': precioActual,
            'diferencia': entry.value - precioActual,
          });
        }
      }
    } catch (e) {
      debugPrint('DEBUG MEMORY: check price drops error=$e');
    }
    return drops;
  }

  Future<List<Map<String, dynamic>>> checkStockReturns() async {
    final uid = _uid;
    if (uid == null) return [];
    final alerts = <Map<String, dynamic>>[];
    try {
      final favs = await _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('Favoritos')
          .get()
          .timeout(_timeout);
      if (favs.docs.isEmpty) return [];
      final productosSnapshot = await _firestore
          .collection('digizone_productos')
          .limit(50)
          .get()
          .timeout(_timeout);
      final productos = <String, Map<String, dynamic>>{};
      for (final doc in productosSnapshot.docs) {
        productos[doc.id] = doc.data();
      }
      for (final doc in favs.docs) {
        final actual = productos[doc.id];
        if (actual == null) continue;
        final inventario = (actual['inventario'] as num?)?.toInt() ?? 0;
        final disponible = actual['disponible'] != false;
        if (disponible && inventario > 0) {
          final favData = doc.data();
          final estabaAgotado = favData['estabaAgotado'] == true;
          if (estabaAgotado) {
            alerts.add({
              'productoId': doc.id,
              'titulo': actual['titulo'] ?? '',
              'imagen': actual['imagen'] ?? '',
              'stock': inventario,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('DEBUG MEMORY: check stock returns error=$e');
    }
    return alerts;
  }
}
