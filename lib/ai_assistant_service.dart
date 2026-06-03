import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';

import 'digizone_utils.dart';

class ProductoContexto {
  final String id;
  final String titulo;
  final String detalle;
  final String categoria;
  final String fabricante;
  final double costo;
  final int inventario;
  final double puntuacion;

  ProductoContexto({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.categoria,
    required this.fabricante,
    required this.costo,
    required this.inventario,
    required this.puntuacion,
  });

  bool get disponible => inventario > 0;

  factory ProductoContexto.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ProductoContexto(
      id: doc.id,
      titulo: (data['titulo'] ?? '').toString(),
      detalle: (data['detalle'] ?? '').toString(),
      categoria: (data['categoria'] ?? '').toString(),
      fabricante: (data['fabricante'] ?? '').toString(),
      costo: ((data['costo'] ?? 0) as num).toDouble(),
      inventario: ((data['inventario'] ?? 0) as num).toInt(),
      puntuacion: ((data['puntuacion'] ?? 0) as num).toDouble(),
    );
  }

  String toPromptLine() {
    return '- $titulo | categoria: $categoria | marca: $fabricante | '
        'precio: S/. ${costo.toStringAsFixed(2)} | stock: $inventario | '
        'rating: ${puntuacion.toStringAsFixed(1)} | detalle: $detalle';
  }
}

class AiAssistantService {
  AiAssistantService({FirebaseFirestore? firestore, GenerativeModel? model})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _model = model;

  final FirebaseFirestore _firestore;
  final GenerativeModel? _model;

  GenerativeModel get _geminiModel {
    return _model ??
        FirebaseAI.googleAI().generativeModel(
          model: 'gemini-3.1-flash-lite',
          generationConfig: GenerationConfig(
            temperature: 0.4,
            maxOutputTokens: 650,
          ),
          systemInstruction: Content.system(
            'Eres el asistente de TECHNOVATE, una tienda de tecnologia en Peru. '
            'Ayudas a recomendar laptops, PCs, componentes, perifericos y software. '
            'Usa solo los productos del catalogo entregado cuando sugieras productos. '
            'Responde en espanol claro, breve y practico. Incluye presupuesto en soles, '
            'uso, recomendacion principal, alternativas y compatibilidad basica cuando aplique. '
            'Si falta informacion, haz una pregunta concreta.',
          ),
        );
  }

  Future<String> responder(String mensajeUsuario) async {
    final productos = await _obtenerProductosDisponibles();
    if (productos.isEmpty) {
      return 'Todavia no hay productos disponibles en el catalogo. Agrega productos desde Admin y luego puedo recomendar opciones.';
    }

    final prompt = _construirPrompt(mensajeUsuario, productos);

    try {
      final response = await _geminiModel.generateContent([
        Content.text(prompt),
      ]);
      final texto = response.text?.trim();
      if (texto != null && texto.isNotEmpty) return texto;
    } catch (_) {
      // Si Firebase AI Logic aun no esta activado, damos una respuesta util local.
    }

    return _respuestaLocal(mensajeUsuario, productos);
  }

  Future<List<ProductoContexto>> _obtenerProductosDisponibles() async {
    final snapshot = await _firestore
        .collection(digizoneColeccion)
        .where('disponible', isNotEqualTo: false)
        .get();

    final productos = snapshot.docs
        .map(ProductoContexto.fromFirestore)
        .where((producto) => producto.disponible)
        .toList();

    productos.sort((a, b) {
      final porRating = b.puntuacion.compareTo(a.puntuacion);
      if (porRating != 0) return porRating;
      return a.costo.compareTo(b.costo);
    });

    return productos;
  }

  String _construirPrompt(
    String mensajeUsuario,
    List<ProductoContexto> productos,
  ) {
    final catalogo = productos.take(30).map((p) => p.toPromptLine()).join('\n');
    return '''
Consulta del cliente:
$mensajeUsuario

Catalogo disponible:
$catalogo

Devuelve:
1. Recomendacion principal.
2. Por que encaja con el presupuesto/uso.
3. Productos sugeridos del catalogo.
4. Compatibilidad basica o advertencias.
5. Una pregunta final solo si necesitas mas datos.
''';
  }

