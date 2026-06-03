import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseCrashlytics get crashlytics => _crashlytics;

  Future<void> initialize() async {
    FlutterError.onError = (details) {
      _crashlytics.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  Future<void> logProductView({
    required String productId,
    required String productName,
    required double price,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'product_view',
      parameters: {
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'category': category,
      },
    );
  }

  Future<void> logAddToCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
  }) async {
    await _analytics.logEvent(
      name: 'add_to_cart',
      parameters: {
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'quantity': quantity,
      },
    );
  }

  Future<void> logBeginCheckout({
    required double value,
  }) async {
    await _analytics.logBeginCheckout(
      value: value,
    );
  }

  Future<void> logPurchase({
    required double value,
  }) async {
    await _analytics.logPurchase(
      value: value,
    );
  }

  Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  Future<void> logReview({
    required String productId,
    required int rating,
  }) async {
    await _analytics.logEvent(
      name: 'product_review',
      parameters: {
        'product_id': productId,
        'rating': rating,
      },
    );
  }

  Future<void> setUserId(String? uid) async {
    await _analytics.setUserId(id: uid);
    if (uid != null) {
      await _crashlytics.setUserIdentifier(uid);
    }
  }
}
