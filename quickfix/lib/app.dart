import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/router/app_router.dart';
import 'package:quickfix/shared/themes/app_theme.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';

class QuickFixApp extends ConsumerWidget {
  const QuickFixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return MaterialApp.router(
      title: 'QuickFix',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
