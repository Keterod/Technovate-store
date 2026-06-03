import 'product_model.dart';

class AssistantResponse {
  final String message;
  final List<ProductModel> recommendedProducts;
  final bool usedFallback;
  final List<String> actions;

  const AssistantResponse({
    required this.message,
    required this.recommendedProducts,
    required this.usedFallback,
    this.actions = const [],
  });
}
