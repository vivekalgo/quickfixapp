import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quickfix_provider/features/auth/presentation/pages/splash_screen.dart';
import 'package:quickfix_provider/features/auth/presentation/pages/login_screen.dart';
import 'package:quickfix_provider/features/auth/presentation/pages/first_login_screen.dart';
import 'package:quickfix_provider/features/dashboard/presentation/pages/main_navigation_shell.dart';

import 'package:quickfix_provider/core/logging/navigation_observer.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter providerRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  observers: [AppNavigationObserver()],
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/first-login',
      builder: (context, state) => const FirstLoginScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainNavigationShell(),
    ),
  ],
);
