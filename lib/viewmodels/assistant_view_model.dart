import 'package:flutter/foundation.dart';
import '../models/assistant_chat_message.dart';
import '../models/product_model.dart';
import '../services/ai_assistant_service.dart';
import '../services/concierge_service.dart';
import '../services/memory_service.dart';
import '../services/product_service.dart';
import 'cart_view_model.dart';

class AssistantViewModel extends ChangeNotifier {
  AssistantViewModel({
    AiAssistantService? assistantService,
    ProductService? productService,
    ConciergeService? conciergeService,
    required CartViewModel cartViewModel,
  })  : _assistantService = assistantService ?? AiAssistantService(),
        _productService = productService ?? ProductService(),
        _conciergeService = conciergeService ?? ConciergeService(),
        _cartViewModel = cartViewModel {
    _initConcierge();
  }

  final AiAssistantService _assistantService;
  final ProductService _productService;
  final ConciergeService _conciergeService;
  final CartViewModel _cartViewModel;
  final List<AssistantChatMessage> _messages = [];
  bool _isLoading = false;
  bool _conciergeLoaded = false;
  String _conciergeGreeting = '';
  List<ProductModel> _suggestions = [];
  List<Map<String, dynamic>> _priceDrops = [];
  List<Map<String, dynamic>> _stockAlerts = [];

  List<AssistantChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get conciergeLoaded => _conciergeLoaded;
  String get conciergeGreeting => _conciergeGreeting;
  List<ProductModel> get suggestions => _suggestions;
  List<Map<String, dynamic>> get priceDrops => _priceDrops;
  List<Map<String, dynamic>> get stockAlerts => _stockAlerts;

  Future<void> _initConcierge() async {
    _messages.add(
      AssistantChatMessage(
        text: 'Cargando tu asistente personal...',
        isUser: false,
      ),
    );
    notifyListeners();

    final memory = MemoryService();
    final results = await Future.wait([
      _conciergeService.generarSaludo(),
      _conciergeService.obtenerSugerencias(),
      memory.checkPriceDrops(),
      memory.checkStockReturns(),
    ]);
    final greeting = results[0] as String;
    final suggestions = results[1] as List<ProductModel>;
    final drops = results[2] as List<Map<String, dynamic>>;
    final stocks = results[3] as List<Map<String, dynamic>>;

    _conciergeGreeting = greeting;
    _suggestions = suggestions;
    _priceDrops = drops;
    _stockAlerts = stocks;
    _conciergeLoaded = true;

    _messages.clear();
    _messages.add(
      AssistantChatMessage(
        text: greeting,
        isUser: false,
        recommendedProducts: suggestions,
      ),
    );
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _messages.add(AssistantChatMessage(text: trimmed, isUser: true));
    _isLoading = true;
    notifyListeners();

    final response = await _assistantService.responder(trimmed, _cartViewModel.items);

    for (final action in response.actions) {
      if (action.startsWith('ADD_TO_CART:')) {
        final id = action.substring('ADD_TO_CART:'.length);
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
    final queryText = 'Armame una recomendacion con las siguientes especificaciones tecnicas:\n'
        '- Presupuesto maximo: S/. ${presupuesto.toStringAsFixed(0)}\n'
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
