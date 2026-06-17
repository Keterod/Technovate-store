import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  // Simple admin check based on email address.
  // In production this should use custom claims or a secure backend.
  final List<String> _adminEmails = ['admin@gmail.com'];

  Future<bool> isAdmin(User user) async {
    final email = user.email?.toLowerCase() ?? '';
    return _adminEmails.contains(email);
  }
}
