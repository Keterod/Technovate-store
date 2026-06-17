import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/session/session_manager.dart';
import 'core/theme/technovate_theme.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'views/home/digizone_screen.dart';
import 'views/admin/admin_guard.dart';
import 'views/admin/digizone_admin_screen.dart';
import 'views/splash_screen.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('DEBUG BOOT: main init start');

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('DEBUG BOOT: Firebase initialized');

    if (!kIsWeb) {
      try {
        debugPrint('DEBUG BOOT: App Check activate start');
        await FirebaseAppCheck.instance
            .activate(
              providerAndroid: kDebugMode
                  ? const AndroidDebugProvider()
                  : const AndroidPlayIntegrityProvider(),
            )
            .timeout(const Duration(seconds: 5));
        debugPrint('DEBUG BOOT: App Check activate done');
      } catch (e) {
        debugPrint('DEBUG BOOT: App Check activate error=$e');
      }
    } else {
      // En Web, App Check requiere configuración adicional (reCAPTCHA)
      // Lo desactivamos temporalmente para evitar que bloquee el inicio
      debugPrint('App Check omitido en Web para pruebas');
    }

    try {
      await AnalyticsService().initialize().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('DEBUG BOOT: Analytics init error=$e');
    }

    try {
      await NotificationService().initialize().timeout(
        const Duration(seconds: 5),
      );
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
  bool _bootstrapComplete = false;
  Timer? _inactivityTimer;
  StreamSubscription<User?>? _authSubscription;
  late final NavigatorObserver _activityNavigatorObserver;

  void _toggleDarkMode() {
    setState(() => _darkMode = !_darkMode);
    debugPrint('DEBUG SESSION: theme toggled darkMode=$_darkMode');
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      if (FirebaseAuth.instance.currentUser == null) return;
      SessionManager.logoutAndResetNavigation(reason: 'inactivity_timeout');
    });
  }

  void _handleUserActivity() {
    _resetInactivityTimer();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activityNavigatorObserver = _SessionActivityNavigatorObserver(
      onNavigationActivity: _handleUserActivity,
    );
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint('DEBUG SESSION: auth state user=${user?.uid ?? 'null'}');
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
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_bootstrapComplete && FirebaseAuth.instance.currentUser != null) {
        SessionManager.logoutAndResetNavigation(reason: 'app_paused');
      }
    } else if (state == AppLifecycleState.resumed) {
      _resetInactivityTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG BOOT: build MainApp');
    if (_showSplash) {
      debugPrint('DEBUG BOOT: showing Splash');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TechnovateTheme.light(),
        darkTheme: TechnovateTheme.dark(),
        themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
        home: SplashScreen(
          onFinish: () {
            if (!mounted) return;
            setState(() {
              _showSplash = false;
              _bootstrapComplete = true;
            });
          },
        ),
      );
    }

    return Listener(
      onPointerDown: (_) => _handleUserActivity(),
      onPointerMove: (_) => _handleUserActivity(),
      onPointerSignal: (_) => _handleUserActivity(),
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        navigatorObservers: [_activityNavigatorObserver],
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
              final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
              debugPrint(
                'DEBUG BOOT: auth snapshot state=${snapshot.connectionState} '
                'hasData=${snapshot.hasData} user=${user?.uid ?? 'null'}',
              );

              if (user != null) {
                if (user.email?.toLowerCase() == 'admin@gmail.com') {
                  debugPrint('DEBUG BOOT: showing Admin');
                  return const AdminGuard(child: DigizoneAdminScreen());
                }
                debugPrint('DEBUG BOOT: showing Digizone');
                return DigizoneScreen(userEmail: user.email);
              }
              debugPrint('DEBUG BOOT: showing Login');
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}

class _SessionActivityNavigatorObserver extends NavigatorObserver {
  _SessionActivityNavigatorObserver({required this.onNavigationActivity});

  final VoidCallback onNavigationActivity;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onNavigationActivity();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onNavigationActivity();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onNavigationActivity();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onNavigationActivity();
    super.didRemove(route, previousRoute);
  }
}
