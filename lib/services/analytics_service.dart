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
  static const Duration _timeout = Duration(seconds: 3);

  Future<void> initialize() async {
    if (!kIsWeb) {
      FlutterError.onError = (details) {
        _crashlytics.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    if (kIsWeb) return;

    FlutterError.onError = (details) {
      debugPrint('DEBUG GLOBAL ERROR: flutter ${details.exception}');
      _safeCrashlytics(
        'flutter_fatal',
        () => _crashlytics.recordFlutterFatalError(details),
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('DEBUG GLOBAL ERROR: platform $error');
      _safeCrashlytics(
        'platform_fatal',
        () => _crashlytics.recordError(error, stack, fatal: true),
      );
      return true;
    };
    await _safeCrashlytics(
      'initialize',
      () => _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode),
    );
  }

  Future<void> _safeAnalytics(
    String event,
    Future<void> Function() operation,
  ) async {
    try {
      await operation().timeout(_timeout);
      debugPrint('DEBUG ANALYTICS: event=$event ok');
    } catch (e) {
      debugPrint('DEBUG ANALYTICS: event=$event error=$e');
    }
  }

  Future<void> _safeCrashlytics(
    String event,
    Future<void> Function() operation,
  ) async {
    if (kIsWeb) return;
    try {
      await operation().timeout(_timeout);
      debugPrint('DEBUG ANALYTICS: event=crashlytics_$event ok');
    } catch (e) {
      debugPrint('DEBUG ANALYTICS: event=crashlytics_$event error=$e');
    }
  }

  Future<void> logProductView({
    required String productId,
    required String productName,
    required double price,
    required String category,
  }) async {
    await _safeAnalytics(
      'product_view',
      () => _analytics.logEvent(
        name: 'product_view',
        parameters: {
          'product_id': productId,
          'product_name': productName,
          'price': price,
          'category': category,
        },
      ),
    );
  }

  Future<void> logAddToCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
  }) async {
    await _safeAnalytics(
      'add_to_cart',
      () => _analytics.logEvent(
        name: 'add_to_cart',
        parameters: {
          'product_id': productId,
          'product_name': productName,
          'price': price,
          'quantity': quantity,
        },
      ),
    );
  }

  Future<void> logBeginCheckout({required double value}) async {
    await _safeAnalytics(
      'begin_checkout',
      () => _analytics.logBeginCheckout(value: value),
    );
  }

  Future<void> logPurchase({required double value}) async {
    await _safeAnalytics(
      'purchase',
      () => _analytics.logPurchase(value: value),
    );
  }

  Future<void> logSearch(String searchTerm) async {
    await _safeAnalytics(
      'search',
      () => _analytics.logSearch(searchTerm: searchTerm),
    );
  }

  Future<void> logReview({
    required String productId,
    required int rating,
  }) async {
    await _safeAnalytics(
      'product_review',
      () => _analytics.logEvent(
        name: 'product_review',
        parameters: {'product_id': productId, 'rating': rating},
      ),
    );
  }

  Future<void> setUserId(String? uid) async {
    await _analytics.setUserId(id: uid);
    if (uid != null && !kIsWeb) {
      await _crashlytics.setUserIdentifier(uid);
    await _safeAnalytics('set_user_id', () => _analytics.setUserId(id: uid));
    if (uid != null && !kIsWeb) {
      await _safeCrashlytics(
        'set_user_identifier',
        () => _crashlytics.setUserIdentifier(uid),
      );
    }
  }
}
