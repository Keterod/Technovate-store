import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio de autenticación con Firebase Auth.
/// Permite registro, login, logout y verificación del rol (admin vs cliente).
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registrar nuevo usuario con email/contraseña y guardar perfil en Firestore.
  Future<User?> registrar({
    required String email,
    required String password,
    required String nombre,
    String rol = 'cliente',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await _firestore.collection('usuarios').doc(user.uid).set({
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      await user.updateDisplayName(nombre);
    }
    return user;
  }

  /// Iniciar sesión con email/contraseña.
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Cerrar sesión.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Obtener el rol del usuario actual desde Firestore.
  /// Retorna 'admin' o 'cliente'.
  Future<String> obtenerRol(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return (doc.data()?['rol'] ?? 'cliente').toString();
      }
    } catch (_) {
      // Si falla la consulta, asumir cliente
    }
    return 'cliente';
  }

  /// Obtener nombre del usuario.
  Future<String> obtenerNombre(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return (doc.data()?['nombre'] ?? 'Usuario').toString();
      }
    } catch (_) {}
    return currentUser?.displayName ?? 'Usuario';
  }
}
