import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../services/checkout_service.dart';
import '../services/order_service.dart';

class OrderViewModel extends ChangeNotifier {
  final OrderService _orderService;
  final CheckoutService _checkoutService;
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  OrderViewModel({
    OrderService? orderService,
    CheckoutService? checkoutService,
  })  : _orderService = orderService ?? OrderService(),
        _checkoutService = checkoutService ?? CheckoutService();

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;

  Stream<List<OrderModel>> watchOrders() {
    return _orderService.watchOrders();
  }

  Future<OrderModel> crearPedido({
    required List<CartItemModel> cartItems,
    required Map<String, String> direccion,
    required String metodoPago,
    required double total,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _checkoutService.finishPurchase(cartItems);

      final order = await _orderService.crearPedido(
        cartItems: cartItems,
        direccion: direccion,
        metodoPago: metodoPago,
        total: total,
      );

      return order;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _orderService.getOrders();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
