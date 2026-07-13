import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/first_login_screen.dart';
import '../../features/dashboard/presentation/screens/main_navigation_shell.dart';

final GoRouter providerRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
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
