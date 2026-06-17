import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/technovate_theme.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'views/home/digizone_screen.dart';
import 'views/admin/admin_login_screen.dart';
import 'views/admin/admin_guard.dart';
import 'views/admin/digizone_admin_screen.dart';
import 'views/splash_screen.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    if (!kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
    } else {
      // En Web, App Check requiere configuración adicional (reCAPTCHA)
      // Lo desactivamos temporalmente para evitar que bloquee el inicio
      debugPrint('App Check omitido en Web para pruebas');
    }

    await AnalyticsService().initialize();

    try {
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('FCM init error (non-fatal): $e');
    }
  } catch (e) {
    debugPrint('Error crítico de inicialización: $e');
  }
  
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  bool _darkMode = false;
  bool _showSplash = true;
  Timer? _inactivityTimer;

  void _toggleDarkMode() {
    setState(() => _darkMode = !_darkMode);
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    // Si hay un usuario logueado, iniciamos el temporizador de 5 minutos
    if (FirebaseAuth.instance.currentUser != null) {
      _inactivityTimer = Timer(const Duration(minutes: 5), () {
        _logout('Cierre de sesión por inactividad (5 min)');
      });
    }
  }

  Future<void> _logout(String reason) async {
    if (FirebaseAuth.instance.currentUser != null) {
      debugPrint(reason);
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      AnalyticsService().setUserId(user?.uid);
      if (user != null) {
        _resetInactivityTimer();
      } else {
        _inactivityTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si la app pasa a segundo plano (paused), cerramos sesión automáticamente
    if (state == AppLifecycleState.paused) {
      _logout('Cierre de sesión automático: Aplicación minimizada');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TechnovateTheme.light(),
        darkTheme: TechnovateTheme.dark(),
        themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
        home: SplashScreen(
          onFinish: () => setState(() => _showSplash = false),
        ),
      );
    }

    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TECHNOVATE',
        theme: TechnovateTheme.light(),
        darkTheme: TechnovateTheme.dark(),
        themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
        home: DarkModeScope(
          darkMode: _darkMode,
          onToggle: _toggleDarkMode,
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasData && snapshot.data != null) {
                  final user = snapshot.data!;
                  if (user.email?.toLowerCase() == 'admin@gmail.com') {
                    return const AdminGuard(child: DigizoneAdminScreen());
                  }
                  return DigizoneScreen(userEmail: user.email);
                }
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}


