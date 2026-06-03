import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../models/product_model.dart';
import 'memory_service.dart';
import 'product_service.dart';

class ConciergeService {
  final MemoryService _memory;
  final ProductService _products;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GenerativeModel? _model;

  ConciergeService({
    MemoryService? memory,
    ProductService? products,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GenerativeModel? model,
  })  : _memory = memory ?? MemoryService(),
        _products = products ?? ProductService(),
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _model = model;

  GenerativeModel get _geminiModel {
    return _model ??
        FirebaseAI.googleAI().generativeModel(
          model: geminiAssistantModel,
          generationConfig: GenerationConfig(
            temperature: 0.5,
            maxOutputTokens: 400,
          ),
        );
  }

  Future<String> generarSaludo() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Hola, inicia sesion para recomendaciones personalizadas.';

    List<Map<String, dynamic>>? drops;
    List<Map<String, dynamic>>? stocks;

    try {
      final views = await _memory.getRecentViews(limit: 3);
      final searches = await _memory.getRecentSearches();
      drops = await _memory.checkPriceDrops();
      stocks = await _memory.checkStockReturns();

      final hasHistory = views.isNotEmpty || searches.isNotEmpty;
      final hasAlerts = drops.isNotEmpty || stocks.isNotEmpty;

      if (!hasHistory && !hasAlerts) {
        return 'Bienvenido a TECHNOVATE! Soy tu asistente personal de compras. '
            'Explora la tienda o preguntame lo que necesites.';
      }

      final viewsText = views.map((v) => '- ${v['titulo']} (S/ ${(v['costo'] as num).toStringAsFixed(2)})').join('\n');
      final searchesText = searches.take(3).join(', ');
      final dropsText = drops.map((d) => '- ${d['titulo']}: bajo S/ ${(d['diferencia'] as num).toStringAsFixed(2)}').join('\n');
      final stockText = stocks.map((s) => '- ${s['titulo']}: ${s['stock']} en stock').join('\n');

      final prompt = '''
Eres el asistente concierge de TECHNOVATE, tienda peruana de tecnologia.

Genera UN SALUDO BREVISIMO (max 3 lineas) en espanol peruano natural, como si fueras un amigo vendedor.
Usa el historial del usuario para personalizar.

Historial:
$viewsText
${searchesText.isNotEmpty ? "Busquedas: $searchesText" : ""}
${dropsText.isNotEmpty ? "Precios bajaron:\n$dropsText" : ""}
${stockText.isNotEmpty ? "Stock repuesto:\n$stockText" : ""}

Responde SOLO el saludo, nada mas.
''';

      final response = await _geminiModel.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) return text;
    } catch (_) {}

    if (drops != null && drops.isNotEmpty) {
      return 'Buenas noticias! ${drops.length} producto(s) que viste bajaron de precio. '
          'Revisa las alertas abajo.';
    }
    if (stocks != null && stocks.isNotEmpty) {
      return 'Volvieron a estar disponibles! ${stocks.length} producto(s) de tus favoritos ya tienen stock.';
    }
    return 'Hola de nuevo! En que puedo ayudarte hoy?';
  }

  Future<List<ProductModel>> obtenerSugerencias() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    try {
      final ids = await _memory.getWatchedProductIds();
      final allProducts = await _products.getAvailableProducts();
      if (allProducts.isEmpty) return [];
      final seen = <String>{};
      final suggestions = <ProductModel>[];
      for (final id in ids) {
        if (seen.contains(id)) continue;
        seen.add(id);
        try {
          final doc = await _firestore.collection('digizone_productos').doc(id).get();
          if (doc.exists) {
            final product = ProductModel.fromFirestore(doc);
            if (product.tieneStock) suggestions.add(product);
          }
        } catch (_) {}
      }
      final remaining = allProducts.where((p) => !seen.contains(p.id)).toList();
      remaining.sort((a, b) => b.puntuacion.compareTo(a.puntuacion));
      suggestions.addAll(remaining.take(4 - suggestions.length));
      return suggestions;
    } catch (_) {
      return [];
    }
  }
}
