import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String titulo;
  final String detalle;
  final String fabricante;
  final String categoria;
  final double costo;
  final int inventario;
  final String garantia;
  final double puntuacion;
  final String imagen;
  final bool disponible;
  final Map<String, dynamic> especificaciones;
  final List<String> tags;
  final List<String> usoRecomendado;

  const ProductModel({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.fabricante,
    required this.categoria,
    required this.costo,
    required this.inventario,
    required this.garantia,
    required this.puntuacion,
    required this.imagen,
    required this.disponible,
    required this.especificaciones,
    required this.tags,
    required this.usoRecomendado,
  });

  bool get tieneStock => disponible && inventario > 0;

  Map<String, dynamic> get atributos => especificaciones;

  String get ram => (especificaciones['ram'] ?? '').toString();
  String get procesador => (especificaciones['procesador'] ?? '').toString();
  String get gpu => (especificaciones['gpu'] ?? '').toString();
  String get almacenamiento => (especificaciones['almacenamiento'] ?? '').toString();
  String get socket => (especificaciones['socket'] ?? '').toString();
  String get tipoRam => (especificaciones['tipoRam'] ?? '').toString();
  int get potenciaFuente => int.tryParse(especificaciones['potenciaFuente']?.toString() ?? '') ?? 0;

  factory ProductModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProductModel.fromMap(doc.id, data);
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> data) {
    final especs = (data['especificaciones'] as Map? ?? data['atributos'] as Map? ?? {});
    return ProductModel(
      id: id,
      titulo: (data['titulo'] ?? '').toString(),
      detalle: (data['detalle'] ?? '').toString(),
      fabricante: (data['fabricante'] ?? '').toString(),
      categoria: (data['categoria'] ?? data['categoriaId'] ?? '').toString(),
      costo: ((data['costo'] ?? 0) as num).toDouble(),
      inventario: ((data['inventario'] ?? 0) as num).toInt(),
      garantia: (data['garantia'] ?? 'Sin garantia').toString(),
      puntuacion: ((data['puntuacion'] ?? 0) as num).toDouble(),
      imagen: (data['imagen'] ?? '').toString(),
      disponible: data['disponible'] != false,
      especificaciones: Map<String, dynamic>.from(especs),
      tags: _stringList(data['tags']),
      usoRecomendado: _stringList(data['usoRecomendado']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'detalle': detalle,
      'fabricante': fabricante,
      'categoria': categoria,
      'categoriaId': categoria,
      'costo': costo,
      'inventario': inventario,
      'garantia': garantia,
      'puntuacion': puntuacion,
      'imagen': imagen,
      'disponible': disponible,
      'especificaciones': especificaciones,
      'atributos': especificaciones,
      'tags': tags,
      'usoRecomendado': usoRecomendado,
    };
  }

  String toPromptLine() {
    final specs = especificaciones.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
    final usos = usoRecomendado.join(', ');
    return '- id: $id | $titulo | categoria: $categoria | marca: $fabricante | '
        'precio: S/. ${costo.toStringAsFixed(2)} | stock: $inventario | '
        'rating: ${puntuacion.toStringAsFixed(1)} | garantia: $garantia | '
        'usos: $usos | specs: $specs | detalle: $detalle';
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    if (value is String && value.trim().isNotEmpty) {
      return value.split(',').map((item) => item.trim()).toList();
    }
    return const [];
  }
}
