import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/admin_auth_service.dart';

import 'admin_login_screen.dart';

import 'digizone_admin_screen.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({Key? key, required this.child}) : super(key: key);

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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == true) {
          return child;
        }
        // Not admin → redirect to admin login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
        });
        return const SizedBox.shrink();
      },
    );
  }
}
