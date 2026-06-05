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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } else {
    await Firebase.initializeApp();
  }

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  }

  await AnalyticsService().initialize();

  if (!kIsWeb) {
    try {
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('FCM init error (non-fatal): $e');
    }
  }
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _darkMode = false;

  void _toggleDarkMode() {
    setState(() => _darkMode = !_darkMode);
  }

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      AnalyticsService().setUserId(user?.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TECHNOVATE',
      theme: TechnovateTheme.light(),
      darkTheme: TechnovateTheme.dark(),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        );
      },
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
              return const DigizoneScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}


