import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../digizone_screen.dart';
import '../login_screen.dart';
import '../registro_screen.dart';
import '../features/favorites/favorites_screen.dart';

final GoRouter appRouter = GoRouter(
  refreshListenable: _GoRouterAuthStream(),
  initialLocation: '/',
  redirect: _authRedirect,
  routes: [
    GoRoute(path: '/login', name: 'login', builder: (_, _) => const LoginScreen()
),
    GoRoute(path: '/register', name: 'register', builder: (_, _) => const RegistroScreen()
),
    GoRoute(path: '/', name: 'home', builder: (_, _) => const DigizoneScreen()
),
    GoRoute(path: '/favorites', name: 'favorites', builder: (_, _) => const FavoritesScreen()
),
  ],
);

String? _authRedirect(BuildContext context, GoRouterState state) {
  final user = FirebaseAuth.instance.currentUser;
  final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
  if (user == null && !isAuthRoute) return '/login';
  if (user != null && isAuthRoute) return '/';
  return null;
}

class _GoRouterAuthStream extends ChangeNotifier {
  StreamSubscription<User?>? _subscription;

  _GoRouterAuthStream() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
