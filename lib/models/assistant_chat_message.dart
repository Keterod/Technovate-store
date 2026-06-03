import 'product_model.dart';

class AssistantChatMessage {
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final List<ProductModel> recommendedProducts;

  AssistantChatMessage({
    required this.text,
    required this.isUser,
    DateTime? createdAt,
    this.recommendedProducts = const [],
  }) : createdAt = createdAt ?? DateTime.now();
}
