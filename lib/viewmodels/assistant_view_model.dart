import 'package:flutter/foundation.dart';
import '../models/assistant_chat_message.dart';
import '../models/product_model.dart';
import '../services/ai_assistant_service.dart';
import '../services/product_service.dart';
import 'cart_view_model.dart';

class AssistantViewModel extends ChangeNotifier {
  AssistantViewModel({
    AiAssistantService? assistantService,
    ProductService? productService,
    required CartViewModel cartViewModel,
  })  : _assistantService = assistantService ?? AiAssistantService(),
        _productService = productService ?? ProductService(),
        _cartViewModel = cartViewModel {
    _messages.add(
      AssistantChatMessage(
        text:
            'Hola, soy el asistente experto de TECHNOVATE. 💻\n\n'
            'Puedo ayudarte a armar tu PC compatible, buscar productos por presupuesto, o agregarlos a tu carrito de compras.\n\n'
            'Prueba los botones rápidos de abajo o hazme una consulta.',
        isUser: false,
      ),
    );
  }

  final AiAssistantService _assistantService;
  final ProductService _productService;
  final CartViewModel _cartViewModel;
  final List<AssistantChatMessage> _messages = [];
  bool _isLoading = false;

  List<AssistantChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _messages.add(AssistantChatMessage(text: trimmed, isUser: true));
    _isLoading = true;
    notifyListeners();

    // Pasar el carrito actual para realizar comprobaciones de compatibilidad
    final response = await _assistantService.responder(trimmed, _cartViewModel.items);

    // Procesar acciones solicitadas por el asistente
    for (final action in response.actions) {
      if (action.startsWith('ADD_TO_CART:')) {
        final id = action.substring('ADD_TO_CART:'.length);
        
        // Buscar producto en recomendados o catálogo
        ProductModel? product;
        final inRecommended = response.recommendedProducts.where((p) => p.id == id);
        if (inRecommended.isNotEmpty) {
          product = inRecommended.first;
        } else {
          final allProducts = await _productService.getAvailableProducts();
          final matches = allProducts.where((p) => p.id == id);
          if (matches.isNotEmpty) {
            product = matches.first;
          }
        }

        if (product != null) {
          _cartViewModel.addProduct(product);
        }
      } else if (action.startsWith('REMOVE_FROM_CART:')) {
        final id = action.substring('REMOVE_FROM_CART:'.length);
        final index = _cartViewModel.items.indexWhere((item) => item.idProducto == id);
        if (index != -1) {
          _cartViewModel.eliminarEn(index);
        }
      } else if (action == 'CLEAR_CART') {
        _cartViewModel.limpiar();
      }
    }

    _messages.add(
      AssistantChatMessage(
        text: response.message,
        isUser: false,
        recommendedProducts: response.recommendedProducts,
      ),
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendBudgetForm({
    required double presupuesto,
    required String uso,
    required String marca,
    required String formato,
    required String prioridad,
  }) async {
    final queryText = 'Ármame una recomendación con las siguientes especificaciones técnicas:\n'
        '- Presupuesto máximo: S/. ${presupuesto.toStringAsFixed(0)}\n'
        '- Uso principal: $uso\n'
        '- Marca de preferencia: $marca\n'
        '- Tipo de formato: $formato\n'
        '- Prioridad: $prioridad';
    await sendMessage(queryText);
  }

  String? addRecommendationToCart(ProductModel product) {
    final error = _cartViewModel.addProduct(product);
    notifyListeners();
    return error;
  }
}
