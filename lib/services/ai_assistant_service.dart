import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../core/constants/app_constants.dart';
import '../models/assistant_response.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import 'product_service.dart';

class AiAssistantService {
  AiAssistantService({
    ProductService? productService,
    FirebaseFirestore? firestore,
    GenerativeModel? model,
  })  : _productService = productService ?? ProductService(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _model = model;

  final ProductService _productService;
  final FirebaseFirestore _firestore;
  final GenerativeModel? _model;

  GenerativeModel get _geminiModel {
    return _model ??
        FirebaseAI.googleAI().generativeModel(
            model: geminiAssistantModel,
            generationConfig: GenerationConfig(
              temperature: 0.25,
              maxOutputTokens: 1200,
            ),
            systemInstruction: Content.system(
              'Eres el Asesor Experto y Vendedor Pro de TECHNOVATE, la mejor tienda de tecnologia de Peru. '
              'Tu objetivo es guiar al cliente, asegurar la compatibilidad y facilitar la compra.\n\n'
              'REGLAS DE NEGOCIO:\n'
              '1. Recomienda solo usando productos del catalogo real. No inventes nombres, precios, ni caracteristicas.\n'
              '2. Estructura tus respuestas de recomendacion de manera profesional y atractiva.\n'
              '3. Realiza la validacion de compatibilidad en el armado de PCs:\n'
              '   - Socket: Placa madre y CPU deben tener el mismo socket (ej. AM4, LGA1700).\n'
              '   - RAM: Placa y RAM deben usar el mismo tipo (DDR4 o DDR5).\n'
              '   - Fuente de Poder: La potencia de la fuente (en Watts) debe ser igual o mayor a la recomendada para la GPU + CPU.\n'
              '   - Almacenamiento/Case: Valida si caben los componentes (SSD M.2, tamano de GPU).\n'
              '4. Si hay algun conflicto en el carrito actual o con la recomendacion, advierte firmemente al usuario y sugiere la alternativa correcta.\n'
              '5. Genera tags de acciones de carrito cuando el usuario lo solicite (ej. "agrega eso", "limpia el carrito", "cambia X por Y") o cuando recomiendes algo y sea ideal agregarlo.\n'
              'Sintaxis de acciones (colocalas al final de tu respuesta):\n'
              '[ACCION: AGREGAR_AL_CARRITO(id_producto)]\n'
              '[ACCION: QUITAR_DEL_CARRITO(id_producto)]\n'
              '[ACCION: LIMPIAR_CARRITO]\n'
              'Usa un tono entusiasta, tecnologico, claro y servicial.'
            ),
        );
  }

  Future<AssistantResponse> responder(
    String mensajeUsuario,
    List<CartItemModel> carritoActual,
  ) async {
    final products = await _productService.getAvailableProducts();
    if (products.isEmpty) {
      final emptyResponse = const AssistantResponse(
        message:
            'Todavía no hay productos registrados en el catálogo. Agrega productos desde el panel de Admin para que pueda guiarte.',
        recommendedProducts: [],
        usedFallback: true,
      );
      await _saveHistory(mensajeUsuario, emptyResponse);
      return emptyResponse;
    }

    final recommended = _recommendProducts(mensajeUsuario, products);
    final prompt = _buildPrompt(mensajeUsuario, products, recommended, carritoActual);

    try {
      final response = await _geminiModel.generateContent([Content.text(prompt)]);
      var text = response.text?.trim() ?? '';
      
      if (text.isNotEmpty) {
        final parsedActions = <String>[];
        
        // Parsear acciones del tipo [ACCION: AGREGAR_AL_CARRITO(id)]
        final regexAgregar = RegExp(r'\[ACCION:\s*AGREGAR_AL_CARRITO\(([^)]+)\)\]');
        final matchesAgregar = regexAgregar.allMatches(text);
        for (final match in matchesAgregar) {
          final id = match.group(1)!.trim();
          parsedActions.add('ADD_TO_CART:$id');
        }

        // Parsear acciones del tipo [ACCION: QUITAR_DEL_CARRITO(id)]
        final regexQuitar = RegExp(r'\[ACCION:\s*QUITAR_DEL_CARRITO\(([^)]+)\)\]');
        final matchesQuitar = regexQuitar.allMatches(text);
        for (final match in matchesQuitar) {
          final id = match.group(1)!.trim();
          parsedActions.add('REMOVE_FROM_CART:$id');
        }

        // Parsear acciones del tipo [ACCION: LIMPIAR_CARRITO]
        if (text.contains('[ACCION: LIMPIAR_CARRITO]')) {
          parsedActions.add('CLEAR_CART');
        }

        // Limpiar el texto para que el usuario no vea los brackets de las acciones internas
        var cleanText = text
            .replaceAll(RegExp(r'\[ACCION:\s*AGREGAR_AL_CARRITO\([^)]+\)\]'), '')
            .replaceAll(RegExp(r'\[ACCION:\s*QUITAR_DEL_CARRITO\([^)]+\)\]'), '')
            .replaceAll('[ACCION: LIMPIAR_CARRITO]', '')
            .trim();

        final aiResponse = AssistantResponse(
          message: cleanText,
          recommendedProducts: recommended,
          usedFallback: false,
          actions: parsedActions,
        );
        await _saveHistory(mensajeUsuario, aiResponse);
        return aiResponse;
      }
    } catch (_) {
      // Ignorar y caer en el fallback local
    }

    // Fallback local robusto
    final fallback = AssistantResponse(
      message: _buildLocalResponse(mensajeUsuario, recommended, products, carritoActual),
      recommendedProducts: recommended,
      usedFallback: true,
      actions: _parseLocalActions(mensajeUsuario, recommended),
    );
    await _saveHistory(mensajeUsuario, fallback);
    return fallback;
  }

  String _buildPrompt(
    String userMessage,
    List<ProductModel> products,
    List<ProductModel> recommended,
    List<CartItemModel> carritoActual,
  ) {
    final catalog = products.take(45).map((p) => p.toPromptLine()).join('\n');
    final selectedIds = recommended.map((p) => p.id).join(', ');
    final cartStr = carritoActual.isEmpty
        ? 'El carrito está vacío.'
        : carritoActual.map((c) => '- id: ${c.idProducto} | ${c.titulo} x ${c.cantidad}').join('\n');

    return '''
Consulta del cliente:
"$userMessage"

Estado del Carrito de Compras actual del cliente:
$cartStr

Productos preseleccionados por relevancia del catálogo:
$selectedIds

Catálogo Disponible en la tienda (nombre, precio, stock, especificaciones técnicas):
$catalog

Estructura obligatoria de respuesta (Usa markdown para que se vea premium y ordenado):
1. **DIAGNÓSTICO RÁPIDO**: Diagnostica brevemente qué busca el usuario, su presupuesto y uso principal.
2. **MEJOR OPCIÓN PRINCIPAL**: La opción ideal (nombre, precio y por qué es la mejor).
3. **OPCIÓN ECONÓMICA**: Alternativa económica viable si existe en el catálogo.
4. **OPCIÓN PREMIUM**: Alternativa de alta gama si existe.
5. **POR QUÉ SÍ / POR QUÉ NO**: Resumen de pros y contras técnicos (ej. más rendimiento, menos garantía, etc.).
6. **COMPATIBILIDAD EXPERTA**: Valida si los productos recomendados son compatibles entre sí, y también si son compatibles con lo que el cliente YA tiene en su carrito. (¡Presta especial atención a sockets de placa/procesador, fuente de poder y tipo de RAM DDR4/DDR5!).
7. **PREGUNTAS FALTANTES**: Una sola pregunta clave solo si faltan detalles importantes para recomendar mejor.

Si el cliente te pide agregar algo al carrito, o te pide "ármame una PC" y recomiendas componentes, recuerda colocar la etiqueta:
[ACCION: AGREGAR_AL_CARRITO(id_producto)]
al final del mensaje para cada producto recomendado.
''';
  }

  List<ProductModel> _recommendProducts(
    String message,
    List<ProductModel> products,
  ) {
    final budget = _extractBudget(message);
    final use = _detectUse(message);
    final keywords = _keywords(message);

    final scored = products.map((product) {
      var score = product.puntuacion * 2;
      final searchable =
          '${product.titulo} ${product.detalle} ${product.categoria} '
                  '${product.fabricante} ${product.tags.join(' ')} '
                  '${product.usoRecomendado.join(' ')} ${product.ram} ${product.procesador} '
                  '${product.gpu} ${product.almacenamiento} ${product.socket} ${product.tipoRam}'
              .toLowerCase();

      if (budget != null && product.costo <= budget) score += 8;
      if (budget != null && product.costo > budget) score -= 6;
      if (use != null && _productMatchesUse(product, use)) score += 6;
      for (final keyword in keywords) {
        if (searchable.contains(keyword)) score += 2.0;
      }
      if (product.inventario >= 5) score += 1;
      return MapEntry(product, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    final recommended = scored.map((entry) => entry.key).take(4).toList();
    if (recommended.isNotEmpty) return recommended;
    return products.take(4).toList();
  }

  String _buildLocalResponse(
    String userMessage,
    List<ProductModel> recommended,
    List<ProductModel> products,
    List<CartItemModel> carritoActual,
  ) {
    final budget = _extractBudget(userMessage);
    final use = _detectUse(userMessage);
    final selected = recommended.isEmpty ? products.take(3).toList() : recommended;
    final main = selected.first;
    
    final budgetText = budget == null
        ? 'sin presupuesto definido'
        : 'con presupuesto de S/. ${budget.toStringAsFixed(0)}';
    final useText = use == null ? '' : ' para $use';
    
    final options = selected
        .map((p) => '- **${p.titulo}**: S/. ${p.costo.toStringAsFixed(2)} (${p.categoria})')
        .join('\n');

    // Validación básica de compatibilidad local
    var compatibilidadWarn = '';
    if (carritoActual.isNotEmpty) {
      for (final cartItem in carritoActual) {
        final pCart = products.firstWhere((p) => p.id == cartItem.idProducto, orElse: () => main);
        for (final rec in selected) {
          if (pCart.socket.isNotEmpty && rec.socket.isNotEmpty && pCart.socket != rec.socket) {
            compatibilidadWarn += '\n⚠️ **Incompatibilidad de Socket**: La placa/procesador "${pCart.titulo}" (${pCart.socket}) no coincide con "${rec.titulo}" (${rec.socket}).';
          }
          if (pCart.tipoRam.isNotEmpty && rec.tipoRam.isNotEmpty && pCart.tipoRam != rec.tipoRam) {
            compatibilidadWarn += '\n⚠️ **Incompatibilidad de RAM**: Componentes usan RAM tipo "${pCart.tipoRam}" y "${rec.tipoRam}" combinadas.';
          }
        }
      }
    }

    return '''
### 1. DIAGNÓSTICO RÁPIDO
Buscas una recomendación $budgetText$useText.

### 2. MEJOR OPCIÓN PRINCIPAL
**${main.titulo}** (S/. ${main.costo.toStringAsFixed(2)})
Ideal por precio, rendimiento y disponibilidad de inventario.

### 3. OPCIONES SUGERIDAS
$options

### 4. POR QUÉ SÍ / POR QUÉ NO
- **Por qué sí**: Alto rendimiento, stock inmediato y garantía oficial.
- **Por qué no**: Dependiendo del presupuesto, puede haber opciones más avanzadas agotadas.

### 5. COMPATIBILIDAD EXPERTA${compatibilidadWarn.isEmpty ? '\nTodos los componentes seleccionados y en tu carrito son compatibles en socket, tipo de RAM y consumo.' : compatibilidadWarn}

### 6. PREGUNTAS FALTANTES
¿Hay alguna marca específica (Intel, AMD, NVIDIA) que prefieras en tu configuración?
''';
  }

  List<String> _parseLocalActions(String message, List<ProductModel> recommended) {
    final lower = message.toLowerCase();
    final actions = <String>[];
    if (lower.contains('agrega') || lower.contains('añadir') || lower.contains('carrito')) {
      if (recommended.isNotEmpty) {
        actions.add('ADD_TO_CART:${recommended.first.id}');
      }
    }
    if (lower.contains('limpia') || lower.contains('vaciar')) {
      actions.add('CLEAR_CART');
    }
    return actions;
  }

  Future<void> _saveHistory(
    String userMessage,
    AssistantResponse response,
  ) async {
    try {
      await _firestore.collection(assistantHistoryCollection).add({
        'usuario': 'invitado',
        'consulta': userMessage,
        'respuesta': response.message,
        'productoIds': response.recommendedProducts.map((p) => p.id).toList(),
        'acciones': response.actions,
        'usedFallback': response.usedFallback,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ignorar errores al guardar historial (ej. sin internet o reglas bloqueando)
    }
  }

  double? _extractBudget(String text) {
    final matches = RegExp(r'(\d+(?:[.,]\d+)?)').allMatches(text).toList();
    if (matches.isEmpty) return null;
    final values = matches
        .map((match) => double.tryParse(match.group(1)!.replaceAll(',', '.')))
        .whereType<double>()
        .toList();
    if (values.isEmpty) return null;
    values.sort();
    return values.last;
  }

  String? _detectUse(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('gaming') || lower.contains('jugar') || lower.contains('juegos')) return 'gaming';
    if (lower.contains('diseno') ||
        lower.contains('diseño') ||
        lower.contains('render') ||
        lower.contains('edicion') ||
        lower.contains('edición')) {
      return 'diseno grafico';
    }
    if (lower.contains('oficina') ||
        lower.contains('estudio') ||
        lower.contains('clases') ||
        lower.contains('colegio') ||
        lower.contains('universidad')) {
      return 'oficina/estudio';
    }
    if (lower.contains('programar') || lower.contains('desarrollo') || lower.contains('codigo') || lower.contains('código')) {
      return 'programacion';
    }
    return null;
  }

  bool _productMatchesUse(ProductModel product, String use) {
    final searchable =
        '${product.titulo} ${product.detalle} ${product.categoria} '
                '${product.tags.join(' ')} ${product.usoRecomendado.join(' ')}'
            .toLowerCase();
    if (use == 'gaming') {
      return searchable.contains('gaming') ||
          searchable.contains('gpu') ||
          searchable.contains('rtx') ||
          searchable.contains('radeon') ||
          searchable.contains('monitor') ||
          searchable.contains('pc');
    }
    if (use == 'diseno grafico') {
      return searchable.contains('laptop') ||
          searchable.contains('monitor') ||
          searchable.contains('gpu') ||
          searchable.contains('rtx') ||
          searchable.contains('ryzen 7') ||
          searchable.contains('core i7') ||
          searchable.contains('ips');
    }
    if (use == 'oficina/estudio') {
      return searchable.contains('laptop') ||
          searchable.contains('tablet') ||
          searchable.contains('monitor') ||
          searchable.contains('economico') ||
          searchable.contains('estudiante');
    }
    if (use == 'programacion') {
      return searchable.contains('laptop') ||
          searchable.contains('monitor') ||
          searchable.contains('teclado') ||
          searchable.contains('ssd') ||
          searchable.contains('16gb');
    }
    return true;
  }

  List<String> _keywords(String text) {
    const ignored = {
      'para',
      'quiero',
      'tengo',
      'soles',
      'recomiendas',
      'recomienda',
      'necesito',
      'algo',
      'hola',
      'asistente',
    };
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-záéíóúñ0-9]+'))
        .where((word) => word.length >= 3 && !ignored.contains(word))
        .toSet()
        .toList();
  }
}
