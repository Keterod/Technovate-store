import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// ViewModel de autenticación.
/// Controla login, registro, logout y estado del usuario actual.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthService? authService})
      : _authService = authService ?? AuthService() {
    // Escuchar cambios de estado de autenticación
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _rol = await _authService.obtenerRol(user.uid);
        _nombre = await _authService.obtenerNombre(user.uid);
      } else {
        _rol = 'cliente';
        _nombre = '';
      }
      notifyListeners();
    });
  }

  final AuthService _authService;
  User? _user;
  String _rol = 'cliente';
  String _nombre = '';
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String get rol => _rol;
  String get nombre => _nombre;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _rol == 'admin';
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get email => _user?.email ?? '';

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.login(email: email, password: password);
      if (user != null) {
        _user = user;
        _rol = await _authService.obtenerRol(user.uid);
        _nombre = await _authService.obtenerNombre(user.uid);
      }
      _isLoading = false;
      notifyListeners();
      return user != null;
    } on FirebaseAuthException catch (e) {
      _error = _traducirError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrar({
    required String email,
    required String password,
    required String nombre,
    String rol = 'cliente',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.registrar(
        email: email,
        password: password,
        nombre: nombre,
        rol: rol,
      );
      if (user != null) {
        _user = user;
        _rol = rol;
        _nombre = nombre;
      }
      _isLoading = false;
      notifyListeners();
      return user != null;
    } on FirebaseAuthException catch (e) {
      _error = _traducirError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _rol = 'cliente';
    _nombre = '';
    _error = null;
    notifyListeners();
  }

  String _traducirError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres)';
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      default:
        return 'Error de autenticación: $code';
    }
  }
}
