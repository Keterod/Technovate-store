import 'order_model.dart';

class AdminOrderItem {
  final String uid;
  final String orderId;
  final OrderModel order;

  const AdminOrderItem({
    required this.uid,
    required this.orderId,
    required this.order,
  });
}
