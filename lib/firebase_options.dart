import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      case TargetPlatform.windows: return windows;
      default: return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBb3cD0HVg0-XU3JPVfxRz1xSz6w4PFHNo',
    appId: '1:346974235549:web:b43c15b52416054276dd74',
    messagingSenderId: '346974235549',
    projectId: 'empresa-s',
    storageBucket: 'empresa-s.firebasestorage.app',
    authDomain: 'empresa-s.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBb3cD0HVg0-XU3JPVfxRz1xSz6w4PFHNo',
    appId: '1:346974235549:android:42b468edc1c22cfe76dd74',
    messagingSenderId: '346974235549',
    projectId: 'empresa-s',
    storageBucket: 'empresa-s.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBb3cD0HVg0-XU3JPVfxRz1xSz6w4PFHNo',
    appId: '1:346974235549:ios:6b4685214d325b2876dd74',
    messagingSenderId: '346974235549',
    projectId: 'empresa-s',
    storageBucket: 'empresa-s.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBb3cD0HVg0-XU3JPVfxRz1xSz6w4PFHNo',
    appId: '1:346974235549:web:9152d68b305cb47776dd74',
    messagingSenderId: '346974235549',
    projectId: 'empresa-s',
    storageBucket: 'empresa-s.firebasestorage.app',
  );
}
