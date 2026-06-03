import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'viewmodels/auth_view_model.dart';
import 'views/auth/login_screen.dart';
import 'views/home/digizone_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
  );
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final AuthViewModel _authViewModel = AuthViewModel();

  @override
  void initState() {
    super.initState();
    _authViewModel.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthChanged);
    _authViewModel.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TECHNOVATE',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Mientras carga la verificación de sesión
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Si hay usuario logueado, ir al home
          if (snapshot.hasData) {
            return DigizoneScreen(authViewModel: _authViewModel);
          }

          // Si no hay sesión, ir al login
          return LoginScreen(authViewModel: _authViewModel);
        },
      ),
    );
  }
}
