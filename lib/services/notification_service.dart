import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? get fcmToken => _token;
  String? _token;

  Future<void> initialize() async {
    if (kIsWeb) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    _token = await _messaging.getToken();

    _messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;

    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
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
