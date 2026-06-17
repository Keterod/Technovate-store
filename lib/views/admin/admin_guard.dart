import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/session/session_manager.dart';
import '../../services/admin_auth_service.dart';

import 'admin_login_screen.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final authService = AdminAuthService();
    return await authService.isAdmin(user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return child;
        }
        if (FirebaseAuth.instance.currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (FirebaseAuth.instance.currentUser == null) {
              SessionManager.resetNavigationToRoot();
            }
          });
          return const SizedBox.shrink();
        }
        return const AdminLoginScreen();
      },
    );
  }
}