  String _respuestaLocal(
    String mensajeUsuario,
    List<ProductoContexto> productos,
  ) {
    final presupuesto = _extraerPresupuesto(mensajeUsuario);
    final uso = _detectarUso(mensajeUsuario);
    final texto = mensajeUsuario.toLowerCase();

    final candidatos = productos.where((producto) {
      final dentroPresupuesto =
          presupuesto == null || producto.costo <= presupuesto;
      final coincideUso = uso == null || _productoSirveParaUso(producto, uso);
      final coincideBusqueda =
          texto.length < 4 ||
          '${producto.titulo} ${producto.detalle} ${producto.categoria}'
              .toLowerCase()
              .contains(_palabraClave(texto));
      return dentroPresupuesto && (coincideUso || coincideBusqueda);
    }).toList();

    final seleccion = (candidatos.isEmpty ? productos : candidatos)
        .take(3)
        .toList();
    final principal = seleccion.first;
    final presupuestoTexto = presupuesto == null
        ? 'sin presupuesto definido'
        : 'con presupuesto de S/. ${presupuesto.toStringAsFixed(0)}';

    final sugeridos = seleccion
        .map(
          (p) =>
              '- ${p.titulo}: S/. ${p.costo.toStringAsFixed(2)} (${p.categoria})',
        )
        .join('\n');

    return '''
Recomendacion principal: ${principal.titulo}

Para tu consulta $presupuestoTexto${uso == null ? '' : ' y uso $uso'}, esta opcion es una buena base por precio, stock y puntuacion.

Productos sugeridos:
$sugeridos

Compatibilidad basica: revisa que el producto cubra el uso principal, que este en stock y que los accesorios/componentes usen conexiones compatibles. Si vas a armar una PC, confirma socket de placa/procesador, tipo de RAM, potencia de fuente y espacio del case.
''';
  }

  double? _extraerPresupuesto(String texto) {
    final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(texto);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  String? _detectarUso(String texto) {
    final lower = texto.toLowerCase();
    if (lower.contains('gaming') || lower.contains('jugar')) return 'gaming';
    if (lower.contains('diseno') ||
        lower.contains('diseño') ||
        lower.contains('render') ||
        lower.contains('edicion')) {
      return 'diseno grafico';
    }
    if (lower.contains('oficina') ||
        lower.contains('estudio') ||
        lower.contains('clases')) {
      return 'oficina/estudio';
    }
    if (lower.contains('programar') || lower.contains('desarrollo')) {
      return 'programacion';
    }
    return null;
  }

  bool _productoSirveParaUso(ProductoContexto producto, String uso) {
    final texto = '${producto.titulo} ${producto.detalle} ${producto.categoria}'
        .toLowerCase();
    if (uso == 'gaming') {
      return texto.contains('gaming') ||
          texto.contains('gpu') ||
          texto.contains('rtx') ||
          texto.contains('monitor') ||
          texto.contains('pc');
    }
    if (uso == 'diseno grafico') {
      return texto.contains('laptop') ||
          texto.contains('monitor') ||
          texto.contains('gpu') ||
          texto.contains('rtx') ||
          texto.contains('tablet');
    }
    if (uso == 'oficina/estudio') {
      return texto.contains('laptop') ||
          texto.contains('tablet') ||
          texto.contains('monitor') ||
          texto.contains('software');
    }
    if (uso == 'programacion') {
      return texto.contains('laptop') ||
          texto.contains('monitor') ||
          texto.contains('teclado') ||
          texto.contains('software');
    }
    return true;
  }

  String _palabraClave(String texto) {
    final palabras = texto
        .split(RegExp(r'\s+'))
        .where((palabra) => palabra.length >= 4)
        .toList();
    if (palabras.isEmpty) return texto;
    return palabras.first;
  }
}
