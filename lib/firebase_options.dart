import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Configuración Firebase para web.
/// Si aún no existe, registra una app Web en Firebase Console (proyecto empresa-s)
/// y actualiza [web.appId] con el valor que te entregue.
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAZy37i2uZCsM-wCdUd9uuQV3kAycdAP4o',
    appId: '1:346974235549:web:42b468edc1c22cfe76dd74',
    messagingSenderId: '346974235549',
    projectId: 'empresa-s',
    authDomain: 'empresa-s.firebaseapp.com',
    storageBucket: 'empresa-s.firebasestorage.app',
  );
}
