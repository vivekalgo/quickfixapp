import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/router/app_router.dart';
import 'package:quickfix/core/theme/app_theme.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/auth/presentation/controllers/auth_providers.dart';

import 'package:quickfix/core/widgets/offline_overlay.dart';

class QuickFixApp extends ConsumerWidget {
  const QuickFixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        appRouter.go('/login');
      }
    });

    return MaterialApp.router(
      title: 'QuickFix',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        return OfflineOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
