import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class SessionManager {
  SessionManager._();

  static void resetNavigationToRoot() {
    final navigator = rootNavigatorKey.currentState;
    debugPrint('DEBUG SESSION: navigator ready=${navigator != null}');
    if (navigator == null) return;

    navigator.popUntil((route) => route.isFirst);
  }

  static Future<void> logoutAndResetNavigation({
    String reason = 'manual',
  }) async {
    final hadUser = FirebaseAuth.instance.currentUser != null;
    if (!hadUser) {
      debugPrint(
        'DEBUG SESSION: logout ignored, no authenticated user reason=$reason',
      );
      return;
    }

    debugPrint('DEBUG SESSION: logout reason=$reason');
    await FirebaseAuth.instance.signOut();

    resetNavigationToRoot();
  }
}
