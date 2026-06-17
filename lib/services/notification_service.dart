import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? get fcmToken => _token;
  String? _token;
  static const Duration _timeout = Duration(seconds: 5);

  Future<void> initialize() async {
    try {
      debugPrint('DEBUG FCM: init start');
      final settings = await _messaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          )
          .timeout(_timeout);

      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      _token = await _messaging.getToken().timeout(_timeout);

      _messaging.onTokenRefresh.listen((newToken) {
        _token = newToken;
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await _messaging.getInitialMessage().timeout(
        _timeout,
      );
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
      debugPrint('DEBUG FCM: init done');
    } catch (e) {
      debugPrint('DEBUG FCM: init error=$e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'TECHNOVATE';
    final body = message.notification?.body ?? '';

    if (title.isEmpty && body.isEmpty) return;

    debugPrint('FCM foreground: $title — $body');
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    debugPrint('FCM tapped: $data');
  }
}
