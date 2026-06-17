import 'package:cloud_firestore/cloud_firestore.dart';
import 'atributo_definicion.dart';

class CategoriaModel {
  final String id;
  final String nombre;
  final String icono;
  final int orden;
  final bool activo;
  final List<AtributoDefinicion> atributos;

  const CategoriaModel({
    required this.id,
    required this.nombre,
    this.icono = '',
    this.orden = 0,
    this.activo = true,
    this.atributos = const [],
  });

  factory CategoriaModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CategoriaModel.fromMap(doc.id, data);
  }

  factory CategoriaModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoriaModel(
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
  }

  Map<String, dynamic> toFirestore() => {
        'nombre': nombre,
        'icono': icono,
        'orden': orden,
        'activo': activo,
        'atributos': atributos.map((a) => a.toMap()).toList(),
      };
}
