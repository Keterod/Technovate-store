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
              temperature: 0.3,
              maxOutputTokens: 1500,
            ),
            systemInstruction: Content.system(
              'Eres TECHNOVATE AI, un asesor experto en computadoras, hardware, gaming, productividad y tecnologia. '
              'Tu funcion NO es ser un chatbot generico. '
              'Tu objetivo es ayudar a los clientes a encontrar los mejores productos disponibles en el '
              'catalogo de TECHNOVATE Store.\n\n'
              'REGLAS OBLIGATORIAS:\n'
              '1. Utiliza unicamente los productos proporcionados en el catalogo.\n'
              '2. Nunca inventes productos, precios o stock.\n'
              '3. Si un producto no existe en el catalogo, indicarlo claramente.\n'
              '4. Prioriza la experiencia del cliente y las ventas.\n'
              '5. Explica las recomendaciones de forma sencilla.\n'
              '6. Manten respuestas breves y utiles.\n'
              '7. Cuando sea posible, recomienda productos complementarios.\n'
              '8. Siempre considera compatibilidad entre componentes.\n\n'
              'CAPACIDADES:\n'
              '- Recomendacion de productos: Analiza la necesidad, busca productos, explica por que.\n'
              '- Configuracion por presupuesto: Arma la mejor configuracion posible dentro del presupuesto, '
              'priorizando rendimiento/precio.\n'
              '- Compatibilidad: Valida socket, tipo RAM y wattaje de fuente usando datos del catalogo.\n'
              '- Ventas Inteligentes: Tras recomendar, sugiere accesorios, mejoras futuras o complementos.\n\n'
              'FORMATO DE RESPUESTA:\n'
              '1. Recomendacion principal.\n'
              '2. Explicacion breve.\n'
              '3. Productos recomendados.\n'
              '4. Precio aproximado.\n'
              '5. Recomendacion adicional.\n\n'
              'Cuando el cliente solicite agregar/quitar/limpiar el carrito, o cuando recomiendes '
              'productos ideales, genera las acciones al FINAL:\n'
              '[ACCION: AGREGAR_AL_CARRITO(id_producto)]\n'
              '[ACCION: QUITAR_DEL_CARRITO(id_producto)]\n'
              '[ACCION: LIMPIAR_CARRITO]\n'
              'Ejemplo: si recomiendas 3 productos, agrega 3 tags [ACCION: AGREGAR_AL_CARRITO(id)] uno por cada uno.'
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
    final productMap = {for (final p in products) p.id: p};

    final porCategoria = <String, List<ProductModel>>{};
    for (final p in products) {
      porCategoria.putIfAbsent(p.categoria, () => []).add(p);
    }
    final catalogByCategory = porCategoria.entries
        .map((entry) {
          return '--- ${entry.key} ---\n${entry.value.take(12).map((p) => p.toPromptLine()).join('\n')}';
        })
        .join('\n\n');

    final cartStr = carritoActual.isEmpty
        ? 'El carrito está vacío.'
        : carritoActual.map((c) {
            final p = productMap[c.idProducto];
            if (p == null) return '- ${c.titulo} x${c.cantidad} (producto no encontrado)';
            return '- id: ${c.idProducto} | ${c.titulo} x${c.cantidad} | S/. ${(p.costo * c.cantidad).toStringAsFixed(2)} | stock: ${p.inventario} | socket: ${p.socket} | ram: ${p.tipoRam}';
          }).join('\n');

    final cartTotal = carritoActual.fold<double>(
      0,
      (sum, c) => sum + (productMap[c.idProducto]?.costo ?? 0) * c.cantidad,
    );

    return '''
## Catalogo Disponible

$catalogByCategory

## Carrito Actual del Cliente

$cartStr
Total: S/. ${cartTotal.toStringAsFixed(2)}

## Consulta del Usuario

$userMessage

Genera la mejor recomendacion posible utilizando exclusivamente la informacion del catalogo proporcionado.
Si recomiendas productos y el cliente parece interesado, agrega al final de tu respuesta:
[ACCION: AGREGAR_AL_CARRITO(id_producto)] por cada producto recomendado.
Si te pide limpiar el carrito: [ACCION: LIMPIAR_CARRITO]
Si te pide quitar algo: [ACCION: QUITAR_DEL_CARRITO(id)]
''';
  }

  List<ProductModel> _recommendProducts(
    String message,
    List<ProductModel> products,
  ) {
    final lowerMsg = message.toLowerCase();
    final budget = _extractBudget(message);
    final use = _detectUse(message);
    final keywords = _keywords(message);
    final categoriasMencionadas = _categorias.keys
        .where((cat) => lowerMsg.contains(cat.toLowerCase()))
        .map((cat) => _categorias[cat]!)
        .toSet();

    final scored = products.map((product) {
      final searchable =
          '${product.titulo} ${product.detalle} ${product.categoria} '
                  '${product.fabricante} ${product.tags.join(' ')} '
                  '${product.usoRecomendado.join(' ')} ${product.ram} ${product.procesador} '
                  '${product.gpu} ${product.almacenamiento} ${product.socket} ${product.tipoRam}'
              .toLowerCase();

      var score = 0.0;

      // Coincidencia en titulo — señal mas fuerte
      for (final kw in keywords) {
        if (product.titulo.toLowerCase().contains(kw)) score += 15;
      }

      // Keywords en el resto del producto
      var matchCount = 0;
      for (final keyword in keywords) {
        if (searchable.contains(keyword)) {
          score += 5;
          matchCount++;
        }
      }

      // Sin ningun keyword match -> penaliza fuerte
      if (matchCount == 0 && keywords.isNotEmpty) {
        score -= 20;
      }

      // Categoria mencionada por el usuario
      if (categoriasMencionadas.contains(product.categoria.toLowerCase())) {
        score += 12;
      }

      // Presupuesto
      if (budget != null && product.costo <= budget) score += 10;
      if (budget != null && product.costo > budget * 1.15) score -= 8;

      // Uso detectado
      if (use != null && _productMatchesUse(product, use)) score += 8;

      // Rating como desempate menor
      score += product.puntuacion * 0.3;

      // Stock disponible suma poco
      if (product.inventario >= 5) score += 1;

      return MapEntry(product, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    final recommended = scored.map((entry) => entry.key).take(4).toList();
    if (recommended.isNotEmpty) return recommended;
    return products.take(4).toList();
  }

  static const Map<String, String> _categorias = {
    'Laptop': 'laptop',
    'Smartphone': 'smartphone',
    'Tablet': 'tablet',
    'Monitor': 'monitor',
    'Periféricos': 'periférico',
    'Componentes': 'hardware',
    'Equipos': 'equipo',
    'Software': 'software',
  };

  String _buildLocalResponse(
    String userMessage,
    List<ProductModel> recommended,
    List<ProductModel> products,
    List<CartItemModel> carritoActual,
  ) {
    final budget = _extractBudget(userMessage);
    final selected = recommended.isEmpty ? products.take(3).toList() : recommended;
    if (selected.isEmpty) {
      return 'Actualmente no hay productos disponibles en el catalogo. '
          'Vuelve pronto, estamos renovando nuestro inventario.';
    }
    final main = selected.first;
    final productMap = {for (final p in products) p.id: p};

    final options = selected
        .map((p) => '- **${p.titulo}**: S/. ${p.costo.toStringAsFixed(2)} (${p.categoria}) | Stock: ${p.inventario}')
        .join('\n');

    var compatibilidadWarn = '';
    for (final cartItem in carritoActual) {
      final pCart = productMap[cartItem.idProducto];
      if (pCart == null) continue;
      for (final rec in selected) {
        if (pCart.socket.isNotEmpty && rec.socket.isNotEmpty && pCart.socket != rec.socket) {
          compatibilidadWarn += '\n⚠️ **Socket**: "${pCart.titulo}" (${pCart.socket}) no coincide con "${rec.titulo}" (${rec.socket}).';
        }
        if (pCart.tipoRam.isNotEmpty && rec.tipoRam.isNotEmpty && pCart.tipoRam != rec.tipoRam) {
          compatibilidadWarn += '\n⚠️ **RAM**: "${pCart.titulo}" usa ${pCart.tipoRam} y "${rec.titulo}" usa ${rec.tipoRam}.';
        }
      }
    }

    final stockWarn = selected.where((p) => p.inventario < 3).map((p) => p.titulo).toList();

    return '''
**Recomendacion principal:**
${main.titulo} — S/. ${main.costo.toStringAsFixed(2)}

**Explicacion:**
${main.detalle}

**Productos recomendados:**
$options

**Precio aproximado:**
S/. ${main.costo.toStringAsFixed(2)}

**Recomendacion adicional:**
${compatibilidadWarn.isEmpty ? 'Todos los componentes son compatibles.' : compatibilidadWarn}
${stockWarn.isNotEmpty ? 'Stock bajo: ${stockWarn.join(", ")} — podrian agotarse pronto.' : ''}
${budget == null ? '\n¿Tienes un presupuesto definido? Puedo ayudarte a encontrar la mejor opcion.' : ''}
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
    if (lower.contains('gaming') ||
        lower.contains('jugar') ||
        lower.contains('juegos') ||
        lower.contains('fortnite') ||
        lower.contains('valorant') ||
        lower.contains('gamer')) {
      return 'gaming';
    }
    if (lower.contains('diseno') ||
        lower.contains('diseñ') ||
        lower.contains('render') ||
        lower.contains('edicion') ||
        lower.contains('edición') ||
        lower.contains('photoshop') ||
        lower.contains('illustrator') ||
        lower.contains('blender') ||
        lower.contains('autocad') ||
        lower.contains('video')) {
      return 'diseno grafico';
    }
    if (lower.contains('oficina') ||
        lower.contains('estudio') ||
        lower.contains('clases') ||
        lower.contains('colegio') ||
        lower.contains('universidad') ||
        lower.contains('estudiante') ||
        lower.contains('trabajo') ||
        lower.contains('tareas') ||
        lower.contains('office')) {
      return 'oficina/estudio';
    }
    if (lower.contains('program') ||
        lower.contains('desarrollo') ||
        lower.contains('codigo') ||
        lower.contains('código') ||
        lower.contains('software') ||
        lower.contains('developer') ||
        lower.contains('ide')) {
      return 'programacion';
    }
    if (lower.contains('music') ||
        lower.contains('produccion') ||
        lower.contains('audio') ||
        lower.contains('podcast')) {
      return 'produccion musical';
    }
    return null;
  }

  bool _productMatchesUse(ProductModel product, String use) {
    final searchable =
        '${product.titulo} ${product.detalle} ${product.categoria} '
                '${product.tags.join(' ')} ${product.usoRecomendado.join(' ')}'
            .toLowerCase();
    switch (use) {
      case 'gaming':
        return searchable.contains('gaming') ||
            searchable.contains('gpu') ||
            searchable.contains('rtx') ||
            searchable.contains('radeon') ||
            searchable.contains('monitor') ||
            searchable.contains('pc') ||
            searchable.contains('teclado') ||
            searchable.contains('mouse') ||
            searchable.contains('audifono');
      case 'diseno grafico':
        return searchable.contains('laptop') ||
            searchable.contains('monitor') ||
            searchable.contains('gpu') ||
            searchable.contains('rtx') ||
            searchable.contains('ryzen 7') ||
            searchable.contains('core i7') ||
            searchable.contains('ips') ||
            searchable.contains('oled') ||
            searchable.contains('16gb') ||
            searchable.contains('32gb');
      case 'oficina/estudio':
        return searchable.contains('laptop') ||
            searchable.contains('tablet') ||
            searchable.contains('monitor') ||
            searchable.contains('economico') ||
            searchable.contains('estudiante') ||
            searchable.contains('webcam') ||
            searchable.contains('teclado') ||
            searchable.contains('mouse');
      case 'programacion':
        return searchable.contains('laptop') ||
            searchable.contains('monitor') ||
            searchable.contains('teclado') ||
            searchable.contains('ssd') ||
            searchable.contains('16gb') ||
            searchable.contains('32gb') ||
            searchable.contains('ultrawide');
      case 'produccion musical':
        return searchable.contains('laptop') ||
            searchable.contains('audifono') ||
            searchable.contains('parlante') ||
            searchable.contains('ssd') ||
            searchable.contains('16gb');
      default:
        return true;
    }
  }

  List<String> _keywords(String text) {
    const ignorados = {
      'para', 'quiero', 'tengo', 'soles', 'recomiendas', 'recomienda',
      'necesito', 'algo', 'hola', 'asistente', 'una', 'que', 'los',
      'las', 'por', 'con', 'del', 'mas', 'más', 'pero', 'como',
      'todo', 'esta', 'entre', 'cual', 'cuales', 'puedes', 'buenas',
      'tardes', 'dias', 'noches', 'gracias', 'porfa', 'ayuda',
    };
    final words = text
        .toLowerCase()
        .split(RegExp(r'[^a-záéíóúñ0-9]+'))
        .where((w) => w.length >= 3 && !ignorados.contains(w))
        .toSet()
        .toList();
    // Palabras compuestas de 2 palabras clave (ej. "tarjeta grafica", "disco duro", "fuente poder")
    final bigrams = <String>[];
    for (var i = 0; i < words.length - 1; i++) {
      bigrams.add('${words[i]} ${words[i + 1]}');
    }
    return [...bigrams, ...words];
  }
}
