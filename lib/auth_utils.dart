import 'package:firebase_auth/firebase_auth.dart';

/// Error conocido de firebase_auth 4.x al decodificar respuesta nativa (Pigeon).
bool esErrorPigeonAuth(Object error) {
  final mensaje = error.toString();
  return mensaje.contains('PigeonUserDetails') ||
      mensaje.contains('PigeonUserInfo') ||
      mensaje.contains('PigeonUserCredential');
}

/// La autenticación pudo completarse aunque el plugin lance TypeError.
bool debeIgnorarErrorAuth(Object error) {
  return esErrorPigeonAuth(error) &&
      FirebaseAuth.instance.currentUser != null;
}
