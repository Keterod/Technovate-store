import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TechnovateApp());
}

class TechnovateApp extends StatelessWidget {
  const TechnovateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TECHNOVATE',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
