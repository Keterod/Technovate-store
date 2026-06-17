import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/atributo_definicion.dart';
import '../models/categoria_model.dart';
import 'categoria_service.dart';

class SeedService {
  final CategoriaService _categoriaService;
  final FirebaseFirestore _firestore;

  SeedService({CategoriaService? categoriaService, FirebaseFirestore? firestore})
      : _categoriaService = categoriaService ?? CategoriaService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<int> importarCategorias() async {
    final json = await rootBundle.loadString('assets/seed/categorias_seed.json');
    final data = jsonDecode(json) as Map<String, dynamic>;
    final lista = data['categorias'] as List<dynamic>;
    int count = 0;

    for (final item in lista) {
      final map = item as Map<String, dynamic>;
      final id = map['_id'] as String;
      final categoria = CategoriaModel(
        id: id,
        nombre: (map['nombre'] ?? '').toString(),
        icono: (map['icono'] ?? '').toString(),
        orden: (map['orden'] as int?) ?? 0,
        activo: map['activo'] as bool? ?? true,
        atributos: (map['atributos'] as List<dynamic>?)
                ?.map((a) =>
                    AtributoDefinicion.fromMap(a as Map<String, dynamic>))
                .toList() ??
            [],
      );
      await _categoriaService.saveCategoria(categoria);
      count++;
    }
    return count;
  }

  Future<int> importarSucursales() async {
    final json = await rootBundle.loadString('assets/seed/sucursales_seed.json');
    final data = jsonDecode(json) as Map<String, dynamic>;
    final lista = data['sucursales'] as List<dynamic>;
    int count = 0;

    for (final item in lista) {
      final map = item as Map<String, dynamic>;
      final ubicacion = map['ubicacion'] as Map<String, dynamic>;
      await _firestore.collection('sucursales').add({
        'nombre': map['nombre'],
        'direccion': map['direccion'],
        'ubicacion': GeoPoint(
          (ubicacion['_latitude'] as num).toDouble(),
          (ubicacion['_longitude'] as num).toDouble(),
        ),
      });
      count++;
    }
    return count;
  }
}
