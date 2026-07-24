import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/driver/presentation/welcome_screen.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/coming-soon',
        name: 'coming-soon',
        builder: (context, state) => const _ComingSoonScreen(),
      ),
    ],
    errorBuilder: (context, state) => const _ComingSoonScreen(),
  );
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قريباً')),
      body: const Center(child: Text('سيتم إضافة هذه الشاشة لاحقاً.')),
    );
  }
}
